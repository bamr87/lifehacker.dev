---
title: "Stop storing a list in one column: the junction table that survives a re-run"
description: "You stuffed 'sql,python' into one cell and now you can't count tags. The fix is a junction table — skip its composite key and every count doubles."
date: 2026-08-26
categories: [Hacks]
tags: [data]
author: edge
preview: /images/previews/stop-storing-a-list-in-one-column-the-junction-tab.svg
excerpt: "The comma-jam LIKE matches 'pythonic' when you asked for 'python'. I fixed it, then broke the fix three ways — and the third one is a real SQLite bug."
permalink: /hacks/junction-table-many-to-many-tags/
---
Someone handed me a `post` table with a column called `tags TEXT`, and inside it, per row, a little comma-separated confession: `'sql,python'`. It works. It demos beautifully. Then the first real question arrives — "how many posts are tagged python?" — and the schema goes quiet, because it has no idea what a tag is. It thinks `'sql,python'` is a *word*.

That's the whole bug, and it never announces itself. It waits for a report. IT-Journey has the earnest, no-grudge walkthrough of how relationships are supposed to work in [Data Modeling: Schema Design and Database Relationships](https://it-journey.dev/quests/0110/data-modeling/); I'm here to build the comma-jam on purpose, prove it lies, replace it with a junction table, and then attack the junction table until something falls off. Everything below ran in a throwaway `sqlite3` (3.45.1) database. The tables are real. The exit codes are real.

## The comma-jam, and the two questions it can't answer

Here's the crime scene. One post is tagged `pythonic` — the Python style, not the language — and that one row is going to matter in a second.

```bash
sqlite3 tags.db <<'SQL'
CREATE TABLE post (
  id    INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  tags  TEXT NOT NULL          -- 'sql,python' — the comma-jam
);
INSERT INTO post (title, tags) VALUES
  ('Indexing basics',        'sql,python'),
  ('Writing pythonic loops', 'pythonic'),
  ('Git bisect walkthrough', 'git,sql'),
  ('Deploying with Docker',  'docker,python');
SQL
```

**Question one: show me every post tagged `python`.** With everything crammed in one cell, your only tool is substring matching, and substrings don't respect word boundaries:

```sql
SELECT title, tags FROM post WHERE tags LIKE '%python%';
```

| title | tags | should it be here? |
|---|---|---|
| Indexing basics | sql,python | ✅ |
| Writing pythonic loops | pythonic | ❌ — that's `pythonic`, not `python` |
| Deploying with Docker | docker,python | ✅ |

`LIKE '%python%'` matched `pythonic`, because `python` is a substring of `pythonic`. You asked for a tag; the database gave you a spelling coincidence. The failure this prevents has a name and a victim: every "posts in category X" page you build this way silently over-counts, and nobody notices until the one edge-case tag ships to production.

**Question two: how many posts have each tag?** This one doesn't even get to be wrong interestingly. It just refuses:

```sql
SELECT tags, count(*) AS n FROM post GROUP BY tags;
```

| tags | n |
|---|---|
| docker,python | 1 |
| git,sql | 1 |
| pythonic | 1 |
| sql,python | 1 |

`GROUP BY tags` grouped by the whole comma-jammed string. As far as SQL is concerned `'sql,python'` and `'docker,python'` have nothing in common — they're different words. There is no query that counts tags here, because there are no tags here. There's a `TEXT` column doing a cosplay of a list.

## The fix: three tables, and a primary key on the pair

A tag is a thing. A post is a thing. "This post has that tag" is *also* a thing — it's a row in a third table, the **junction table** (a.k.a. join table, bridge table, associative table). The pair is the whole point, so the pair is the primary key.

```sql
PRAGMA foreign_keys = ON;                 -- more on this landmine below

CREATE TABLE post (
  id    INTEGER PRIMARY KEY,
  title TEXT NOT NULL
);
CREATE TABLE tag (
  id   INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE                -- 'python' exists exactly once
);
CREATE TABLE post_tag (
  post_id INTEGER NOT NULL REFERENCES post(id) ON DELETE CASCADE,
  tag_id  INTEGER NOT NULL REFERENCES tag(id)  ON DELETE CASCADE,
  PRIMARY KEY (post_id, tag_id)           -- the same pair can't be linked twice
);
```

Now the two impossible questions are one JOIN each. `python` is `python`; `pythonic` is a different row with a different id, and no substring can confuse them:

```sql
SELECT p.title
FROM post p
JOIN post_tag pt ON pt.post_id = p.id
JOIN tag t       ON t.id = pt.tag_id
WHERE t.name = 'python';
```

| title |
|---|
| Indexing basics |
| Deploying with Docker |

Two rows. `Writing pythonic loops` is correctly absent — I ran it, it stayed gone. And the count that couldn't exist before:

```sql
SELECT t.name, count(*) AS posts
FROM tag t
JOIN post_tag pt ON pt.tag_id = t.id
GROUP BY t.name
ORDER BY posts DESC, t.name;
```

| name | posts |
|---|---|
| python | 2 |
| sql | 2 |
| docker | 1 |
| git | 1 |
| pythonic | 1 |

That's the migration. It's not more code than the comma-jam; it's the same amount of code that happens to answer questions. But I don't trust a schema until I've tried to make it lie, so here's the gauntlet.

## The gauntlet: I broke it three ways, and the third one is a real bug

### Break 1: drop the composite key, re-run the import once

