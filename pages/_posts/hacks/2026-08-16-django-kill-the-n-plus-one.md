---
title: "Your Django page fired 51 queries: I counted them, then killed the N+1"
description: "A Django loop fired one query per row. I counted them, killed the N+1 with select_related and prefetch_related, then broke both fixes on purpose."
date: 2026-08-16
preview: /images/previews/your-django-page-fired-51-queries-i-counted-them-t.svg
categories: [Hacks]
tags: [web-dev, data]
author: edge
excerpt: "The page felt slow. 'Felt' is not a number. So I turned on the query log, ran the loop, and the counter stopped at 51 — for a list of 50 orders."
permalink: /hacks/django-kill-the-n-plus-one/
---
The page felt slow. "Felt" is not a number, and I don't file bugs against feelings, so I turned on the query log and counted. The loop over 50 orders fired **51 queries**. Not 51 milliseconds. Fifty-one round trips to the database, to render one list, because somewhere in the template a `{% raw %}{{ order.customer.name }}{% endraw %}` was quietly reaching across a foreign key once per row. Multiply by a real orders table and that's the page that "sometimes hangs" — the one nobody can reproduce because nobody's list is ever the same length twice.

This is the N+1: 1 query to load the list, then N more to load the thing you touch inside the loop. The ORM makes it invisible on purpose — `order.customer` looks like a field access, not a `SELECT`. The whole bug is that it doesn't look like a bug. It came off the [Stack Attack Django + React ERP quest](https://it-journey.dev/quests/0001/stack-attack/) over on it-journey.dev, where "the orders page is slow" is a rite of passage. I don't take "slow" on faith. I counted.

Everything below I actually ran, standalone, on **Python 3.12.3 with Django 6.1** against an in-memory SQLite. No project, no `manage.py`, no server — one file. The counts are pasted from the runs, not estimated.

## Count them first, or you're guessing

You cannot fix a number you refuse to measure. Django populates `django.db.connection.queries` whenever `DEBUG=True` — every SQL statement, with timing. `reset_queries()` zeroes the log so you can wrap exactly the block you suspect. Here's the whole harness, self-contained enough to paste into a scratch file and run:

```python
# n1.py — run: python3 n1.py   (Django 6.1, no project needed)
import django, sys, types
from django.conf import settings
settings.configure(
    DEBUG=True,  # REQUIRED — without it, connection.queries stays empty
    DATABASES={"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": ":memory:"}},
    INSTALLED_APPS=["shop"], DEFAULT_AUTO_FIELD="django.db.models.BigAutoField")
shop = types.ModuleType("shop"); shop.__path__ = ["."]; sys.modules["shop"] = shop
django.setup()

from django.db import models, connection, reset_queries

class Customer(models.Model):
    name = models.CharField(max_length=100)
    class Meta: app_label = "shop"

class Tag(models.Model):
    label = models.CharField(max_length=40)
    class Meta: app_label = "shop"

class Order(models.Model):
    customer = models.ForeignKey(Customer, on_delete=models.CASCADE)
    total = models.IntegerField(default=0)
    tags = models.ManyToManyField(Tag)
    class Meta: app_label = "shop"

with connection.schema_editor() as se:
    se.create_model(Customer); se.create_model(Tag); se.create_model(Order)

tags = [Tag.objects.create(label=f"tag{i}") for i in range(5)]
for i in range(50):                                   # 50 customers, 1 order each
    c = Customer.objects.create(name=f"Customer {i}")
    o = Order.objects.create(customer=c, total=i * 10)
    o.tags.add(tags[i % 5], tags[(i + 1) % 5])         # 2 tags each, for later

def count(label, fn):
    reset_queries(); fn()
    print(f"{label}: {len(connection.queries)} queries")

# the crime scene
count("naive loop (order.customer.name)",
      lambda: [o.customer.name for o in Order.objects.all()])
```

The `types.ModuleType("shop")` line is a hack to give the models an app without a real package on disk — skip it in a real project where `shop` is an actual app. You'll know the harness works when it prints a query count instead of a traceback:

```text
naive loop (order.customer.name): 51 queries
```

Fifty-one, for fifty orders. There it is, with a receipt. And it isn't abstract — dump the first four statements the loop fired and the pattern is right there in the SQL:

```text
SELECT "shop_order"."id", "shop_order"."customer_id", "shop_order"."total" FROM ...
SELECT "shop_customer"."id", "shop_customer"."name" FROM "shop_customer" WHERE ...
SELECT "shop_customer"."id", "shop_customer"."name" FROM "shop_customer" WHERE ...
SELECT "shop_customer"."id", "shop_customer"."name" FROM "shop_customer" WHERE ...
```

One query for the orders, then the same customer lookup over and over with a different id. That repeated line, fifty times, is the whole performance bug.

## `select_related`: join the foreign key into one query

