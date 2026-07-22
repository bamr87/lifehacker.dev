---
title: "Your connection pool is too big: size it by cores, not hope"
description: "Why a big database pool is a self-inflicted DoS, the idle-in-transaction leak that drains it, and three ranked, tested fixes: sizing, a finally, PgBouncer."
preview: /images/previews/your-connection-pool-is-too-big-size-it-by-cores-n.svg
date: 2026-07-21
categories: [Hacks]
tags: [data, security]
author: cass
excerpt: "Nobody attacks your database. You do, every deploy, with a pool_size someone copied from a 2013 blog post and set to 200."
permalink: /hacks/size-your-connection-pool-by-cores/
---
Somebody, right now, is trying to take your app down with a flood of connections. It's you. You do this every time traffic is good.

Here is the thriller version I lie awake on. Your product hits the front page. Ten thousand happy users arrive at once. Your app, eager to serve them, opens a connection for each — because the pool is set to 200 per instance and you run twelve instances, so it reaches for 2,400 connections against a Postgres configured for 100. Postgres, being a database and not a magician, starts refusing. Your health check, which also needs a connection, can't get one. The orchestrator sees the health check fail and kills the instance. The remaining instances inherit the traffic and the stampede, and reach for *more* connections. Somewhere a pager goes off. Somewhere a VP asks if it was "a DDoS." It was. The threat actor was your own success, wielding a config default.

**SEVERITY:** your best traffic day. **ATTACK VECTOR:** a `pool_size` someone pasted from a 2013 blog post and rounded up to feel safe.

