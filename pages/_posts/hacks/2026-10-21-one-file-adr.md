---
title: "Write the decision down or relitigate it forever: the one-file ADR"
description: "A numbered markdown file per decision ends the six-monthly 'why Postgres?' rerun. Plus the overwrite, the numbering race, and ADR 10,000 that broke it."
date: 2026-10-21
preview: /images/previews/write-the-decision-down-or-relitigate-it-forever-t.svg
categories: [Hacks]
tags: [git, shell]
author: edge
excerpt: "I wrote 10,000 Architecture Decision Records to see what breaks. Two branches minted the same number, and ADR 10,000 kept getting written twice."
permalink: /hacks/one-file-adr/
---
Every team has a meeting that comes back like a seasonal allergy. "Why did we pick Postgres?" Somebody who wasn't there asks. Somebody who was there remembers it differently. Forty minutes later the team has re-decided the same thing and kept no record of it, so it can all happen again in April.

The fix is old, boring, and one file long: the **Architecture Decision Record**. Each decision gets one numbered markdown file in the repo with four headings. You commit it, and then `grep` and `git log` remember the decision so you don't have to. The idea came from the [Technical Leadership quest on it-journey.dev](https://it-journey.dev/quests/1111/technical-leadership/), which is right that writing a decision down is leadership work. My job is to find out how the file breaks. It broke three ways. One of them only shows up at ADR number 10,000, and yes, I wrote 10,000 of them.

Tested on bash 5.2.21, git 2.55.0, and GNU grep 3.11, in a throwaway repo. Every console block below is output I captured.

## The file

One decision per file, under `docs/adr/`. The name is a zero-padded number and a slug. There are four headings, and you get to skip the template-generator SaaS.

```markdown
# 1. Use Postgres for the orders database

Date: 2026-10-21

## Status

Accepted

## Context

We need a relational store for orders. The team knows SQL. Nobody wants to run a second database.

## Decision

We will use PostgreSQL 16 for the orders service.

## Consequences

Ops has to own backups and upgrades. We give up schemaless writes. MongoDB comes up again in six months; point at this file.
```

That's `docs/adr/0001-use-postgres.md`. Commit it with a message that says what it is (`docs(adr): 0001 use postgres`), and the history is now searchable:

```console
$ grep -rn -A2 "^## Status" docs/adr
docs/adr/0001-use-postgres.md:5:## Status
docs/adr/0001-use-postgres.md-6-
docs/adr/0001-use-postgres.md-7-Accepted
```

**You'll know it worked when** a new teammate types `grep -ril postgres docs/adr`, reads Context, and doesn't ping you. Each heading prevents a specific failure:

- **Context** is there for the person who later says "that was dumb." It records the constraints you had at the time, so they're arguing with your situation and not your intelligence.
- **Decision** is one sentence in the active voice: "We will…". If you can't write that sentence, you haven't decided anything yet, and the meeting isn't over.
- **Status** is the field that makes the next section possible.
- **Consequences** records what you gave up. Without it, the ADR is a press release.

## Failure 1: editing the old ADR to "update" it

Six months later the team really does move orders to MongoDB. The tidy-minded thing is to open `0001` and fix it. I did that, so you can see what it costs:

```console
$ grep -ril postgresql docs/adr
(exit 1)
$ grep -A2 "^## Decision" docs/adr/0001-use-postgres.md
## Decision

We will use MongoDB 8 for the orders service.
$ grep -A2 "^## Context" docs/adr/0001-use-postgres.md
## Context

We need a relational store for orders. The team knows SQL. Nobody wants to run a second database.
```

That's three bugs from one edit:

1. The decision you made is gone from the working tree. `grep` swears Postgres was never mentioned.
2. The file is still called `0001-use-postgres.md`, so the filename now contradicts its own contents.
3. The Context still argues *for SQL and against a second database*, and right under it the Decision picks a second, non-SQL database. The reasoning is orphaned, and that's worse than having no reasoning, because it reads as if somebody lost their mind.

Yes, git still has it:

