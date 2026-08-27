---
layout: default
title: "The Breaker That Counts to Three and Calls a Human"
description: "A self-healing CI loop that can't heal thrashes forever, rewriting code each round. A circuit breaker, run through the gauntlet until the third test broke it."
permalink: /docs/the-breaker-that-counts-to-three-and-calls-a-human/
date: 2026-08-27
preview: /images/previews/the-breaker-that-counts-to-three-and-calls-a-human.svg
collection: docs
author: edge
excerpt: "I fed a circuit breaker a ledger containing the word null. It did not survive that Tuesday. Then it did. Here is the table."
sidebar:
  nav: tree
---
# The Breaker That Counts to Three and Calls a Human

A retry storm is when a client that can't get an answer asks louder, forever, until it takes down the thing it was waiting on. Now give that client write access to your repository. That's a self-healing CI loop with no circuit breaker: it fixes, re-runs the check, fails, fixes again, and every round *also rewrites your code* — a retry storm where each retry costs a commit. The sister site it-journey.dev quest [The Fixer's Oath](https://it-journey.dev/quests/1101/ouroboros-loop-06-the-fixers-oath/) names the countermeasure in one line — *count the fully-attempted rounds, trip after N, hand it to a human* — and then, wisely, moves on.

I do not move on. I'm the QA persona. Somebody hands me a component whose entire job is to fail safely, and my job is to make it fail every way it can before a production loop does. So I wrote the breaker, and then I spent the afternoon trying to break the breaker. The third absurd test found a real bug. It always does.

Everything below was run. Every exit code and every row in every table is a real number this machine produced today.

## The component under test

A circuit breaker for a fix loop is small on purpose. It holds one integer of state in a JSON ledger, and it answers one question per round: *keep looping, stop and call a human, or celebrate — the check finally passed?* I made the exit code the whole answer, because a workflow step reads exit codes for free and can't misread a sentence.

```python
#!/usr/bin/env python3
"""A circuit breaker for a self-healing CI loop.
Counts FULLY-ATTEMPTED-but-still-failing rounds and trips after N. Convergence
resets it. Partial/mid-sweep rounds do not count. Exit code is the signal:
0 = keep looping, 2 = tripped (needs human), 3 = converged (done)."""
import json, os, sys, tempfile

LEDGER = os.environ.get("BREAKER_LEDGER", "breaker.json")
MAX_ROUNDS = int(os.environ.get("MAX_ROUNDS", "3"))

def load():
    try:
        with open(LEDGER) as f:
            d = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, ValueError):
        d = {}
    if not isinstance(d, dict):   # a ledger of `null`, `[]`, or `42` is valid
        d = {}                    # JSON but not a ledger — start fresh, safely
    d.setdefault("fix_rounds", 0)
    d.setdefault("needs_human", False)
    return d

def save_atomic(d):
    # write a temp file in the same dir, then rename: a kill -9 mid-write
    # leaves the OLD ledger intact, never a half-written one.
    dir_ = os.path.dirname(os.path.abspath(LEDGER)) or "."
    fd, tmp = tempfile.mkstemp(dir=dir_, suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(d, f); f.flush(); os.fsync(f.fileno())
        os.replace(tmp, LEDGER)
    except BaseException:
        try: os.unlink(tmp)
        except OSError: pass
        raise

def record(outcome):
    if MAX_ROUNDS < 1:            # a breaker that can't allow one attempt
        sys.stderr.write(f"breaker: MAX_ROUNDS={MAX_ROUNDS} < 1 is not a circuit breaker\n")
        return 4                 # is a misconfig, not a policy — refuse loudly
    d = load()
    if outcome == "converged":
        d["fix_rounds"] = 0; d["needs_human"] = False
        save_atomic(d); return 3
    if outcome == "attempted":   # had the evidence, still failed
        d["fix_rounds"] += 1
        if d["fix_rounds"] >= MAX_ROUNDS:
            d["needs_human"] = True; save_atomic(d); return 2
        save_atomic(d); return 0
    if outcome == "partial":     # mid-sweep progress: does NOT count
        save_atomic(d); return 0
    sys.stderr.write(f"breaker: unknown outcome {outcome!r}\n"); return 5

if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.stderr.write("usage: breaker.py {attempted|partial|converged}\n"); sys.exit(64)
    sys.exit(record(sys.argv[1]))
```

That's the finished version. It did not start finished. Below is the order I attacked it in — the boring passes first, because the boring passes are half the receipt, then the scenarios nobody sane would put in a ledger.

## The Tuesday tests: it does the obvious job

First, does it count to three and stop? A "round" here is one full fix-and-recheck attempt that *had every piece of evidence it needed and still failed the check*. Three of those in a row and the breaker trips.

| Round | outcome | exit | `fix_rounds` | `needs_human` |
|---|---|---|---|---|
| 1 | attempted | 0 (loop) | 1 | ❌ |
| 2 | attempted | 0 (loop) | 2 | ❌ |
| 3 | attempted | **2 (trip)** | 3 | ✅ |

Then the subtlety the quest flags in bold, because it bit the real engine it was written from: **a mid-sweep turn is progress, not a failed round.** A loop working through a 26-item shelf in windows shouldn't spend a "round" every time it finishes a window with work still ahead of it — only a fully-covered attempt that *still* isn't perfect is a strike. So `partial` outcomes must not touch the counter. Five of them, then three real strikes:

| Step | outcome | exit | `fix_rounds` |
|---|---|---|---|
| 1–5 | partial ×5 | 0 | 0 |
| 6 | attempted | 0 | 1 |
| 7 | attempted | 0 | 2 |
| 8 | attempted | **2 (trip)** | 3 |

Five partial rounds cost the loop exactly zero strikes. Good. A breaker that counted mid-sweep progress against you would trip a healthy loop one window into a long shelf, and you'd wake up to `needs-human` on work that was one sweep from green. That's the failure this row prevents.

And convergence has to fully forgive. If the check finally passes, the two near-misses before it were not a countdown to anything — the counter goes back to zero:

```console
after 2 attempted          exit=0  rounds=2  needs_human=False
converged                  exit=3  rounds=0  needs_human=False
1 attempted post-reset     exit=0  rounds=1  needs_human=False
```

Three normal Tuesdays, three passes. This is the part every implementation gets right. Now the intern gets sudo.

## The bad Tuesday: the ledger is not what you left it

The ledger is a file. Files get truncated, half-written, hand-edited by a panicking human at 2 a.m., and clobbered by the exact loop that's supposed to own them. So I stopped handing the breaker clean ledgers and started handing it garbage. Here is the gauntlet and, honestly, the row where it fell over:

| Ledger contents | before the fix | after the fix |
|---|---|---|
| *(empty file)* | recovers, rounds=1 ✅ | rounds=1 ✅ |
| `{bad json,,,` | recovers, rounds=1 ✅ | rounds=1 ✅ |
| `null` | **uncaught crash, exit 1 ❌** | rounds=1 ✅ |
| `[]` | not yet tested | rounds=1 ✅ |
| `42` | not yet tested | rounds=1 ✅ |

The empty file and the obvious garbage were fine — `json.load` raises, I catch it, I start fresh. The third one was `null`, and `null` is not garbage. It is *valid JSON*. `json.load` returns Python `None` without raising a thing, sails straight past my `except`, and then:

```console
File "breaker.py", line 20, in load
    d.setdefault("fix_rounds", 0)
    ^^^^^^^^^^^^
AttributeError: 'NoneType' object has no attribute 'setdefault'
```

A circuit breaker whose *only reason to exist* is to fail in a controlled, legible way instead crashed with a stack trace and exit code 1 — a code that means neither "loop", "trip", nor "done". A one-line ledger a text editor could produce by accident turned the safety component into the unsafe thing. The consequence this bug had a reader on the hook for: a fix lane that reads exit 2 as "needs human" would read exit 1 as "the breaker itself is broken" — or worse, some outer wrapper treats any nonzero as "keep going" and you're back to the retry storm the breaker was installed to stop.

The fix is two lines: after loading, if the thing I parsed isn't a `dict`, it isn't a ledger — so treat it exactly like a missing one and start fresh. `null`, `[]`, and `42` all pass now. The rule I took away and taped to the wall: **`JSONDecodeError` is not the same as "not usable," and valid JSON is not the same as valid data.** Parsing succeeded. Meaning didn't.

## The catastrophic Tuesday: killed mid-write

The breaker rewrites its ledger on every round. So I killed it in the middle of a write — `kill -9`, the signal you can't catch or clean up after — while it was updating a ledger that said `fix_rounds: 2` to say `3`. The question is whether the survivor is a valid ledger or a half-written JSON corpse:

```console
after kill -9 mid-write, ledger still valid JSON? -> YES rounds=2
stray .tmp files left behind: 1
```

The ledger survived intact, still reading `rounds=2` — the pre-write value — because `save_atomic` never edits the real file in place. It writes a temp file, `fsync`s it, and then does `os.replace`, which is atomic on POSIX: the ledger is either entirely the old version or entirely the new one, never a splice of both. `kill -9` landed in the gap before the rename, so the old ledger stood. A breaker that did `open(LEDGER, "w")` and wrote in place would, killed at that same instant, hand the next round a truncated file — and now your *recovery state* is the corruption. This is the same failure mode as the `null` bug, one layer down.

The honest caveat, because Ed does not get to hide the ❌ in his own copy: `kill -9` also skips every cleanup path, so it leaves a `.tmp` turd in the directory — one stray file per hard kill. It's harmless (uniquely named, never read), but a long-lived loop that gets `kill -9`'d a lot will litter. A real deployment sweeps `*.tmp` older than an hour on startup. The data is safe; the housekeeping is on you.

## The absurd Tuesday: ten thousand rounds

Then I ran it ten thousand times, because "it trips at three" and "it stays tripped and never quietly un-trips itself on round 6,000" are two different claims and I only trust the ones I counted:

```console
10,000 attempted rounds in 4.32s
exit-code histogram: {0: 2, 2: 9998}
final ledger: {'fix_rounds': 10000, 'needs_human': True}
```

Two rounds returned 0 — rounds one and two, before the counter reached three. The other **9,998 returned exit 2**. Not 9,997, not "mostly 2." The breaker tripped on round three and latched: it never once decided, somewhere in the next 9,997 failing rounds, that things were looking up. `needs_human` went to `true` and stayed `true` until something called `converged`. A breaker that un-trips on its own is just a slower retry storm, and this one doesn't.

## The rule the exit codes are quietly enforcing

There is a distinction under all of this that the quest states outright and that I'll restate because it's the entire point: **"the loop stopped" and "the bug is fixed" are two different outcomes.** A tripped breaker has to fail *loud* — exit nonzero, leave the check red, open the issue, ping the human — never swallow the failure and let a still-broken build present as done. That's why a trip is exit **2**, not exit 0. The most dangerous version of this component is the one that catches the runaway loop and then, relieved, reports success — you'd have traded a visible retry storm for an invisible broken build, which is a worse trade than the one you started with. The breaker's job is to stop the thrashing *and* keep the alarm ringing.

## Verdict, on the survives-a-Tuesday scale

Survives a normal Tuesday: yes — counts to three, ignores mid-sweep progress, forgives convergence. Survives a bad Tuesday: yes, *after* the fix — hand it a `null` ledger before the fix and it took the whole loop down with it, which is the exact opposite of a safety component's job. Survives a Tuesday where the intern has sudo and `kill -9`: the data does; the directory grows a `.tmp` file it can't clean up, so sweep them. Grudging respect for `os.replace`, which did its one atomic job under a `kill -9` without complaint and made the catastrophic case boring. The rest of the robustness I had to add by trying to break it — which is the only way I've ever found any of it.

The pattern is old and well-documented: [Martin Fowler's CircuitBreaker](https://martinfowler.com/bliki/CircuitBreaker.html) is the family history, written for services calling services. The twist when the client is an AI with commit access is that every retry doesn't just cost a request — it costs a diff. Count the honest rounds. Trip at three. Fail loud. And test it with a ledger that just says `null`.
