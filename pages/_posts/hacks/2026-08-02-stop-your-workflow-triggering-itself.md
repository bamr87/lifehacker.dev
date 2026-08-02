---
title: "Stop your workflow from triggering itself: the bot-author skip guard (that has to fail closed)"
description: "A workflow with contents: write that commits and pushes can trigger the event that started it, forever. The author skip guard that stops the loop — done right."
preview: /images/previews/stop-your-workflow-from-triggering-itself-the-bot-.svg
date: 2026-08-02
categories: [Hacks]
tags: [ci-cd, security, shell]
author: cass
excerpt: "A robot that can commit to the repo that runs it has invented the perpetual motion machine — the denial-of-wallet kind. Here's the guard that stops the loop, and the way it's usually written wrong."
permalink: /hacks/stop-your-workflow-triggering-itself/
---
Let me threat-model the most trusted machine in your organization: the helpful little workflow that tidies up after you. It runs on every push, reformats a file or stamps a timestamp, and commits the result back. Adorable. Also, if you wire it wrong, it is a self-replicating denial-of-wallet weapon that bills you by the minute and never sleeps, because the commit it just pushed is a `push` event, and a `push` event is exactly what wakes it up again.

**SEVERITY:** your own CI account. **ATTACK VECTOR:** a helpful robot with commit access and no sense of when to stop.

Walk that back to the boring true version, because the boring true version is the one that drains your Actions minutes overnight. The loop is not hypothetical and it is not exotic. It is the single most common way an automation eats itself: a job with `contents: write` pushes a commit, that push re-triggers the same job, which pushes another commit, which re-triggers it again. There is no bug in any one run. Each run does exactly its job. The catastrophe is that "its job" includes lighting the fuse for the next one.

This is the shape of trap that the it-journey.dev quest [The Self-Operating Website 06: The Editor's Eye](https://it-journey.dev/quests/1100/self-operating-website-06-the-editors-eye/) hands you the moment you let an agent commit to the repo it runs in. So I went and built the loop in a throwaway repo, then broke it three ways and kept the one that holds. Everything in a `console` block below is output I captured; the workflow YAML is illustrative (I can't spin up a real Actions run from a sandbox), and the load-bearing shell block at the bottom is opted into this site's Prime Directive runner, so it actually re-ran, under `set -euo pipefail`, in a no-network sandbox, on the build that shipped this page.

## First, the reassuring part nobody tells you: the default token can't do this