```console
$ git log --format=%s -S "PostgreSQL 16" -- docs/adr
docs(adr): update 0001 to mongodb
docs(adr): 0001 use postgres
```

But nobody in a meeting runs pickaxe searches. The ADR exists so the answer is in the file. **The failure this prevents:** a new hire reads the "current" ADR, sees reasoning that contradicts the decision, and correctly decides the docs can't be trusted. They stop reading all of them.

## The fix: append-only, supersede with a new file

An ADR is append-only. When a decision reverses, you write a **new** file. The only change to the old one is its Status line:

```console
$ git show --stat --oneline HEAD
ae43b0d docs(adr): 0002 supersedes 0001
 docs/adr/0001-use-postgres.md           |  2 +-
 docs/adr/0002-move-orders-to-mongodb.md | 19 +++++++++++++++++++
 2 files changed, 20 insertions(+), 1 deletion(-)
```

`0001`'s Status goes from `Accepted` to `Superseded by [0002](0002-move-orders-to-mongodb.md)`. `0002` gets its own Context ("line items became free-form vendor JSON"), and its Status reads `Accepted. Supersedes [0001](0001-use-postgres.md).` Its Consequences also say out loud that "we now run two databases, which 0001 said we didn't want." Now the trail reads in both directions:

```console
$ grep -rn -A2 "^## Status" docs/adr
docs/adr/0002-move-orders-to-mongodb.md:5:## Status
docs/adr/0002-move-orders-to-mongodb.md-6-
docs/adr/0002-move-orders-to-mongodb.md-7-Accepted. Supersedes [0001](0001-use-postgres.md).
--
docs/adr/0001-use-postgres.md:5:## Status
docs/adr/0001-use-postgres.md-6-
docs/adr/0001-use-postgres.md-7-Superseded by [0002](0002-move-orders-to-mongodb.md)
$ grep -ril postgresql docs/adr
docs/adr/0001-use-postgres.md
```

Postgres is findable again, and so is the reason you left it. **You'll know it worked when** `grep` for the old technology lands on a file whose Status points you to the new one. (Small nitpick: `grep -r` prints in directory order, not number order. Add `| sort` if you want a timeline.)

## Failure 2: two branches mint the same number

Here's the obvious way to pick the next number: list the directory, take the last entry, add one. I wrote that helper and had two people use it on two branches at the same time, which is how real teams work:

```bash
next() { local last; last=$(ls docs/adr | sort | tail -1); printf '%04d' $(( 10#${last%%-*} + 1 )); }
```

Alice branched and wrote `0003-use-redis-for-sessions.md`. Bob branched from the same `main` and wrote `0003-use-kafka-for-events.md`. Then both merged:

```console
$ git merge alice
exit=0
$ git merge bob
exit=0
$ ls docs/adr
0001-use-postgres.md
0002-move-orders-to-mongodb.md
0003-use-kafka-for-events.md
0003-use-redis-for-sessions.md
```

Both merges exited 0. There was no conflict because the filenames differ, so as far as git is concerned nothing collided. **The failure this prevents:** six months later, "see ADR 3" in a PR comment points to two different decisions, and the person who quoted it can't remember which one they meant.

## Failure 3: ADR number 10,000 (the absurd one that found a real bug)

This is the test nobody sane would run. I generated `0001` through `9999` and asked the same helper for the next number, three times in a row:

```console
files: 9999
next: 10000
next: 10000
next: 10000
$ ls docs/adr | sort | tail -3
9997-decision-9997.md
9998-decision-9998.md
9999-decision-9999.md
$ ls docs/adr | sort -V | tail -3
9999-decision-9999.md
10000-decision-10000.md
10000-decision-again.md
$ ls docs/adr | grep -c "^10000-"
2
```

`sort` compares text, and the character `1` sorts before `9`, so `10000-…` lands *above* `9999-…`. The helper keeps seeing 9999 as the newest ADR and hands out 10000 forever. I got two ADR 10000s before I stopped it. Yes, your team won't write ten thousand decisions. The same lexical-sort bug hits anyone who skipped the zero padding: `9-…` sorts after `10-…`, and that happens at ADR **10**.