Let me walk that back to the boring true version, because the boring true version is the one that hangs your checkout page. There is no attacker. There is a widespread, sincere belief that a bigger connection pool serves more users, and it is exactly backwards. This is the idea that sent me down the rabbit hole — I found it laid out plainly in [it-journey.dev's connection-pooling quest](https://it-journey.dev/quests/0110/connection-pooling/); this is the paranoid, run-it-yourself companion.

Every claim below is real output from a throwaway Postgres 16 in Docker, which I built, broke on purpose, and deleted. Point the same commands at a throwaway of your own.

## First, the thing nobody threat-models: a connection is a whole process

Here is the fact the entire pool-sizing argument rests on. In Postgres, a connection is not a cheap handle. It is a forked operating-system process, with its own memory. Open two connections and leave them idle, then look at the server from the outside:

```console
$ docker exec pg ps -eo pid,cmd | grep 'postgres postgres'
    115 postgres: postgres postgres 172.17.0.1(39152) idle
    116 postgres: postgres postgres 172.17.0.1(39150) idle
```

Two idle connections, two real PIDs. Not two rows in a table — two processes the kernel schedules. A pool of 500 is a promise to fork 500 processes that mostly sit there, each holding memory, all competing for the same handful of CPUs. Which is the second fact:

```console
$ docker exec pg nproc
4
```

Four cores. A machine with four cores can do *four* things at literally the same instant. The other 496 connections in your pool of 500 are not doing work in parallel; they are taking turns, and the taking-of-turns has overhead. Past a point, adding connections makes the database slower, not faster — you've hired 500 cashiers for a shop with four registers and told them all to clock in.

And there is a hard ceiling you will hit long before "slower." Postgres ships defaulting to 100 connections total:

```console
$ psql -tAc "show max_connections;"
100
```

Cross that line and the database stops being slow and starts saying no. I set a fresh box to `max_connections=10` to make the wall cheap to hit, then opened connections until it broke:

```console
$ psql -tAc "show max_connections;"
10
$ psql -tAc "show superuser_reserved_connections;"
3
$ # open a dozen concurrent clients against a 10-connection server...
psql: error: connection to server at "localhost" (::1), port 5434 failed:
FATAL:  sorry, too many clients already
```

`FATAL: sorry, too many clients already`. That is the sound of your pool being too big for your database. Note the reserved three: Postgres holds back `superuser_reserved_connections` so an admin can still get in to see what's on fire — which means your app's *usable* ceiling is even lower than the number you read off `max_connections`. Your monitoring, your migrations, and your 2am rescue session all draw from the same 100.

So the pool is not a throughput dial you turn up. It's a loaded gun pointed at your own database, and the default setting is "large." Three mitigations, ranked for the threat that's actually in play — your own traffic exhausting your own database.

## The three mitigations, ranked

### 1. Size the pool to the hardware, not to your hopes

The counterintuitive fix for a slow, connection-starved app is to make the pool *smaller*. The number that has survived the most production contact is HikariCP's formula: `connections = (cores * 2) + 1`. Two times cores because while one query waits on disk, another can use the CPU; the plus-one is headroom. On the four-core box above, that is not 200:

```console
$ echo "connections = $(nproc) * 2 + 1 = $(( $(nproc) * 2 + 1 ))"
connections = 4 * 2 + 1 = 9
```

Nine. Per instance. It looks absurdly small if you've been raised on big-number configs, and it is almost certainly more than enough, because those nine connections are nine processes actually getting CPU time instead of five hundred processes fighting over it. The pool's job is not to have a connection ready for every user; it's to have a connection ready for every *core that can do work*, and to make everyone else wait in an orderly line for a few milliseconds instead of stampeding the database.

The security framing, since that's my beat: a bounded pool is a bulkhead. When traffic spikes past what you can serve, a small pool queues the overflow in your app — where you control the timeout and can shed load — instead of forwarding the stampede to Postgres, where the failure mode is "everything, including the health check, gets nothing." Set the ceiling low and set it deliberately. `(cores * 2) + 1` is the honest starting point; measure from there.

**Ranked #1** because it's the one setting that turns the loaded gun into a queue. Every other fix here assumes the pool is bounded in the first place.

### 2. Return the connection in a `finally` — the leak that empties any pool

Now the failure that stays in, because a perfectly-sized pool still hangs if your code never gives connections back. This is the one in the title, and it's the one that actually pages people.

A connection you borrow and forget to return doesn't crash. It sits, mid-transaction, holding its slot, doing nothing. Postgres has a name for it. I opened one connection, started a transaction, ran a write, and then — simulating a code path that returns without committing — just walked away. From another session:

```console
$ psql -x -c "SELECT pid, state, wait_event_type,
    now()-state_change AS idle_for, left(query,45) AS last_query
  FROM pg_stat_activity WHERE state = 'idle in transaction';"
-[ RECORD 1 ]---+----------------------------------------------
pid             | 103
state           | idle in transaction
wait_event_type | Client
idle_for        | 00:00:01.994913
last_query      | UPDATE pg_class SET reltuples = reltuples WHE
```

`idle in transaction`. The `wait_event_type` is `Client` — the database is not busy; it is *waiting for your application code* to say something, anything, and your code has moved on and forgotten this connection exists. That slot is gone until the connection is closed. Leak nine of these on a pool of nine and the pool is empty. Every subsequent request waits for a connection that is never coming back, and your app hangs while the database sits at near-zero CPU — which is what makes this one so cruel to debug. The dashboards say the database is *fine*. The database is fine. Your code is holding all the phones off the hook.

The fix is not a bigger pool — a bigger pool just means you leak longer before you notice. The fix is guaranteeing the connection goes back even when the code between borrow and return throws. In Python that is a context manager or a `finally`:

```python
# The leak: if do_work() raises, conn is never returned. Slot lost.
conn = pool.getconn()
do_work(conn)
pool.putconn(conn)

# The fix: the connection goes back on success, on exception, on early return.
conn = pool.getconn()
try:
    do_work(conn)
finally:
    pool.putconn(conn)

# Better: let the context manager do it, so you can't forget.
with pool.connection() as conn:
    do_work(conn)
```

Same shape in every language — `try/finally`, `defer conn.Close()` in Go, a using-block, an ORM session scope. The rule is: the return path must be un-skippable. As a backstop for the leaks you'll still ship, set a server-side eject seat — `idle_in_transaction_session_timeout = '30s'` — so Postgres kills a connection that's been idle mid-transaction too long instead of letting it hold the slot forever. That's a seatbelt, not a fix; the fix is the `finally`.

**Ranked #2** because a leak defeats any pool size, and it's the failure you're most likely to actually cause yourself — but it's ranked below sizing because you can't reason about "the pool is leaking" until the pool is bounded enough to notice.

### 3. Put PgBouncer in transaction mode when you genuinely have thousands of clients

Sometimes you really do have 1,000 application workers and a database that can bear 100 connections, and no amount of per-instance sizing squares that circle. That's what a connection pooler is for. PgBouncer sits in front of Postgres and lets many clients share a small set of *real* backend connections, handing a backend to whichever client is mid-transaction and taking it back the instant the transaction ends. The magic word is `pool_mode = transaction`.

I ran it for real: PgBouncer 1.25.2 in front of the same Postgres, `default_pool_size = 20`, `max_client_conn = 1000`. Then I fired 40 concurrent clients at it and asked PgBouncer what it was doing:

```console
$ psql -p 6432 -U postgres -d pgbouncer -c "SHOW POOLS;"
 database  |   user    | cl_active | cl_waiting | sv_active | sv_idle |  pool_mode
-----------+-----------+-----------+------------+-----------+---------+-------------
 postgres  | postgres  |        20 |         20 |        20 |       0 | transaction
```

Read that row. `cl_active 20` clients are being served, `cl_waiting 20` are politely queued, and `sv_active` — the number of *real* connections open against Postgres — is `20`, exactly `default_pool_size`. Forty clients, twenty backends, and Postgres never sees more than twenty no matter how the client count grows. Confirmed from the database's own side during the burst:

```console
$ psql -tAc "select count(*) from pg_stat_activity
    where backend_type='client backend';"
21
```

Twenty backends plus the one connection I was using to count. PgBouncer absorbed the fan-out. This is how you let a thundering herd of app workers exist without translating it into a thundering herd of Postgres processes.

The catch, because transaction mode always has one: session-level state does not survive between transactions, because your next query might land on a different backend. Session-`SET`s, `LISTEN/NOTIFY`, `WITH HOLD` cursors, prepared statements that expect to persist — these break in ways that are maddening to diagnose. Transaction mode is a contract: you may not assume the connection you have now is the connection you had a moment ago. Most web apps already honor that contract without knowing it. Audit before you flip the switch.

**Ranked #3** because it's the heavyweight you reach for only when sizing and leak-plugging genuinely aren't enough — the thousands-of-clients case. Reach for it last, not first; a pooler in front of a still-leaking app just gives your leak a bigger room to hide in.

## The one-paragraph version

Nobody is flooding your database. You are, with a pool sized by hope. A Postgres connection is a whole OS process, your machine has a fixed number of cores, and Postgres refuses new connections past `max_connections` with `FATAL: sorry, too many clients already` — so a giant pool is a self-inflicted DoS, not a throughput dial. In order of what actually keeps you up: size the pool to `(cores * 2) + 1` so overflow queues in your app instead of stampeding the database; return every connection in a `finally`/context manager so you don't leak `idle in transaction` slots until the pool is empty and the database looks innocent; and when you truly have thousands of clients, put PgBouncer in `transaction` mode so they share a bounded set of real backends. I threat-modeled your connection pool so you don't have to. It's still too big. Go turn it down.
