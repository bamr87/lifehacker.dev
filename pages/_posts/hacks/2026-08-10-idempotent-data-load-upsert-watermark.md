---
title: "Run your data load twice on purpose: the upsert and watermark that survive a retry"
description: "I ran the same data load twice, then 10,000 times. The naive one doubled every row; ON CONFLICT DO UPDATE plus an inclusive watermark held the line."
date: 2026-08-10
preview: /images/previews/run-your-data-load-twice-on-purpose-the-upsert-and.jpg
categories: [Hacks]
tags: [data, shell]
author: edge
excerpt: "A data load you can only run once isn't a data load, it's a landmine. I ran this one 10,000 times to prove which version defuses it."
permalink: /hacks/idempotent-data-load-upsert-watermark/
---
I don't trust a data load until I've run it twice. A load that's only correct the first time isn't a pipeline, it's a landmine with a cron schedule — and cron, retries, a nervous engineer hitting up-enter, and a CI job that re-runs on flake will all step on it eventually. So I did the stepping on purpose. Every number below came out of a throwaway SQLite 3.45 database on my machine; run the same commands against a throwaway of your own and you'll get the same counts.

The idea comes straight from [it-journey.dev's ETL pipeline design quest](https://it-journey.dev/quests/1100/etl-pipeline-design/), which lays out "make your loads rerunnable" as a design principle. This is the QA companion: the same principle, but I fed it the retry it's supposed to survive and published the table either way.

## The load that only works once (the one you probably shipped)

Here's the load everybody writes first. A table, an `INSERT`, three rows from the source. Run it once and it's perfect:

```console
$ sqlite3 naive.db "CREATE TABLE orders (id INTEGER, customer TEXT, amount REAL);
  INSERT INTO orders VALUES (1,'ana',10.0),(2,'ben',20.0),(3,'cy',30.0);"
$ sqlite3 naive.db "SELECT count(*) AS rows, round(sum(amount),2) AS total FROM orders;"
3|60.0
```

Three rows, total 60. Ship it. Now the part nobody tests before shipping: the second run. The source hasn't changed, the cron fired again, the load runs again.

```console
$ sqlite3 naive.db "INSERT INTO orders VALUES (1,'ana',10.0),(2,'ben',20.0),(3,'cy',30.0);"
$ sqlite3 naive.db "SELECT count(*) AS rows, round(sum(amount),2) AS total FROM orders;"
6|120.0
$ sqlite3 naive.db "SELECT * FROM orders WHERE id=2;"
2|ben|20.0
2|ben|20.0
```

Six rows. Revenue just doubled to 120 with nobody buying anything, and Ben — who ordered exactly once — is now two Bens. **This is the failure this whole post exists to prevent:** a retry that silently double-counts, which downstream shows up as a revenue chart that looks great until finance asks why. The table has no primary key, so nothing stops the same `id` from landing twice. That's the bug. Everything below is me trying to break the fixes.

## Fix attempt #1: add a primary key and hope — ❌

Give `orders` a `PRIMARY KEY` on `id` and the plain `INSERT` can no longer duplicate a row. It can, however, do something arguably worse:

```console
$ sqlite3 traps.db "INSERT INTO orders VALUES (1,'ana',10.0),(2,'ben',20.0),(3,'cy',30.0);"
Error: stepping, UNIQUE constraint failed: orders.id (19)
$ echo "exit: $?"
exit: 19
```

`UNIQUE constraint failed`, exit code 19, and the whole batch aborts. The primary key stopped the double-count and replaced it with a crash on every rerun — which means your load is now un-retryable by design. The failure this prevents (duplicates) got traded for a new one (a pipeline that red-lights the second time cron looks at it). Not a fix. A different landmine.

## Fix attempt #2: INSERT OR IGNORE — ❌ (the quiet one)

`INSERT OR IGNORE` is the reflex fix: on a key collision, skip the row instead of erroring. It never crashes, so it *feels* idempotent. I ran the scenario that matters — a rerun where one value was corrected upstream. Ben's amount got fixed to 25.0 at the source:

```console
$ sqlite3 traps.db "INSERT OR IGNORE INTO orders VALUES (2,'ben',25.0);"
$ sqlite3 traps.db "SELECT amount FROM orders WHERE id=2;"
20.0
```

Still 20.0. `OR IGNORE` saw the existing `id=2`, shrugged, and threw away the correction. **The failure this hides:** your reruns look clean, no duplicates, no errors — and every upstream fix after the first load silently never arrives. That's the worst kind of bug, the one that passes every test that isn't looking for it. `OR IGNORE` is fine when rows are write-once and immutable; the moment a value can change, it's a data-loss trap wearing an idempotency costume.

## The fix that holds: ON CONFLICT DO UPDATE — ✅

`INSERT ... ON CONFLICT(id) DO UPDATE SET ...` — the upsert — is the one that survives the gauntlet. On a new `id` it inserts; on a collision it updates the row in place to match the source. Re-running it is a no-op when nothing changed, and a correction when something did. I ran the identical load four times:

```console
$ UPSERT="INSERT INTO orders(id,customer,amount) VALUES (1,'ana',10.0),(2,'ben',20.0),(3,'cy',30.0)
    ON CONFLICT(id) DO UPDATE SET customer=excluded.customer, amount=excluded.amount;"
$ sqlite3 upsert.db "$UPSERT"; sqlite3 upsert.db "$UPSERT"
$ sqlite3 upsert.db "$UPSERT"; sqlite3 upsert.db "$UPSERT"
$ sqlite3 upsert.db "SELECT count(*) AS rows, round(sum(amount),2) AS total FROM orders;"
3|60.0
```

Four runs, still three rows, still 60. The `excluded.` prefix is the SQLite (and Postgres) keyword for "the row you tried to insert" — so `DO UPDATE SET amount=excluded.amount` means "keep the incoming value." That's what makes the correction land where `OR IGNORE` dropped it:

```console
$ sqlite3 upsert.db "INSERT INTO orders(id,customer,amount) VALUES (2,'ben',25.0)
    ON CONFLICT(id) DO UPDATE SET amount=excluded.amount;"
$ sqlite3 upsert.db "SELECT * FROM orders WHERE id=2;"
2|ben|25.0
```

Ben is 25.0 now. One Ben. Correct value. That's the difference between "never errors" and "actually right."

You'll know it worked when the row count stops moving no matter how many times you run the load. So I stopped running it four times and ran it ten thousand:

```console
$ { echo "BEGIN;"
    for i in $(seq 1 10000); do
      echo "INSERT INTO orders(id,customer,amount) VALUES (1,'ana',10.0),(2,'ben',20.0),(3,'cy',30.0)
        ON CONFLICT(id) DO UPDATE SET amount=excluded.amount;"
    done
    echo "COMMIT;"; } | sqlite3 stress.db
$ sqlite3 stress.db "SELECT count(*) FROM orders;"
3
$ sqlite3 stress.db "SELECT round(sum(amount),2) FROM orders;"
60.0
```

Ten thousand loads. Three rows. Total 60.0. The boring pass is the whole point: an idempotent load run 10,000 times is indistinguishable from one run once, which is the property you actually want when a retry storm hits at 2am.

| Load strategy | Run once | Run twice | Applies a correction? |
|---|---|---|---|
| `INSERT`, no PK | 3 rows | ❌ 6 rows | n/a (double-counts) |
| `INSERT`, with PK | 3 rows | ❌ crashes (exit 19) | n/a (aborts) |
| `INSERT OR IGNORE` | 3 rows | ✅ 3 rows | ❌ silently skips it |
| `ON CONFLICT DO UPDATE` | 3 rows | ✅ 3 rows | ✅ updates in place |

## The second landmine: the incremental load and the boundary second

Upsert fixes the "load doubles" bug. But nobody re-reads the entire source every night — you pull only new rows since last time, using a high-water mark: remember the largest `updated_at` you've seen, and next run grab everything newer. The intuitive filter is `updated_at > watermark`. I built the one case that filter gets wrong on purpose, because that's the job: two source rows sharing the exact same second.

```console
$ sqlite3 wm.db "CREATE TABLE src (id INTEGER PRIMARY KEY, customer TEXT, updated_at TEXT);
  CREATE TABLE dst (id INTEGER PRIMARY KEY, customer TEXT, updated_at TEXT);"
$ sqlite3 wm.db "INSERT INTO src VALUES
    (1,'ana','2026-08-10 09:59:58'),
    (2,'ben','2026-08-10 10:00:00'),
    (3,'cy', '2026-08-10 10:00:00');"
$ sqlite3 wm.db "INSERT INTO dst SELECT * FROM src;"
$ sqlite3 wm.db "SELECT max(updated_at) FROM dst;"
2026-08-10 10:00:00
```

First load: three rows in, watermark recorded as `10:00:00`. Now a fourth row arrives — and it lands at the same boundary second the watermark already points at, which happens constantly when your source stamps whole seconds and writes in batches:

```console
$ sqlite3 wm.db "INSERT INTO src VALUES (4,'del','2026-08-10 10:00:00');"
$ sqlite3 wm.db "INSERT INTO dst SELECT * FROM src WHERE updated_at > '2026-08-10 10:00:00'
    ON CONFLICT(id) DO UPDATE SET customer=excluded.customer, updated_at=excluded.updated_at;"
$ sqlite3 wm.db "SELECT count(*) FROM dst;"
3
$ sqlite3 wm.db "SELECT customer FROM dst WHERE id=4;"

```

Three rows. `del` is gone. The empty last line is `del` not existing in the destination. **The failure this prevents:** `> watermark` silently skips every row that shares the boundary timestamp, so the more rows your source writes per second, the more you lose per run — and you never see an error, because dropping rows isn't an error, it's just a smaller number. This is the ETL bug that gets caught in a reconciliation three weeks later, if it gets caught at all.

## Why the fix is `>=` and not "add a microsecond"

The tempting fix is a stricter filter — bump the watermark by the smallest tick and keep using `>`. Don't. Your source's clock resolution is not yours to assume, and "smallest tick" is a guess that's wrong on the one source that stamps whole seconds. The robust fix is the opposite direction: re-read *inclusively* with `>=`, and let the upsert absorb the rows you re-read. You already proved the upsert doesn't double-count; now you spend that property on purpose.

```console
$ sqlite3 wm.db "INSERT INTO dst SELECT * FROM src WHERE updated_at >= '2026-08-10 10:00:00'
    ON CONFLICT(id) DO UPDATE SET customer=excluded.customer, updated_at=excluded.updated_at;"
$ sqlite3 wm.db "SELECT count(*) FROM dst;"
4
$ sqlite3 wm.db "SELECT customer FROM dst WHERE id=4;"
del
```

Four rows, `del` recovered. Yes, `>=` re-reads Ben and Cy every run because they sit on the boundary. That's the trade, and it's free — I re-ran the inclusive load three more times to prove the overlap costs nothing:

```console
$ for i in 1 2 3; do
    sqlite3 wm.db "INSERT INTO dst SELECT * FROM src WHERE updated_at >= '2026-08-10 10:00:00'
      ON CONFLICT(id) DO UPDATE SET customer=excluded.customer, updated_at=excluded.updated_at;"
  done
$ sqlite3 wm.db "SELECT count(*) FROM dst;"
4
```

Still four. The overlap window re-reads a handful of boundary rows; the upsert makes re-reading them a no-op. Losing a row is a silent, permanent bug; re-reading a row is a few microseconds. Pick the cheap failure on purpose. For real pipelines, widen the window past the exact boundary — subtract a minute (or your source's max clock skew) from the watermark before you filter — so late-arriving rows stamped a hair behind the clock also get swept up. The upsert eats the overlap; the `>=` and the buffer make sure nothing on the edge falls through.

## The part where it goes wrong

Three honest limits, because the gauntlet found them:

- **The upsert needs a real unique key, and it has to be the *business* key.** `ON CONFLICT(id)` de-duplicates on `id`. If your source's natural key is `(order_id, line_number)` and you upsert on an auto-increment surrogate instead, every rerun is a fresh surrogate and you're back to doubling — the constraint has to be on the thing that identifies a row *in the source*, not the thing your database made up.
- **A widened watermark window re-reads rows every run, so the upsert cost is real at scale.** Re-reading 500 boundary/late rows a night is nothing; re-reading a week of data because someone set the buffer to `- 7 days` is a nightly full scan wearing a trench coat. Size the window to your actual clock skew, not to your anxiety.
- **`DO UPDATE` overwrites, which is wrong if the destination is the source of truth for some columns.** If a downstream process enriches a row after load and your upsert blindly `SET`s every column from the source, you'll stomp the enrichment on the next run. Update only the columns the source owns, or add a `WHERE excluded.updated_at > orders.updated_at` clause so a stale re-read can't clobber a newer value.

## Survives-a-Tuesday verdict

**A normal Tuesday:** the upsert-plus-watermark load runs, pulls its new rows, no-ops on the overlap, and you never think about it. ✅

**A bad Tuesday:** cron double-fires, CI retries on a flake, and someone hits up-enter three times in a panic — and the row count doesn't move, because a load run N times equals a load run once. That's the entire reason to build it this way. ✅

**A Tuesday where the intern has sudo:** they re-run last month's load "just to be safe." With the naive `INSERT` that's a doubled month of revenue and a very bad meeting; with the upsert it's a no-op and nobody notices. The idempotent load is the one that survives the intern. ✅

The one-line version: give the destination the business key, load with `INSERT ... ON CONFLICT(key) DO UPDATE SET ...`, pull incrementally with `updated_at >= watermark` minus a skew buffer, and the retry that was going to double your rows becomes the retry nobody has to think about. I ran it 10,000 times so your cron can run it twice.
