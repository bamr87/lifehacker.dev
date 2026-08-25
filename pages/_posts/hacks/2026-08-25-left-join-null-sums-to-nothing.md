---
title: "The customer who vanished from your revenue report: LEFT JOIN and the NULL that sums to nothing"
description: "An INNER JOIN silently dropped every zero-order customer from a revenue report. The query that lies with a straight face, and three tested fixes."
date: 2026-08-25
preview: /images/previews/the-customer-who-vanished-from-your-revenue-report.svg
categories: [Hacks]
tags: [data]
author: cass
excerpt: "A report that is confidently, quietly wrong is worse than one that crashes. Your revenue-per-customer query is dropping people, and the total still looks plausible."
permalink: /hacks/left-join-null-sums-to-nothing/
---
I threat-model dashboards. Not the login page — everyone threat-models the login page — the *number in the corner*. The one the CFO screenshots into a board deck. Because a report that crashes is an honest report: it failed loudly, someone got paged, nobody made a decision on it. The report I lose sleep over is the one that runs clean, returns a plausible total, and is silently missing every customer who churned. It doesn't throw. It doesn't warn. It just quietly answers a different question than the one you asked, and lets you present the wrong answer to people who sign things.

SEVERITY: your quarterly board deck. ATTACK VECTOR: one four-letter keyword you didn't type on purpose. The keyword is `JOIN`, and the exploit is that you meant `LEFT JOIN`.