The `PRIMARY KEY (post_id, tag_id)` line is not decoration. Delete it — leave `post_tag` as two bare columns — and nothing stops the same link from being inserted twice. Which is exactly what happens the first time someone re-runs a tagging script, or double-clicks Save, or your CI replays a seed file.

```sql
CREATE TABLE post_tag (post_id INTEGER NOT NULL, tag_id INTEGER NOT NULL);  -- no PK, no UNIQUE
INSERT INTO post_tag VALUES (1,1),(1,2);   -- import runs...
INSERT INTO post_tag VALUES (1,1),(1,2);   -- ...import runs again
```

One post, tagged `python` exactly once in reality. Ask the database:

```sql
SELECT count(*) AS posts_tagged_python FROM post_tag WHERE tag_id = 2;
```

| posts_tagged_python | truth |
|---|---|
| 2 | should be 1 |

Every count doubled. Silently. No error, no warning — your analytics dashboard just quietly claims twice the engagement, and it'll survive code review because the *query* is correct. The data is what's lying. Put the composite key back and the second import can't land:

```
sqlite> INSERT INTO post_tag VALUES (1,1);
Runtime error: UNIQUE constraint failed: post_tag.post_id, post_tag.tag_id (19)
```

Exit code 19. That's the database refusing to double your numbers. If you want re-runnable imports without the crash, `INSERT OR IGNORE` turns the second run into a no-op — I ran it, `changes()` reported `0` rows inserted the second time, total links stayed at 2. Idempotent by construction.

### Break 2: a tag literally named `python,sql`

Absurd? Sure. A user with a comma in their free-text tag input is a Tuesday, though. In the junction model the name is just a string — comma and all — so `'python,sql'` is one tag with a weird name sitting right next to the real `'sql'`, and the `UNIQUE` on `tag.name` keeps them distinct. No ambiguity. In the comma-jam model the same input is an existential question the schema cannot answer: is `'python,sql'` one tag or two? `LIKE '%sql%'` matches it either way and never tells you which it meant. The junction table shrugged this off. Grudging point to the junction table.

### Break 3: the composite primary key that let a duplicate through anyway

Here's the one I didn't expect, and it's why I run the third ridiculous test. I built the junction table *with* its composite primary key — but I forgot `NOT NULL` on the columns. Watch:

```sql
CREATE TABLE post_tag (
  post_id INTEGER,
  tag_id  INTEGER,
  PRIMARY KEY (post_id, tag_id)   -- note: NO 'NOT NULL'
);
INSERT INTO post_tag VALUES (1, NULL);
INSERT INTO post_tag VALUES (1, NULL);   -- identical row. rejected, right?
```

| rowid | post_id | tag_id |
|---|---|---|
| 1 | 1 | *(null)* |
| 2 | 1 | *(null)* |

**Both rows went in.** Two identical `(1, NULL)` links, under a PRIMARY KEY that's supposed to forbid duplicates. This isn't SQLite being broken — it's SQLite being *old*. Per its docs, in most SQL engines a `PRIMARY KEY` implies `NOT NULL`, but SQLite got that wrong in an early version, and a database out there depended on the bug, so it's load-bearing now: PRIMARY KEY columns may contain NULL (except the rowid alias), and — because `NULL != NULL` — the uniqueness check treats every NULL as a fresh, unique value. So your composite key, the whole reason you built the junction table, quietly stops guarding the moment a NULL sneaks in. Your counts double again, and this time the constraint is *right there in the schema* looking innocent.

The fix is one keyword per column, which is why the good schema up top has it:

```
sqlite> -- with NOT NULL on both columns:
sqlite> INSERT INTO post_tag VALUES (1, NULL);
Runtime error: NOT NULL constraint failed: post_tag.tag_id (19)
```

Rejected, exit 19. The NULL never gets the chance to be uniquely useless.

## The other landmine: `PRAGMA foreign_keys = ON`

While I was in there: SQLite does not enforce foreign keys by default. It parses `REFERENCES tag(id)`, nods politely, and then lets you insert a `post_tag` row pointing at a tag that doesn't exist.

```sql
CREATE TABLE post_tag (post_id INTEGER, tag_id INTEGER REFERENCES tag(id), PRIMARY KEY(post_id,tag_id));
INSERT INTO tag VALUES (1,'sql');
INSERT INTO post_tag VALUES (1, 999);   -- tag 999 does not exist
```

That inserted cleanly — exit 0, one orphaned link now haunting your junction table. Turn the pragma on and the same insert fails with `FOREIGN KEY constraint failed (19)`. The catch nobody mentions: **the pragma is per-connection, not per-database.** You have to set it on every connection, every session — your app's connection pool, your migration tool, and the `sqlite3` shell you're debugging in all need it independently. Set it in your pool's connect hook and forget it there, not in a migration that runs once.

## Verdict, on the survives-a-Tuesday scale

The comma-jam **fails a normal Tuesday**: the first `GROUP BY` that matters returns garbage and the first `pythonic`/`python` collision ships a wrong count to prod.

The junction table **survives a Tuesday where the intern has sudo**, on three conditions I actually tested to destruction:

1. `PRIMARY KEY (post_id, tag_id)` — or the re-run doubles every count.
2. `NOT NULL` on both columns — or SQLite's NULL loophole doubles them anyway, under a primary key that looks like it's watching.
3. `PRAGMA foreign_keys = ON` on every connection — or your links point at tags that were deleted last month.

Miss any one and the schema goes back to lying, just more quietly than the comma column did. Which is the real lesson: a constraint you didn't write is a bug you're storing for later. Write all three. The database will spend the rest of its life refusing to give you a wrong number, which is the only kind of database worth having.
