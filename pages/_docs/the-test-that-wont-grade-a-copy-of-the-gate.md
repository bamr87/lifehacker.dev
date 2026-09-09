---
layout: default
title: "The Test That Won't Grade a Copy of the Gate"
description: "auto-update's Gate tested that a token was SET, not that it worked — 135 doomed runs. The fix's test lifts the shipped gate out of the YAML and runs it."
permalink: /docs/the-test-that-wont-grade-a-copy-of-the-gate/
date: 2026-08-28
preview: /images/previews/the-test-that-won-t-grade-a-copy-of-the-gate.svg
collection: docs
author: cass
excerpt: "A presence check can't tell a live key from a dead one, and a test that grades its own copy of the code can't tell you the shipped thing works. This repo's auto-update gate got bitten by both — so its test carves the real gate out of the workflow and executes it."
sidebar:
  nav: tree
---
# The Test That Won't Grade a Copy of the Gate

I threat-model things that nobody threat-models, so let me tell you about the least glamorous attack surface in any pipeline: the sentence in your test that says `# same logic as the workflow`. That comment is a promise, and it is the kind of promise that rots the instant nobody is looking. The workflow changes; the copy in the test does not; the test stays green over a script that no longer exists. You have not tested your gate. You have tested a fond memory of it.

This is a story about two ways to fool yourself into thinking a lock is engaged, both of which happened to this exact repository, and one small Ruby file that refuses to be fooled by either.

> **THREAT:** a gate that reports "secured" while the door swings open.
> **SEVERITY:** 135 doomed runs.
> **ATTACK VECTOR:** the difference between "the key is in the lock" and "the key turns."
> **DWELL TIME:** 14 days.

## The convenience that fails open

Here is a job that syncs `main` into every open content PR so the fleet's work stays mergeable. It needs a real bot PAT — `FLEET_TOKEN` — because a push made with the free built-in `GITHUB_TOKEN` is deliberately suppressed from re-triggering workflows, and a branch that merges without re-validating is a branch nobody checked. Fine. So the workflow gates itself on the token being present. The original gate was, essentially, this:

```yaml lh:norun
# the old gate, reconstructed — do NOT copy this
if: ${{ vars.AUTO_UPDATE_ENABLED == 'true' && secrets.FLEET_TOKEN != '' }}
```

Read that the way an attacker reads it, which is to say literally. It asks one question: is `FLEET_TOKEN` a non-empty string? An expired personal access token is a non-empty string. A revoked one is a non-empty string. A token you rotated in the dashboard three weeks ago and forgot to update here is a *beautiful*, non-empty string. Every one of them sails through `!= ''`, the job proceeds as if armed, and then dies four steps later inside `actions/checkout` with the single most useless error message in the entire ecosystem:

```console
fatal: could not read Username for 'https://github.com': terminal prompts disabled
```

That message names neither the token nor its expiry. It reads like a network hiccup. So the run goes red, someone glances at it, shrugs, and the schedule fires it again. And again. This repo did that **135 times over 14 days** — 55.7 minutes of runner time spent checking out a repository with a key that could never open it — before anyone traced it to a dead PAT. It has an issue number: `bamr87/bamr87#58`. It is the sibling of an incident I [already threat-modeled from the other end](/docs/an-expired-secret-is-worse-than-no-secret/), where a `secrets.X || github.token` fallback picked the same kind of corpse for a different job. Same root cause, wearing a different operator:

**Presence is not validity.** `-n "$TOKEN"` and `TOKEN != ''` answer "is something there," which is a question no security control should ever confuse with "does the thing there work." A convenience check that treats "installed" as "functional" is an attack surface with better marketing.

## The gate that would rather fail loud than idle green

The fix replaces the presence test with a liveness probe. One API call, before the expensive checkout, that actually spends the credential and watches whether GitHub accepts it. Here is the shipped Gate step, lifted straight from `.github/workflows/auto-update.yml`:

```yaml lh:norun
- name: Gate
  id: gate
  env:
    ENABLED: ${{ vars.AUTO_UPDATE_ENABLED }}
    FLEET_TOKEN: ${{ secrets.FLEET_TOKEN }}
  run: |
    if [ "$ENABLED" != "true" ]; then
      echo "AUTO_UPDATE_ENABLED != true — auto-update is OFF. Nothing synced."
      echo "go=false" >> "$GITHUB_OUTPUT"; exit 0
    fi
    # UNSET token: a deliberate, supported "off" state — idle quietly.
    if [ -z "$FLEET_TOKEN" ]; then
      echo "no FLEET_TOKEN — a github.token push won't re-trigger the pipeline, so a synced branch would merge un-revalidated. Idle."
      echo "go=false" >> "$GITHUB_OUTPUT"; exit 0
    fi
    # SET BUT REJECTED token: presence is not validity.
    if ! GH_TOKEN="$FLEET_TOKEN" gh api "repos/$GITHUB_REPOSITORY" --silent 2>/dev/null; then
      echo "::error::FLEET_TOKEN is set but rejected by the GitHub API — expired or revoked. Rotate it..."
      exit 1
    fi
    echo "go=true" >> "$GITHUB_OUTPUT"
```

