---
title: "Threat-model your rollback: the migration downgrade nobody tested until 2am"
description: "Every migration ships two functions and you only run one. Reproduce the untested-downgrade incident on a throwaway Postgres, then three ranked fixes."
date: 2026-07-22
categories: [Hacks]
tags: [data, security, ci-cd]
author: cass
excerpt: "Your upgrade() gets run a hundred times before prod. Your downgrade() gets run once — at 2am, on fire, in production, for the first time in its life."
preview: /images/previews/threat-model-your-rollback-the-migration-downgrade.svg
permalink: /hacks/test-your-downgrade-before-prod/
---
Somebody, right now, has a `downgrade()` function they have never run. It's most of you. I threat-model this instead of sleeping.

Here is the scenario I lie awake on. It is 2am. A deploy has gone wrong in a way that is not the migration's fault — a bad config, a poisoned cache, the moon — and the runbook says the same thing runbooks always say: *roll back*. So you type `alembic downgrade -1` with the shaky confidence of a person who has never once watched this command succeed, and one of two things happens. Either `downgrade()` raises — because it was written six weeks ago by someone who tab-completed it and moved on — and now you are half-migrated in production with a schema that matches neither the old code nor the new. Or it *works*, cleanly, and drops the column your emergency hotfix is standing on. The pager, which has three-letter agencies on speed dial, escalates. Somewhere, a budget is approved.

**SEVERITY:** career. **ATTACK VECTOR:** a function you wrote and never called.

Now let me walk that back to the boring true version, because the boring true version is the one that pages you. (The idea for this one was spotted on it-journey.dev's [Database Migrations](https://it-journey.dev/quests/0110/database-migrations/) quest; this is the paranoid director's cut.)

A migration is the one piece of code you deploy that comes with a second, shadow function — `downgrade()` — that exists purely to be run in an emergency, and therefore never gets run in practice. `upgrade()` is exercised on every developer laptop, in CI, in staging, a hundred times before prod. `downgrade()` is exercised zero times, ever, until the worst night of the quarter, at which point it runs in production, as root, for the first time in its life. It is unpaid, untested code with a key to the schema. Convenience with better marketing.

I built the incident on a throwaway Docker Postgres so you can watch it fail somewhere that doesn't matter.

## Setup: a real paired migration, against a disposable database

```console
$ docker run --rm -d --name lh_pg -e POSTGRES_PASSWORD=pw -p 5433:5432 postgres:16
$ alembic init migrations   # then point sqlalchemy.url at the throwaway box
```

Alembic (like Rails, like Django, like every migration tool worth using) makes you write the schema change as two functions: `upgrade()` for the way in, `downgrade()` for the way back. Here is the first one, by hand, so the intent is obvious:

```python
def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("email", sa.String(255), nullable=False),
    )

def downgrade() -> None:
    op.drop_table("users")
```

`upgrade` runs and the table exists. This part everyone tests, because it's the part you actually wanted:

```console
$ alembic upgrade head
INFO  [alembic.runtime.migration] Running upgrade  -> ad925f58cf0c, create users
$ psql ... -c "\d users"
 Column |          Type          | Nullable |              Default
--------+------------------------+----------+-----------------------------------
 id     | integer                | not null | nextval('users_id_seq'::regclass)
 email  | character varying(255) | not null |
```

The whole discipline this article is selling is the next line — the one you'd only ever type in an emergency. Run it *now*, on the disposable box, where a bug is a shrug instead of an incident:

```console
$ alembic downgrade base
INFO  [alembic.runtime.migration] Running downgrade ad925f58cf0c -> , create users
$ psql ... -c "\d users"
Did not find any relation named "users".
```

It worked. Great. Now you *know* it works, which is the entire point, because the alternative was finding out at 2am. But "the downgrade runs" is the easy failure to prevent. There are two harder ones hiding in here, and I reproduced both.

## Footgun 1: `downgrade()` that runs perfectly and still takes prod down

A rollback doesn't have to raise to ruin your night. It can succeed flawlessly and *still* be the outage — because the lock it takes is the weapon, not the SQL. Watch what a plain `DROP COLUMN` does to everyone else trying to use the table. I held the `ALTER` open in one transaction and pointed a normal application read at it from another:

```console
-- session A, mid-rollback:
BEGIN;
ALTER TABLE users DROP COLUMN email;   -- not committed yet

-- session B, meanwhile, asking pg_locks what A is holding:
$ psql -c "SELECT mode, granted FROM pg_locks ... WHERE relname='users';"
     mode         | granted
------------------+---------
 AccessExclusiveLock | t

-- session B, a boring SELECT the running app does a thousand times a second:
$ psql -c "SET lock_timeout='1s'; SELECT count(*) FROM users;"
ERROR:  canceling statement due to lock timeout
```

`AccessExclusiveLock` is the biggest lock Postgres has: it conflicts with *everything*, including a plain `SELECT`. For as long as your `ALTER TABLE ... DROP COLUMN` (or `RENAME`, or a lot of `ALTER TYPE`s) runs, the running application cannot read the table at all. On a table with real traffic, "rolls back cleanly" and "takes a hard outage" are the same event. The migration didn't fail. It succeeded, on top of you.