## The fix: a numeric next-number and a CI check

This helper finds the highest number numerically, not by text order:

```bash
#!/usr/bin/env bash
# adr-next: print the next free ADR number. Numeric max, not lexical.
dir=${1:-docs/adr}
max=$(ls "$dir" | grep -E '^[0-9]+-' | cut -d- -f1 | sort -n | tail -1)
printf '%04d\n' $(( 10#${max:-0} + 1 ))
```

The numbering race can't be prevented when two people branch at the same time, so you catch it at merge time. This check fails on duplicate numbers and on any link to an ADR file that doesn't exist:

```bash
#!/usr/bin/env bash
# adr-check: fail on duplicate ADR numbers and on links to ADRs that don't exist.
dir=${1:-docs/adr}; rc=0
dups=$(ls "$dir" | grep -E '^[0-9]+-' | cut -d- -f1 | awk '{print $1+0}' | sort -n | uniq -d)
for n in $dups; do
  echo "duplicate ADR number $n:"; ls "$dir" | grep -E "^0*$n-" | sed 's/^/  /'; rc=1
done
for f in "$dir"/*.md; do
  [ -e "$f" ] || continue                       # empty dir: nothing to check
  grep -oE '\]\([^)#]+\.md\)' "$f" | sed -E 's/^\]\(//; s/\)$//' |
  while IFS= read -r link; do
    [ -e "$dir/$link" ] || { echo "$f: dead link to $link"; exit 1; }
  done || rc=1
done
exit $rc
```

My first version looped over links with `for link in $(…)`, and it failed both of my unfair tests. It printed a `No such file or directory` grep error on an empty directory. Pointed at a *valid* link to a file really named `0003 use redis.md`, it word-split the link and reported three dead ones: `0003`, `use`, and `redis.md`. The `while read` version above passes that link (exit 0). The results table, run against each scenario:

| Scenario | `adr-next` | `adr-check` |
|---|---|---|
| Empty `docs/adr/` | `0001` | exit 0 ✅ |
| Alice + Bob both merged `0003` | `0004` | exit 1, lists both `0003` files ✅ |
| Someone "tidied" `0002`'s filename | — | exit 1, `0001-use-postgres.md: dead link to 0002-move-orders-to-mongodb.md` ✅ |
| A link with a space: `](0003 use redis.md)` | — | exit 1, reports the whole path as one link ✅ |
| `0001`–`10000` on disk | `10001` | exit 0 ✅, in **17.2 s** |

The rename row is a free bonus. Renaming an ADR to "tidy" its slug silently breaks every `Superseded by` link that points at it, which is one more reason to treat these files as append-only. The 17 seconds at 10,000 files is two process spawns per file. That's slow, but your team won't hit it before the heat death of its Jira.

Put `adr-check` in CI next to your other lints. When two people mint the same number, whoever merges second renumbers. It's a one-line rename, and it's legal because the ADR isn't on `main` yet.

## When this goes wrong

- **The ADR nobody reads.** If the decision never gets linked from the PR that carried it out, the file is a diary entry. Put `ADR-0002` in the PR description so `git log --grep` connects them.
- **Writing an ADR for everything.** If reversing it costs less than writing it, skip it. ADRs are for decisions you'll be asked to defend: the database, the auth model, the "we don't use microservices" one.
- **"Proposed" forever.** A Status that never moves past Proposed is a decision nobody made. Either accept it or mark it Rejected and keep the file. Rejected ADRs stop the same proposal from coming back next quarter.

## Does it survive a Tuesday?

**Verdict: the file survives the Tuesday where the intern has sudo. The naive tooling around it doesn't make it past a bad Tuesday.** A numbered markdown file with four headings is about as low-tech as engineering process gets, and grudgingly, I couldn't break the idea. What broke was everything people do *around* it: editing an old ADR in place, which made `grep` deny the decision ever happened; two branches minting `0003` with exit code 0; and a text-order `sort` that kept handing out ADR 10000. Keep the files append-only, find the next number with `sort -n`, and let `adr-check` fail the build.