This came off the [SQL Mastery quest](https://it-journey.dev/quests/0110/sql-mastery/) over on it-journey.dev, where "revenue per customer" is an early exercise and the trap is baked right in. I don't trust an exercise until I've watched it lie to me, so everything below I ran against a throwaway SQLite database — `sqlite3 3.45.1`, one file, five customers, six orders. The rows you see are pasted from the terminal, not imagined.

Here's the cast. Five customers. **Dorothy has never ordered anything.** Radia only ever placed one order and then refunded it. Remember those two — they're the ones who die quietly.

```sql
CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER, amount INTEGER, status TEXT);

INSERT INTO customers (id, name) VALUES
  (1,'Ada'), (2,'Grace'), (3,'Katherine'), (4,'Dorothy'), (5,'Radia');

INSERT INTO orders (id, customer_id, amount, status) VALUES
  (1,1,100,'paid'), (2,1,50,'paid'),
  (3,2,80,'refunded'), (4,2,40,'paid'),
  (5,3,200,'paid'),
  (7,5,60,'refunded');
```

## The crime scene: five customers walk in, four come out

Here is the query everyone writes first. Revenue per customer — join orders to customers, sum the amounts, group by the person. It reads like plain English and runs without complaint:

```sql
SELECT c.name, COUNT(o.id) AS orders, SUM(o.amount) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.id
GROUP BY c.id
ORDER BY c.id;
```

```text
name       orders  revenue
---------  ------  -------
Ada        2       150
Grace      2       120
Katherine  1       200
Radia      1       60
```

Count the rows. **Four.** We have five customers. Dorothy is gone — no error, no warning, no `NULL`, just *absent*, as if she were never in the `customers` table at all. A plain `JOIN` is an `INNER JOIN`: it only emits rows where both sides match, and Dorothy has nothing on the orders side to match against. So she doesn't drop out of the *sum* — she drops out of *existence*. Your churn report, the one whose entire job is to find people who stopped buying, has just deleted the people who stopped buying.

You'll know you've been hit by this when nobody notices for a quarter. The total still looks right. It is not right — it's the total of everyone who's still active, wearing the label "all customers." That's the whole attack: it's not wrong in a way that looks wrong.

## Mitigation 1 (ranked highest): `LEFT JOIN` — keep every row on the left

`LEFT JOIN` keeps every row from the left table whether or not the right side matches. Customers is on the left. So every customer survives, matched or not:

```sql
SELECT c.name, COUNT(o.id) AS orders, SUM(o.amount) AS revenue
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id
ORDER BY c.id;
```

```text
name       orders  revenue
---------  ------  -------
Ada        2       150
Grace      2       120
Katherine  1       200
Dorothy    0
Radia      1       60
```

Five rows. Dorothy is back from the dead. This is the single most important line in the whole post: if a report is supposed to enumerate *entities* (every customer, every product, every region) and not just *matches*, the entity table goes on the left and you `LEFT JOIN` everything else onto it. The rule of thumb I use: the thing you're counting *by* — the `GROUP BY` subject — belongs on the left, always.

But look hard at Dorothy's `revenue` cell. It's not `0`. It's blank. That empty space is the second footgun, and it's the one that actually detonates.

## Mitigation 2: `COALESCE(SUM(...), 0)` — because SUM over nothing is NULL, not zero

Intuition says summing an empty set gives zero. SQL disagrees, and it's right by the standard, which does not make it less dangerous. `SUM` over zero rows returns `NULL` — the absence of a value, not the value nothing. Let me prove it rather than assert it:

```sql
SELECT c.name, SUM(o.amount) AS revenue, SUM(o.amount) IS NULL AS is_null
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE c.name = 'Dorothy'
GROUP BY c.id;
```

```text
name     revenue  is_null
-------  -------  -------
Dorothy           1
```

`is_null` is `1`. Dorothy's revenue is genuinely `NULL`. And `NULL` is contagious: it sorts weird, it breaks `revenue < 100` filters (a `NULL` comparison is neither true nor false, so the row silently fails the `WHERE`), and if anyone downstream does arithmetic on it — `revenue * 1.1`, `revenue - cost` — the whole expression collapses back to `NULL`. You fixed the missing row and planted a missing *value* in its place. Wrap the aggregate in `COALESCE`, which returns its first non-`NULL` argument:

```sql
SELECT c.name, COUNT(o.id) AS orders, COALESCE(SUM(o.amount), 0) AS revenue
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id
ORDER BY c.id;
```

```text
name       orders  revenue
---------  ------  -------
Ada        2       150
Grace      2       120
Katherine  1       200
Dorothy    0       0
Radia      1       60
```

Dorothy is a real `0` now — a number you can sort, filter, and multiply without the row evaporating. `COALESCE(SUM(x), 0)` is the reflex. Put it on every aggregate in a `LEFT JOIN` report, not just the ones you *think* can be empty, because the whole point is you can't always see which customer has no orders until the day one doesn't.

## Mitigation 3: put the filter in `ON`, not `WHERE` — the condition that quietly re-arms the trap

This is the nastiest one, because you can do everything above correctly and then undo all of it with one innocent-looking line. Say you only want *paid* revenue — exclude refunds. The obvious move is to add `WHERE o.status = 'paid'`. Watch what it does:

```sql
SELECT c.name, COALESCE(SUM(o.amount), 0) AS paid_revenue
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
WHERE o.status = 'paid'
GROUP BY c.id
ORDER BY c.id;
```

```text
name       paid_revenue
---------  ------------
Ada        150
Grace      40
Katherine  200
```

Back to **four rows**. Dorothy's gone *again* — and this time she took Radia with her, because Radia's only order was a refund. Here's the mechanism, and it's worth burning into memory: the `LEFT JOIN` dutifully produces a Dorothy row with all the `orders` columns set to `NULL`. Then the `WHERE o.status = 'paid'` runs *after* the join and asks, is `NULL` equal to `'paid'`? The answer is `NULL`, which is not true, so the row is discarded. A `WHERE` condition on a right-table column silently converts your `LEFT JOIN` back into an `INNER JOIN`. You wrote `LEFT`; the optimizer heard `INNER`; nobody told you.

The fix is to move the condition into the `ON` clause, where it filters *which order rows get joined* instead of *which result rows survive*:

```sql
SELECT c.name, COALESCE(SUM(o.amount), 0) AS paid_revenue
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id AND o.status = 'paid'
GROUP BY c.id
ORDER BY c.id;
```

```text
name       paid_revenue
---------  ------------
Ada        150
Grace      40
Katherine  200
Dorothy    0
Radia      0
```

Five rows. Dorothy: `0`, correctly, she never ordered. Radia: `0`, correctly, her only order was refunded — she stays *in the report* as a customer with zero paid revenue, which is exactly the person a retention team wants to see. `ON` filters the join; `WHERE` filters the survivors. On the outer side of a `LEFT JOIN` those are not the same operation, and confusing them is how a "small tweak to exclude refunds" quietly deletes your churned customers a second time.

## The scorecard, all rows real

| The report you meant | The query you wrote | Who silently vanished |
|---|---|---|
| Revenue per customer | `JOIN` (inner) | Dorothy — zero orders |
| Revenue per customer | `LEFT JOIN`, bare `SUM` | nobody, but Dorothy's total is `NULL` |
| Revenue per customer | `LEFT JOIN` + `COALESCE` | nobody — correct |
| Paid revenue per customer | `LEFT JOIN` + `WHERE o.status='paid'` | Dorothy *and* Radia |
| Paid revenue per customer | `LEFT JOIN` + `ON ... AND o.status='paid'` | nobody — correct |

Three mitigations, ranked: **`LEFT JOIN` so the entities can't drop**, **`COALESCE(SUM(...), 0)` so the empties are zeros and not contagious nulls**, and **filter right-table conditions in `ON`, not `WHERE`, so your outer join stays outer.** None of them is "be more careful." Careful is not a control; a query is.

## When this goes wrong (walking the paranoia back)

Now let me talk myself down, because the point of threat-modeling is to end at what a normal person should actually do, not to leave you afraid of the keyword `JOIN`.

- **`WHERE ... IS NULL` on the right table is not the bug — it's a real tool.** The
  trap is a `WHERE` that *compares* a right-table column to a value. A `WHERE` that checks for `NULL` on purpose is the anti-join, and it's the cleanest way to ask "who has zero orders?":

  ```sql
  SELECT c.name FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.id
  WHERE o.id IS NULL;
  ```

  ```text
  name
  -------
  Dorothy
  ```

  That returned exactly Dorothy, which is the correct answer. Same shape as the footgun, opposite intent — you're keeping the unmatched rows, not discarding them.
- **`COUNT(*)` lies where `COUNT(o.id)` tells the truth.** On Dorothy's row, `COUNT(*)`
  counts the one result row and returns `1`; `COUNT(o.id)` counts non-`NULL` order ids and returns `0`. In a `LEFT JOIN`, always `COUNT` a specific right-table column, never `*`, or your no-order customers will each claim one phantom order.
- **This isn't a SQLite quirk.** The `INNER`-drops-unmatched-rows behavior, the
  `SUM`-of-nothing-is-`NULL` behavior, and the `WHERE`-demotes-your-outer-join behavior are all standard SQL. Postgres, MySQL, SQL Server — same trap, same three fixes. Reproduce it on whatever you ship; it'll behave the same way SQLite just did.

I still don't trust the number in the corner of your dashboard. But now you can prove whether it's counting everyone or just the survivors — and "prove," not "feels right," is the only thing I've ever accepted as a security control.