## Footgun 2: the checksum that isn't there

Here's the one that genuinely surprised me, and I don't surprise easy. The received wisdom — including the brief I was handed — is that you can't edit a migration you've already shipped *because the tool checksums it and refuses to run on a mismatch*. That's true of Flyway and Liquibase. It is **not** true of Alembic, and the truth is worse.

I took a migration that was already applied to the database and edited its body to also add a `country` column — the classic "I'll just fix the one that already went out" move — and re-ran the upgrade:

```console
$ # edited the already-applied migration to add: op.add_column("users", "country")
$ alembic upgrade head
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
$ psql ... -Atc "SELECT column_name FROM information_schema.columns WHERE table_name='users';"
id
phone
```

No error. No checksum complaint. No `country` column. Alembic records *which revision IDs have run*, not *what they contained* — so it looked at the database, saw this revision already applied, and did **nothing**. Your edit is real in the file and imaginary in the database. Every fresh clone that runs the migration from zero will get your `country` column; production, which already ran the old body, never will. Your schema now depends on whether a given database was built before or after you committed. That is not a checksum saving you. That is a silent divergence with your name on the blame.

And if you reach instead for the *other* obvious edit — renumbering or squashing a shipped revision so its ID changes — Alembic finally does speak up, loudly, because now the ID recorded in the database points at nothing:

```console
$ alembic upgrade head
ERROR [alembic.util.messaging] Can't locate revision identified by 'b3ee4b1c60dd'
FAILED: Can't locate revision identified by 'b3ee4b1c60dd'
$ echo $?
255
```

So a shipped migration gives you two ways to lose: edit the body and fail *silently*, or edit the ID and fail *loudly* at the worst possible moment. There is no third option where editing it is fine. Assume every migration you've deployed is frozen, because the tool won't enforce it for you and I don't trust tools that make honesty optional.

## The three mitigations, ranked

The threat is a rollback that's never been run meeting production for the first time. Everything reorders around that.

### 1. Run the downgrade before prod does — in CI, every time

The single highest-value thing you can do is make the untested function tested, automatically, on a database nobody cares about. The round-trip is three commands: migrate up, roll straight back one step, migrate up again.

```console
$ alembic upgrade head && alembic downgrade -1 && alembic upgrade head
INFO  [alembic.runtime.migration] Running downgrade b3ee4b1c60dd -> ad925f58cf0c, add phone
INFO  [alembic.runtime.migration] Running upgrade ad925f58cf0c -> b3ee4b1c60dd, add phone
$ echo $?
0
```

A `downgrade()` that raises fails this at 2pm in CI, in front of the person who wrote it, instead of at 2am in prod in front of the person who didn't. Wire it into the pipeline against a throwaway Postgres — the same disposable container I used above — so no migration merges without its rollback having been executed at least once. Ranked #1 because it converts the entire class of "we never ran it" into "the build was red."

### 2. Never take a blocking lock on a live table: expand, then contract

Footgun 1 was a `DROP COLUMN` freezing every reader. The fix is to never do a destructive schema change and a code deploy in the same breath. Split it across releases — the expand/contract dance:

- **Expand:** add the new thing, always nullable, no default that forces a rewrite. Adding a nullable column is a metadata-only change in modern Postgres — it grabs `AccessExclusiveLock` for microseconds, not for a table scan.
- **Backfill** in batches, out of band, never in the migration transaction.
- **Deploy** code that reads and writes both the old and new shape.
- **Contract** a full release *later*, once nothing references the old column, and only then drop it.

The destructive step — the one that takes the scary lock — happens when the column is already dead weight nobody reads, so the lock is on a table no live query is touching. Ranked #2 because it's the difference between a rollback that's clean and a rollback that's clean *and* invisible to your users.

### 3. Treat every shipped migration as immutable — write a new one

Footgun 2 proved the tool won't stop you editing history: you get silent drift or a broken chain, never a helpful checksum. So enforce the rule yourself, socially, because nothing else will: **a migration that has left your machine is frozen.** Wrong column type? New migration. Typo in a constraint? New migration. The forward-only append is the only edit that behaves the same on a fresh clone and on three-years-of-production. This one's ranked last only because it costs nothing but discipline — and it's the one a code reviewer can actually catch, because "you modified an existing migration file" is a one-line `git diff` a human, or a CI check, can flag on sight. Necessary, cheap, and entirely on you.

## The one-paragraph version

Every migration ships two functions and you only ever run one of them, so the rollback is untested code with root on your schema. Reproduce the incident on a throwaway Postgres tonight, then, in order: run `upgrade → downgrade → upgrade` in CI on every migration so the shadow function gets tested before prod tests it; split destructive changes into expand-then-contract so a rollback never takes an `AccessExclusiveLock` on a live table; and treat any migration you've shipped as frozen, because Alembic won't checksum you into honesty — it'll just diverge quietly and hand you the blame. Your `downgrade()` will run in production exactly once. Decide now whether that's the first time or the second.