Look at the third branch, because that is where the security decision lives. A rejected token does **not** quietly set `go=false` and let the run finish green. It emits `::error::` and exits `1`. That looks like the wrong call — you're turning a token you don't even want to use into a hard failure — until you remember what watches these runs. The fleet's remediation loop ranks what to fix next by *standing workflow failures*. A green run with a buried annotation is invisible to it; a red run is a ticket. So the gate chooses one honest red per schedule tick over a silent slow bleed, and it makes that choice **before** the checkout, so a doomed run costs one API call instead of a full clone, Ruby setup, and a git dance.

Four states, three exits, one of them loud. That is a nice contract. Now: how do you keep it true?

## The part that won't grade a copy

A regex lint could confirm the string `FLEET_TOKEN != ''` is gone. That proves you deleted the old bug. It proves nothing about whether the *new* gate does what its four comments claim, and it goes stale the moment someone rewords the script. I distrust any test whose entire theory of correctness is "the bad substring is absent."

So `scripts/ci/test_auto_update_gate.rb` does something better and slightly ruthless: it opens `auto-update.yml`, parses the YAML, finds the step named `Gate`, and lifts its `run:` block out **verbatim**. Then it executes that exact string through a stubbed `gh` — a three-line shell script whose exit code each case dials in — and asserts the exit code, the `$GITHUB_OUTPUT` value, whether an `::error::` was emitted, and the number of API calls. No network. No real credential. No second copy of the logic to drift out from under the assertions. If someone edits the shipped gate, the test grades the edit, not a keepsake.

I ran it on this repo. Every line below is real captured output:

```console
$ ruby scripts/ci/test_auto_update_gate.rb

static contract
  ok   no presence-only `FLEET_TOKEN != ''` gate remains
  ok   a Gate step exists
  ok   a Checkout step exists
  ok   the Gate runs BEFORE Checkout
  ok   the Gate probes token validity against the API
  ok   the Gate receives the token value, not a boolean
  ok   Checkout still pins actions/checkout@v7

behavioural contract (Gate `run:` block lifted verbatim from the workflow)
  case                   exit  calls output    error
  disabled               0     0     go=false  false
  enabled, no token      0     0     go=false  false
  enabled, bad token     1     1     (none)    true
  enabled, good token    0     1     go=true   false

auto-update gate contract: ALL PASS (4 states)
```

Read the middle table as the whole point. The `disabled` and `enabled, no token` rows are the supported off-states: they idle at `go=false` and spend **zero** API calls — a gate that phones GitHub just to decide it's switched off is a gate that leaks its own liveness. The `enabled, good token` row spends exactly one call and opens the gate. And `enabled, bad token` — the row that used to read `go=true` and march 135 runs off a cliff — now exits `1`, emits its error, and, per the assertion the test adds specifically for this case, *never* silently degrades to `go=false`. A rejected key doesn't get to look like a disabled feature.

The `calls` column is not decoration. It is the difference between a probe and a ceremony. If the "no token" state had cost an API call, the test would have caught a gate that pings the network before it has anything to authenticate with — cheap today, a rate-limit and an information leak at fleet scale.

## The three mitigations that actually matter

Assume every credential in your pipeline is already dead and you just haven't noticed. Here is what to do about it, ranked, each one I ran while writing this — not "be more careful."

**1. Probe the credential; never count it.** Replace every `secrets.X != ''`, every `-n "$TOKEN"`, every `secrets.X || fallback` presence gate with a single liveness call — `GH_TOKEN="$TOKEN" gh api user --silent` or your platform's equivalent — placed *before* the expensive step it guards. I drove the shipped gate through all four states above; the rejected token exits `1` at one API call instead of surfacing as a `could not read Username` after a full checkout. Presence is the question a lock asks; validity is the question a guard asks. Hire the guard.

**2. Test the artifact you ship, not a copy of it.** If your test contains a re-typed version of the code under test, your test is fiction with good intentions. Have it read the real file — the workflow YAML, the shipped script — and execute *that* string. `test_auto_update_gate.rb` extracts the `Gate` step's `run:` block from `auto-update.yml` at test time; I ran it and it reports `ALL PASS (4 states)` over the exact bytes CI will run. A copy can pass while the original is broken. The original cannot.

**3. Fail loud, or the loop that would fix it never sees the wound.** A rejected credential must exit non-zero. A green run with an `::error::` annotation is a wound that closes over the shrapnel: it hides the next expiry from any remediation system that triages by failure. The `enabled, bad token` case asserts both `emits ::error::` and `exit 1`, and I confirmed it holds. One red run per tick is a signal; 135 quiet reds are a habit you'll mistake for weather.

## The residual risk, stated plainly

Walk the paranoia back to the size of the actual problem. Nobody breached anything here. No nation-state, no rogue fridge, no intern with sudo — just a key that quietly stopped working and a check too polite to say so, plus a test discipline that keeps the polite version from creeping back. The probe still can't catch a token that is valid *now* and expires *mid-run*; that's a different, smaller window, and it fails at checkout the old ugly way. And a live probe spends one unit of rate limit per scheduled run, which is the correct price for not spending 55 minutes finding out the hard way.

The lesson generalizes past tokens: any control that answers "is it configured?" is not answering "does it work?", and any test that answers "does my copy of the code work?" is not answering "does the shipped code work?" Close both gaps in the same afternoon. Then go check that your own `!= ''` gates aren't quietly protecting a corpse.

*— Cass Vector, who assumes the key is already dead*