`select_related` follows a forward foreign key (or one-to-one) with a SQL `JOIN`, so the customer arrives glued to the order in the *same* result set. No second trip:

```python
count("select_related('customer')",
      lambda: [o.customer.name for o in Order.objects.select_related("customer")])
```

```text
select_related('customer'): 1 queries
```

51 → 1. The whole loop, one statement, because the customer columns ride along in the SELECT:

```text
SELECT "shop_order"."id", "shop_order"."customer_id", "shop_order"."total", "shop_customer" ...
```

That's the fix for anything hanging off a forward FK — `order.customer`, `comment.author`, `line_item.product`. One join per relation you name.

## `prefetch_related`: for the reverse and many-to-many side

`select_related` can't join a many-to-many (a row can have many tags — there's nothing to flatten into one order row). Touch `order.tags.all()` in a loop and you're back to N+1:

```python
count("naive loop over order.tags.all()",
      lambda: [list(o.tags.all()) for o in Order.objects.all()])
count("prefetch_related('tags')",
      lambda: [list(o.tags.all()) for o in Order.objects.prefetch_related("tags")])
```

```text
naive loop over order.tags.all(): 51 queries
prefetch_related('tags'): 2 queries
```

`prefetch_related` runs a **second** query that fetches every related tag in one `IN (...)`, then stitches them onto the orders in Python. Two queries, flat, no matter how many orders. Not 1 — it's a separate SELECT by design — but 2 beats 51 every day of the week.

The scorecard so far, all counts real:

| Access pattern | Naive | With the fix | Fix |
|---|---|---|---|
| `order.customer.name` (forward FK) | 51 ❌ | 1 ✅ | `select_related` |
| `order.tags.all()` (many-to-many) | 51 ❌ | 2 ✅ | `prefetch_related` |

## Now the part where I break the fixes on purpose

A fix I haven't tried to misuse is a fix I don't trust yet. So I fed both of these the wrong relation and watched.

**Footgun 1 — `select_related` on a many-to-many doesn't silently no-op. It raises.** I half-expected it to quietly ignore the bad hint. It does not:

```python
list(Order.objects.select_related("tags"))
```

```text
FieldError: Invalid field name(s) given in select_related: 'tags'. Choices are: customer
```

Grudging respect: this is the *good* kind of loud. It fails at query-build time, names the field, and even lists the ones that would've worked (`Choices are: customer`). The failure it prevents: shipping `select_related("tags")`, seeing no error because you never looked, and wondering why the page is still slow. It can't be still slow — it won't run. Take the crash. It's cheaper than the mystery.

**Footgun 2 — `.only()` invents a *new* N+1 the moment you touch a field you deferred.** This is the nasty one, because you reach for `.only()` to make the page *faster* — load fewer columns. Then someone touches a column you left behind:

```python
qs = list(Customer.objects.only("name"))   # email is now deferred
# ... later, in a template or a serializer ...
for c in qs:
    _ = c.email                            # the field we told Django to skip
```

```text
fetch with .only('name'):                       1 query
touching only .name across 10 rows:             0 queries
touching deferred .email across 10 rows:        10 queries
```

Ten rows, ten queries — an N+1 you *added* while trying to optimize. Each deferred field access is a fresh `SELECT` for that one column on that one row. The nitpick has a victim: the developer who "optimized" the query with `.only()`, moved on, and left a landmine for whoever adds `{% raw %}{{ customer.email }}{% endraw %}` to the template six months later. The fix is boring — only defer fields you're genuinely not going to touch, and if you might, don't defer them. `.only()` is a scalpel, not a speedup you sprinkle on.

## The verdict, on the survives-a-Tuesday scale

`select_related` and `prefetch_related` **survive a normal Tuesday** — the counts are real, the wins are large (51 → 1, 51 → 2), and the one that gets misused fails loudly with a helpful message instead of silently.

`.only()` survives a Tuesday *only if you never let an intern near the template*, because the moment someone touches a deferred field the count quietly goes back up and nothing warns you. It's the one on this page most likely to re-grow the exact bug you came here to kill.

Whichever fix you reach for: don't trust "felt faster." Wrap the block in `reset_queries()` and print `len(connection.queries)`. A number is the only thing that argues back.

## When this goes wrong

- **Count is 0 and you swear the loop ran.** `DEBUG` is off. `connection.queries` is
  only populated when `DEBUG=True`; in production it's empty on purpose (it would leak memory logging every query). Measure in a shell or a test, not on the live site.
- **`select_related` didn't help.** You named a reverse relation or a many-to-many —
  it only follows forward FK / one-to-one. Reverse and M2M are `prefetch_related`'s job.
- **Still N+1 after `.only()` / `.defer()`.** You touched a deferred field. Add it to
  `.only(...)` or stop deferring it. The counter doesn't lie; the intent did.
