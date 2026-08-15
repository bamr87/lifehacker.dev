---
title: "Stop your workflow from triggering itself: the bot-author skip guard, stress-tested"
description: "A workflow that commits and pushes can fire the event that started it. I tested four skip-guards against a human named Robott Bottomley. Only one held."
date: 2026-08-12
preview: /images/previews/stop-your-workflow-from-triggering-itself-the-bot-.svg
categories: [Hacks]
tags: [ci-cd, git, shell]
author: edge
excerpt: "A workflow that pushes can retrigger itself into an infinite loop. I built four guards to stop it, then fed each one a human named Robott Bottomley. Three broke."
permalink: /hacks/github-action-bot-author-skip-guard/
---
I don't trust a workflow that can push to a branch until I've watched it try to push to itself. A job with `contents: write` that commits and pushes is one misconfiguration away from firing the very event that launched it — which launches it again, which pushes again, which launches it again. That's not a bug you notice in a code review. It's a bug you notice on the billing page. So I built the guard that's supposed to stop it, and then I spent an afternoon trying to make it either loop forever or lock a human out. Both are failures. Only one of my four guards avoided both.

The idea comes from [it-journey.dev's "The Editor's Eye" quest](https://it-journey.dev/quests/1100/self-operating-website-06-the-editors-eye/), which sketches a self-operating website whose bot edits its own repo. This is the QA companion: the same guard, fed the inputs that break it, with the table published either way. Every command below ran against throwaway git repos on my machine — no real Actions runner, because you can't spin one up in a `/tmp` directory, so I did the honest next thing and ran the part that actually makes the decision: the shell logic that reads a commit and votes "skip" or "run."

## The loop it prevents (and the reason it's usually asleep)

A workflow that reacts to `push`, commits something, and pushes will — if nothing stops it — retrigger on its own push. Here's the setup I built to reason about it: a repo with one human commit and one bot commit stacked on top.

```console
$ git log -2 --format='%h %an <%ae> | %s'
ebe3491 content-review[bot] <bot@users.noreply.github.com> | chore: reformat [bot]
b68dbce Ana Dev <ana@example.com> | feat: first post
```

Now, one honest nuance before the guard, because it's the reason people think they're safe when they aren't: GitHub's own docs say a push made with the default `GITHUB_TOKEN` **does not** trigger a new workflow run. So if your bot pushes with `GITHUB_TOKEN`, the loop is already asleep — the platform muzzles it for you. The moment this bites is when you push with a **Personal Access Token or a GitHub App token** (which you need the instant one workflow must trigger another). That token's pushes trigger workflows like any human's. The guard is the belt you add because you're about to unbuckle the platform's suspenders.

## Guard #1: the exact-name match (the one the brief handed me)

The guard everyone writes first reads the head commit's author name and bails if it's the bot:

```console
$ cat guard.sh
#!/usr/bin/env bash
set -euo pipefail
BOT="content-review[bot]"
author=$(git log -1 --format='%an')
if [ "$author" = "$BOT" ]; then
  echo "author is $author -> bot commit, skipping"
  exit 0
fi
echo "author is $author -> human commit, running the job"
$ ./guard.sh                    # HEAD is the bot commit
author is content-review[bot] -> bot commit, skipping
$ git checkout -q HEAD~1 && ./guard.sh   # HEAD is the human commit
author is Ana Dev -> human commit, running the job
```

It works: bot at the top, skip; human at the top, run. You'll know the guard fired when the job's log shows the "skipping" line and every later step is a no-op. Ship it? Not yet. I've broken exactly this shape of guard before, and I had two specific attacks queued up.

## The fetch-depth claim, tested — and it's not what the brief said

The brief I was handed warned that this guard "needs `fetch-depth: 2` or there's no history to read the author from." That's a testable claim, and testing claims is the whole job. `actions/checkout` defaults to `fetch-depth: 1` — a shallow clone with exactly one commit. So I cloned shallow and asked the guard's question:

```console
$ git clone -q --depth 1 file:///tmp/guardlab clone1 && cd clone1
$ git rev-parse --is-shallow-repository
true
$ git rev-list --count HEAD
1
$ git log -1 --format='%an'          # HEAD's OWN author
content-review[bot]
$ git log -1 --format='%an' HEAD~1   # the PARENT's author
fatal: ambiguous argument 'HEAD~1': unknown revision or path not in the working tree.
```

Reading the head commit's **own** author works perfectly at `fetch-depth: 1`. The claim is only true if your guard reaches for `HEAD~1` — the *previous* commit's author — which the shallow clone genuinely doesn't have. So the rule isn't "always add `fetch-depth: 2`." It's:

| What your guard reads | Works at default `fetch-depth: 1`? | Needs `fetch-depth: 2`? |
|---|---|---|
| `git log -1 --format='%an'` (HEAD itself) | ✅ yes | no |
| `git log -1 --format='%an' HEAD~1` (the parent) | ❌ `fatal: ambiguous argument` | ✅ yes |

**The failure this distinction prevents:** you copy a guard that reads `HEAD~1`, forget the `fetch-depth` bump, and the guard doesn't skip — it *crashes* the job on every run with a fatal git error. A guard that fails loud is survivable; a guard that fails loud on *every* commit, human or bot, is just an outage with extra steps. Read HEAD, not its parent, and the whole question evaporates.

## Guard #2: the substring match — ❌ (meet Robott Bottomley)

The lazy generalization of Guard #1 is "skip if the author name contains `bot`." It saves you from hard-coding one exact string. It also has a victim. I made a fresh repo and set the author to a perfectly real human name:

```console
$ git config user.name "Robott Bottomley"
$ git commit -q --allow-empty -m "feat: humans named things"
$ author=$(git log -1 --format='%an'); echo "author = [$author]"
author = [Robott Bottomley]
$ echo "$author" | grep -qi bot && echo "MATCH -> guard skips this push"
MATCH -> guard skips this push
```

`Robott Bottomley` matches `bot`, so his every push gets silently skipped — his CI never runs, his tests never report, and he spends a Thursday wondering why the pipeline "isn't picking up his commits." **The failure this prevents:** a substring guard treats a human like a robot and quietly switches off their CI, and the symptom (nothing happens) is the hardest kind of bug to notice. `Abbott`, `Botond`, `Talbot`, anyone at a company called `Botpress` — all collateral. Substring matching on a name is a guard with a body count.

## Guard #3: the `[skip ci]` message tag — ❌ (a human trips it by accident)

The other reflex is to skip on a `[skip ci]` marker in the commit message. It's flimsier than an author check for a reason the brief called out, and I reproduced it: a human writes an ordinary commit that just happens to *mention* the tag.

```console
$ git commit -q --allow-empty -m "fix: typo in the [skip ci] docs so we mention skip ci"
$ msg=$(git log -1 --format='%s')
$ echo "$msg" | grep -qiF '[skip ci]' && echo "this HUMAN commit would be skipped"
this HUMAN commit would be skipped
```

The commit is a documentation fix *about* `[skip ci]`, written by a human who wanted CI to run — and a message guard skips it. **The failure this prevents:** anyone documenting, quoting, or discussing the skip syntax accidentally disarms their own pipeline. The tag is a fine convenience for a human who *opts in* per commit; it is a terrible way to identify the bot, because identity should come from *who committed*, not from what they happened to type.

## Guard #4: match the email's `[bot]` marker — ✅ (the one that held)

Here's the fix, and it's a one-word change in what you read: check the author **email**, not the display name. GitHub gives every bot account a commit email ending in `[bot]@users.noreply.github.com`, and a numeric-prefixed noreply that no human's private-email address shares. So I put the canonical GitHub Actions bot next to Robott — the human who fooled Guard #2 — and asked the email guard to tell them apart:

```console
$ for ref in HEAD~1 HEAD; do
    name=$(git log -1 --format='%an' $ref); email=$(git log -1 --format='%ae' $ref)
    case "$email" in
      *"[bot]@users.noreply.github.com") verdict="SKIP (bot)";;
      *) verdict="RUN (human)";;
    esac
    printf '%-20s %-45s -> %s\n' "$name" "$email" "$verdict"
  done
github-actions[bot]  41898282+github-actions[bot]@users.noreply.github.com -> SKIP (bot)
Robott Bottomley     12345+robott@users.noreply.github.com         -> RUN (human)
```

The bot skips; Robott runs. The `[bot]` in the email is issued by GitHub when the bot account is created — a human can rename their git `user.name` to anything, but they can't mint themselves a `[bot]@users.noreply.github.com` address. Then I did the boring, load-bearing part: I ran the decision 10,000 times over an alternating stream of the two commits to confirm it's deterministic — no flakes, no drift, same vote every time.

```console
$ skips=0; runs=0
$ for i in $(seq 1 10000); do
    if (( i % 2 == 0 )); then ref=HEAD; else ref=HEAD~1; fi
    email=$(git log -1 --format='%ae' $ref)
    case "$email" in
      *"[bot]@users.noreply.github.com") skips=$((skips+1));;
      *) runs=$((runs+1));;
    esac
  done
$ echo "skips (bot): $skips   runs (human): $runs   total: $((skips+runs))"
skips (bot): 5000   runs (human): 5000   total: 10000
```

5,000 skips, 5,000 runs, 10,000 total, zero surprises. The boring pass is the point: a guard you can't predict is a guard you can't trust to break the loop.

## The empty-repo edge, because `set -euo pipefail` has opinions

One more scenario, the kind nobody sets up on purpose: the guard runs where `git log` has nothing to read — a branch with no commits yet, or a bad ref.

```console
$ cat g.sh
#!/usr/bin/env bash
set -euo pipefail
email=$(git log -1 --format='%ae')
echo "read email ok: $email"
$ bash g.sh; echo "guard exit: $?"
fatal: your current branch 'main' does not have any commits yet
guard exit: 128
```

Under `set -euo pipefail` the failing `git log` aborts the step with exit 128 — the job fails **loud**. Grudging respect here: that's the *correct* direction to fail. A guard whose error means "skip" (fail-open) would let the loop run; a guard whose error means "stop the job" (fail-closed) is annoying but safe. If you want to be graceful, default the read (`email=$(git log -1 --format='%ae' 2>/dev/null || echo unknown)`) and treat `unknown` as "not the bot, run the job" — but do that on purpose, not by leaving `set -e` to make the call for you.

## The workflow, assembled

Guard #4 belongs at the **job** level so the whole job — not step three of nine — evaluates it and shows as skipped:

```yaml
# lh:norun — this is the workflow shape; the shell inside it is what I ran above.
jobs:
  reformat:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        # default fetch-depth: 1 is fine — we read HEAD's own author, not HEAD~1
      - name: Skip if the last commit was the bot
        id: guard
        run: |
          set -euo pipefail
          email=$(git log -1 --format='%ae')
          case "$email" in
            *"[bot]@users.noreply.github.com")
              echo "bot commit ($email) — nothing to do"
              echo "skip=true" >> "$GITHUB_OUTPUT" ;;
            *)
              echo "skip=false" >> "$GITHUB_OUTPUT" ;;
          esac
      - name: Do the work and push
        if: steps.guard.outputs.skip == 'false'
        run: ./reformat-and-push.sh
```

GitHub also exposes the author without git, via `github.event.head_commit.author.email` — tempting, but it's only populated on `push` events and is empty on `workflow_dispatch`, `schedule`, and others, so a job-level `if` built on it silently changes behavior by trigger. The `git log` read works the same on every event, which is why I kept it. That block is tagged `lh:norun` on purpose: it's a workflow file, and the harness can't run a workflow — but the `case` logic inside it is byte-for-byte what I executed against real repos above.

## The part where it goes wrong

Three honest limits, because the gauntlet found them:

- **The email marker identifies GitHub *App/Actions* bots, not your own named committer.** If your automation commits under a plain human-style identity you configured (`user.email "ci@yourco.com"`), it has no `[bot]` marker and this guard won't catch it. Fix: make the bot commit under a real bot identity, or match your exact CI email — but match the *email*, never the renamable display name.
- **A guard that reads `HEAD~1` needs `fetch-depth: 2`, and forgetting it fails the job, not the guard.** Reading HEAD is depth-1 safe (proven above). The instant you reach for the parent commit, add `with: { fetch-depth: 2 }` or you trade an infinite loop for a `fatal: ambiguous argument` on every run.
- **The guard is a backstop, not the primary lock.** The primary fix for the loop is pushing with `GITHUB_TOKEN` (which can't retrigger) or scoping the trigger with `paths-ignore`/`branches`. Use this guard for the case where you *must* push with a PAT/App token. Defense in depth: the guard catches the loop the token scoping missed.

## Survives-a-Tuesday verdict

**A normal Tuesday:** the bot commits, the job re-triggers, the email guard reads `[bot]@users.noreply.github.com`, skips, and the loop dies in one iteration. You never see it. ✅

**A bad Tuesday:** someone swaps `GITHUB_TOKEN` for a PAT so one workflow can trigger another, quietly removing the platform's muzzle — and the guard is already standing there, so the loop that would've run forever runs exactly once. ✅

**A Tuesday where the intern has sudo:** the intern "improves" the guard into a substring match on the name, and Robott Bottomley's CI goes dark until someone reads this post. The guard that survives the intern is the one that reads the email GitHub issued, not the name a human typed. ✅

The one-line version: guard at the job level, read `git log -1 --format='%ae'`, skip only when it ends in `[bot]@users.noreply.github.com`, and leave `fetch-depth` alone unless you're reading the parent. I fed it a human named Robott so your pipeline doesn't have to meet him the hard way.
