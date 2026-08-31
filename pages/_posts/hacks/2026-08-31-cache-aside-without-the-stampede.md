---
title: "Cache-aside without the stampede: the fix for the herd that hits your DB when a hot key expires"
description: "I fired 1,000 concurrent readers at one expired cache key. Naive cache-aside sent 951 of them to the database at once. A single-flight lock sent 1."
date: 2026-08-31
preview: /images/previews/cache-aside-without-the-stampede-the-fix-for-the-h.svg
categories: [Hacks]
tags: [data, web-dev]
author: edge
excerpt: "A cache that works until a popular key expires isn't a cache, it's a delayed-action outage. I ran 1,000 readers at one expired key to prove which version survives it."
permalink: /hacks/cache-aside-without-the-stampede/
---
I don't trust a cache until I've watched a hot key expire under load. A cache that speeds things up on a calm Tuesday is easy; the question I get paid to ask is what happens in the one millisecond after your most-requested key hits its TTL, when a thousand requests all discover it's gone at the same instant. If the answer is "they all go ask the database," you didn't build a cache, you built a snooze button on an outage. So I built the herd and ran it. Every number below came out of a throwaway Python 3.12 script on my machine — a threading model where a shared counter stands in for "expensive database query" — and if you run the same script you'll get the same shape of number.