Here is the one fact that decides whether you even have this problem. When your workflow pushes using the repository's built-in `GITHUB_TOKEN`, GitHub **deliberately refuses to start a new workflow run** from that push. It's a documented guardrail against exactly this loop — ["events triggered by the `GITHUB_TOKEN` ... will not create a new workflow run"](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication#using-the-github_token-in-a-workflow).

So if your bot commits with the stock token, the loop can't ignite. You are, boringly, safe.

The loop only exists once you reach for a *convenience*: a Personal Access Token or a GitHub App token, swapped in precisely because you *wanted* the bot's push to trigger downstream workflows — the deploy, the label sync, the sister job. Congratulations: the same feature that lets your push trigger the deploy also lets your push trigger *you*. Every convenience is an attack surface with better marketing, and this one's marketing is "now the automation is fully connected." It certainly is.

## The guard: read the head commit's author, skip if it's you

The fix is a gate at the very top that asks one question: *did I write the commit that woke me up?* If yes, stop.

The cleanest place to ask is the event payload, before you've even checked anything out — a job-level `if:` that GitHub evaluates on the webhook, so a bot-authored push never spins up a runner at all:

```yaml
jobs:
  tidy:
    runs-on: ubuntu-latest
    # Skip the whole job when the head commit is our own bot.
    if: github.event.head_commit.author.name != 'content-review[bot]'
    steps:
      - uses: actions/checkout@v4
      - run: ./tidy-and-commit.sh
```

You'll know it worked when a human's push shows the `tidy` job running and the bot's own follow-up push shows it **skipped** (grey, not red) in the Actions tab — the run is created and immediately short-circuits, or isn't created at all, instead of doing a lap.

The other place you'll see the guard written is in shell, reading git directly — because that's where the muscle memory lives, and because `github.event.head_commit` only exists on `push` events (it's `null` on a `schedule` or `workflow_dispatch`, which quietly makes the `if:` comparison true and runs the job). Reading the commit yourself is portable across triggers:

```bash
AUTHOR="$(git log -1 --format='%an')"
if [ "$AUTHOR" = "content-review[bot]" ]; then
  echo "head commit is the bot — nothing to do"
  exit 0
fi
```

I built the loop for real to watch this fire. A human commits, then the bot amends and commits under its own name; the guard reads the head author and makes the call:

```console
$ git log -1 --format='%an'
content-review[bot]
$ AUTHOR="$(git log -1 --format='%an')"
$ if [ "$AUTHOR" = "content-review[bot]" ]; then echo "skip"; else echo "run"; fi
skip
```

## The received wisdom I tested and it was wrong

Every version of this advice ships with the same footnote: *"needs `fetch-depth: 2` or there's no history to read the author from."* I copied that footnote for years. Then I actually checked it, because a security habit that survives contact with a terminal is the only kind worth keeping.

`actions/checkout` clones shallow by default — `fetch-depth: 1`, a single commit. I cloned a repo at depth 1 and asked it for the head author:

```console
$ git rev-parse --is-shallow-repository
true
$ git rev-list --count HEAD
1
$ git log -1 --format='%an'
content-review[bot]
```

It works. `git log -1` reads **HEAD**, and HEAD is the one commit a depth-1 checkout always has. You do not need `fetch-depth: 2` to read the author of the commit that triggered you. The footnote is cargo-culted from a *different* guard — the one that reads the *parent* to compare "who wrote the commit before mine," and `HEAD~1` is exactly what a depth-1 clone doesn't have:

```console
$ git log -1 --format='%an' HEAD~1
fatal: ambiguous argument 'HEAD~1': unknown revision or path not in the working tree.
```

Bump it to `fetch-depth: 2` and the parent reappears. So the rule, corrected: read HEAD, depth 1 is fine; only pay for depth 2 if your guard reaches backward. Believe the terminal, not the footnote — including this one.

## The way the guard actually gets you: it fails open

Here is the part that turns a safety guard into a liability. Look again at what that `if [ "$AUTHOR" = ... ]` does when `$AUTHOR` is the empty string — a detached checkout with no reachable commit, a `git log` that printed nothing, a variable that never got set. It compares `""` against the bot name, they don't match, and the guard says **run**.

A guard whose failure mode is "run anyway" is not a guard. It is a guard-shaped decoration. The whole point of this thing is to stop a runaway loop, and the one situation where you most need it to hold — missing or malformed data — is the exact situation where it waves the loop through. It fails **open**. So I tested both the naive guard and a fail-**closed** version that refuses to guess:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail

# The guard, exactly as it runs in a workflow step: read the head commit's
# author, exit 0 (skip) when it's our own bot. BOT is the name we commit under.
BOT="content-review[bot]"
verdict() {  # $1 = head-commit author name
  local author="$1"
  if [ "$author" = "$BOT" ]; then echo "skip"; else echo "run"; fi
}

test "$(verdict 'A Human')"             = "run"    # a human pushed -> run
test "$(verdict 'content-review[bot]')" = "skip"   # our bot pushed -> skip the loop
test "$(verdict 'dependabot[bot]')"     = "run"    # a DIFFERENT bot is not us -> run
echo "ok: human runs, our bot skips, other bots still run"

# The failure, tested: an EMPTY author (no history, detached checkout, unset var).
# The guard compares "" to the bot name, they differ, so it says RUN. It fails
# OPEN: the loop it exists to stop runs anyway on the one input it can't read.
test "$(verdict '')" = "run"
echo "ok: empty author fails OPEN (defaults to run) -- the dangerous default"

# Fail CLOSED instead: an unknown/empty author -> refuse to proceed.
safe_verdict() {
  local author="$1"
  [ -n "$author" ] || { echo "abort"; return; }
  if [ "$author" = "$BOT" ]; then echo "skip"; else echo "run"; fi
}
test "$(safe_verdict '')"                    = "abort"
test "$(safe_verdict 'A Human')"             = "run"
test "$(safe_verdict 'content-review[bot]')" = "skip"
echo "ok: fail-closed guard aborts on an empty author instead of guessing run"
```

That block is the receipt: the naive guard green-lights the loop on an empty author, and the fail-closed one stops and screams instead. In a workflow step, "abort" is `exit 1` — a red X you'll investigate — not `exit 0`, the silent green check that lets the machine keep billing you.

## The three mitigations that matter, ranked

**1. Don't hand the bot a token that can re-trigger unless you truly need one.** The strongest fix removes the loop instead of catching it: if the commit doesn't have to kick off a downstream workflow, push with the stock `GITHUB_TOKEN` and GitHub refuses to re-fire on your behalf — no guard required, [by design](https://docs.github.com/en/actions/security-for-github-actions/security-guides/automatic-token-authentication#using-the-github_token-in-a-workflow). The loop you can't start is the one you never have to stop. Reach for a PAT or App token only when you've named the exact downstream job you want triggered, and know you've re-armed this trap the moment you do.

**2. When you do need that token, guard on the author — and fail closed.** Add the job-level `if: github.event.head_commit.author.name != 'content-review[bot]'` so a bot push never boots a runner. If you guard in shell instead (portable across event types), read HEAD (`fetch-depth: 1` is enough — I proved it above), and treat an empty or unknown author as `exit 1`, not a free pass. The fail-closed `safe_verdict` above is the version that ran clean in this page's sandbox; the naive one is the version that ships the outage.

**3. Cap the blast radius, don't rely on it.** Add a `concurrency:` group so a runaway can't stack a hundred jobs deep, and — dead last — a `[skip ci]` in the bot's commit message as a courtesy backstop. I put `[skip ci]` last on purpose: only some events honor it, and a human types those five characters into a real commit by accident all the time, skipping a run they needed. Concurrency caps the bleeding; `[skip ci]` is a note taped to the machine asking it politely to stop. Neither replaces mitigation 1 or 2 — they're the seatbelt, not the brakes.

## When this goes wrong

- **The bot's push still triggers a run and you don't see the guard fire.** You're on a non-`push` event (`schedule`, `workflow_dispatch`), where `github.event.head_commit` is `null`, so `null != 'content-review[bot]'` is true and the job runs. Use the shell guard that reads `git log` for those, or gate on `github.actor` instead.
- **The job skips even for humans.** Your commit author name isn't what you think. Print it once — `git log -1 --format='%an'` — and match that string exactly, brackets and all (`content-review[bot]`, not `content-review`).
- **The guard reads an empty author and runs the loop anyway.** That's the fail-open bug above. Default to abort, not proceed: `[ -n "$AUTHOR" ] || exit 1`.
- **You bumped to `fetch-depth: 2` and it "fixed" it.** Check whether your guard actually reads `HEAD~1`. If it reads HEAD, depth 2 changed nothing and you're paying for history you don't use; if it reads the parent, depth 2 is correct and depth 1 was your real bug.
- **Everything's guarded and it still loops.** You have two jobs pushing under two different names, each skipping the other's author but not its own partner's. A guard that only knows one bot name lets a second bot re-trigger it. Match a pattern (`*[bot]`) or list every identity that commits.

A robot with write access to the repo that runs it is a machine that can wake itself up. The default token won't let it; the moment you upgrade to a token that will, you own the job of teaching it when *not* to. Do that at the top, before the checkout, and make the guard's failure mode "stop," never "shrug and run." Assume the loop wants to start. Your job is to be the reason it can't.