The pattern comes straight from [it-journey.dev's scaling-strategies quest](https://it-journey.dev/quests/1110/scaling-strategies/), which lists caching as a horizontal-growth lever. This is the QA companion: the same pattern, but I fed it the concurrency it's supposed to survive and published the table either way.

## The pattern that's genuinely worth it (the useful part)

Cache-aside is the read path everybody actually ships, and it earns its keep: **check the cache; on a hit, return it; on a miss, read the source of truth, write it back with a TTL, and return it.** The fastest request is the one you never compute, and once a value is warm every subsequent reader gets it for free until the TTL runs out.

```python
cache = {}                    # key -> (value, expires_at)
def get_naive(key, ttl=1.0):
    now = time.monotonic()
    hit = cache.get(key)
    if hit and hit[1] > now:
        return hit[0]         # fresh hit — never touches the DB
    value = read_from_db(key) # MISS: everyone who reaches here hits the DB
    cache[key] = (value, now + ttl)
    return value
```

That's the whole pattern, and for a single reader it's flawless. My job is the part where there isn't a single reader.

## Part 1: the stampede — 1,000 readers, one expired key

Here's the test the tutorial never runs. Warm the key, wait for its TTL to expire so it's cold, then launch 1,000 threads that all call `get_naive("hotkey")` at once. `read_from_db` bumps a counter and sleeps 50ms — slow on purpose, so the concurrent misses overlap the way real queries do:

```console
$ python3 stampede.py
naive cache-aside: 1000 concurrent readers hit an expired key -> 951 DB queries
```

951. Out of 1,000 readers who wanted one cached value, 951 of them independently decided the cache was empty and went to the database, because every one of them checked the cache in the window *before* the first miss finished writing its result back. **This is the failure this whole post exists to prevent:** the thundering herd, where the cache expiring on a popular key doesn't cause a slow request, it causes a synchronized denial-of-service against your own database, launched by your own users, triggered by a clock. Run it three more times and the number wobbles but never behaves — 963, 957, 946. The cache didn't reduce load at the one moment load mattered; it stored it up and released it all at once.

## The fix: a single-flight lock (1,000 misses, 1 query)

The fix is to make exactly one reader recompute while the rest wait for it. Take a per-key lock on a miss; the first thread through computes and writes the value; everyone else blocks on the lock, and — this is the part people forget — **re-checks the cache after acquiring it**, finds the value the first thread just wrote, and returns that instead of computing again.

```python
def get_singleflight(key, ttl=1.0):
    now = time.monotonic()
    hit = cache.get(key)
    if hit and hit[1] > now:
        return hit[0]
    with lock_for(key):                 # single-flight gate: one recompute at a time
        now = time.monotonic()
        hit = cache.get(key)            # DOUBLE-CHECK after acquiring the lock
        if hit and hit[1] > now:
            return hit[0]               # someone recomputed while we waited — reuse it
        value = read_from_db(key)
        cache[key] = (value, now + ttl)
        return value
```

Same 1,000 threads, same expired key:

```console
$ python3 singleflight.py
single-flight lock: 1000 concurrent readers hit an expired key -> 1 DB queries
```

One. And it's one every single time I run it, not "usually one" — the double-check inside the lock is what makes it deterministic, because the 999 threads that were waiting don't blindly recompute the moment the lock frees, they look again first. Drop that re-check and you get a lock that serializes the herd instead of collapsing it: still 1,000 queries, now politely one at a time, which is arguably worse because it's slow *and* it hammers the DB. The whole fix lives in those three re-check lines. This is the pattern Go's `singleflight` package and every mature cache library implement; the name for a distributed version is a "mutex key" or "lock-and-compute," and the shape is identical.

## Part 2: the TTL is not invalidation (the stale-read trap)

A TTL answers "how long may this be wrong?" — it does **not** answer "this is wrong *now*." If the underlying data changes, a TTL-only cache keeps serving the old value until the timer runs out. So a write has to bust the key. Fine. Except the busting has its own race, and it's the one that poisons your cache for a full TTL. Watch a slow reader and a writer overlap:

```console
$ python3 invalidation.py
  reader: cache miss, read db -> v1
  writer: db=v2, cache busted
  reader: wrote 'v1' back to cache
  final: db = v2 | cache = v1 <- stale!
```

Read that order twice, because it's the whole bug. The reader missed, read `v1` from the database, and then *stalled* — GC pause, slow network, a rescheduled thread, take your pick. During the stall the writer updated the database to `v2` and correctly deleted the cache key. Then the reader woke up and finished its job: it wrote the value it had, `v1`, back into the cache. The database says `v2`; the cache now says `v1`; and it will keep saying `v1` until the TTL expires, because the write that was supposed to fix it already happened *before* the stale value landed. **The failure this prevents:** a cache that's wrong not for a few milliseconds but for the entire TTL, silently, with no error anywhere, because "wrote an old value" isn't an exception, it's just the wrong number.

The mitigations, ranked by how much I trust them: keep the TTL short enough that a poisoned key self-heals fast (the TTL is your backstop, not your invalidation); on write, delete the key *after* the database commits, not before (delete-first leaves a window where a reader repopulates from the not-yet-updated DB); and for the values you truly can't serve stale, stop caching the value and start caching a version number — write the new version on update, and let a reader that wrote a lower version lose. All three shrink the window; none of them is "be careful," because "be careful" has never once won a race against a GC pause.

## Part 3: don't let every key expire on the same tick

One more scenario, because the herd has a cousin. Suppose you warm 50 keys in a single burst — a cold start, a deploy, a full cache flush at 3am. Give them all the same TTL and they all expire at the same instant, and now you have 50 simultaneous stampedes instead of one. The fix is a splash of randomness on the TTL so expirations scatter. I loaded 50 keys both ways and counted the worst 100ms window:

```console
$ python3 jitter.py
TTL 10s, no jitter: worst-case 50 of 50 keys expire in the same 100ms window
TTL 10s +/-10% jitter: worst-case 6 of 50 keys expire in the same 100ms window
```

Without jitter, all 50 keys expire in one 100ms window — one burst, maximum pain. Add `±10%` random jitter to each TTL and the worst window drops to 6. The jitter costs nothing (a `random.uniform(-jitter, jitter)` added to `now + ttl`) and it turns one cliff into a gentle slope. **The failure this prevents:** the synchronized-expiry stampede, where the thing that expires isn't one hot key but your entire warm set at once, usually right after the deploy you did to fix the last outage.

## The results, on one table

| Read strategy | 1,000 readers, expired hot key | Serves stale after a write? | Handles a burst-loaded key set? |
|---|---|---|---|
| Naive cache-aside | ❌ 951 DB queries | ❌ until TTL | ❌ synchronized expiry |
| Single-flight lock | ✅ 1 DB query | ❌ still needs invalidation | ❌ still needs jitter |
| + delete-after-commit + short TTL | ✅ 1 DB query | ✅ self-heals fast | ❌ still needs jitter |
| + TTL jitter | ✅ 1 DB query | ✅ self-heals fast | ✅ 6-of-50 worst window |

The three fixes are independent and you want all three: single-flight kills the per-key herd, ordered invalidation plus a short TTL kills the stale read, and jitter kills the whole-keyset cliff. Ship only the first and a deploy still stampedes you; ship only the second and one hot key still floods the DB.

## The part where it goes wrong

Three honest limits, because the gauntlet found them:

- **My single-flight lock is in-process. Your cache probably isn't.** A `threading.Lock` coordinates threads in one Python process; it does nothing for four app servers behind a load balancer, which is exactly when you have a stampede. Distributed, the "lock" becomes a short-lived key in the cache itself (`SET lockkey <token> NX EX 5`), and now you've signed up for the entire distributed-lock problem — the lock holder that dies mid-compute and leaves everyone blocked until the lock's own TTL, the token you must check before deleting so you don't free someone else's lock. The pattern is the same; the failure modes multiply.
- **Single-flight trades a stampede for a latency spike.** While one reader recomputes, the other 999 wait for it. If the recompute takes 3 seconds, all 1,000 requests take 3 seconds instead of one taking 3 and 999 taking 3 *anyway*. It's a strictly better deal for the database, not a free one for the user. The upgrade is to serve the slightly-stale value while a single background refresh runs — "stale-while-revalidate" — which nobody who hasn't first been burned by a stampede bothers to build.
- **Jitter is a knob, and both ends are wrong.** Too little and you've barely spread the cliff; too much and short-lived data lives measurably longer than its TTL claims, which matters the day someone sets a 60-second TTL for a reason and jitter makes it 90. Size the jitter to a fraction of the TTL you can actually tolerate being wrong, not to your anxiety about stampedes.

## Survives-a-Tuesday verdict

**A normal Tuesday:** traffic is warm, keys are fresh, every reader gets a cache hit and the database naps. Naive cache-aside passes this Tuesday, which is why it ships. ✅ (for all four rows)

**A bad Tuesday:** your most-popular key expires during peak traffic. Naive: 951 queries in one millisecond and a database that tips over. Single-flight: 1 query and 999 readers who wait a few extra milliseconds and never notice. ✅ only with the lock.

**A Tuesday where the intern has sudo:** they flush the entire cache "to fix a stale value," at peak, on a Friday. Naive: every warm key stampedes at once, the classic self-inflicted outage. With single-flight *and* jitter: one query per key, expirations already scattered, and the flush is a shrug instead of an incident. The cache that survives the intern is the one that assumed the intern. ✅ only with all three.

The one-line version: cache-aside is worth it, but the miss on a hot key is a stampede, the write after a miss is a stale-read race, and a burst-loaded key set is a synchronized cliff — so put a single-flight lock on the recompute, delete the key *after* the commit behind a short TTL, and jitter the TTLs so nothing expires in a crowd. I ran 1,000 readers at one dead key so your production cache can survive the first time it happens to you.
