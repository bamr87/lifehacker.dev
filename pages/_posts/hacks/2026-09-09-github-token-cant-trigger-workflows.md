---
title: "The workflow that never fired: why a bot's GITHUB_TOKEN commit triggers nothing (and the PAT that changes that)"
description: "A push made with the default GITHUB_TOKEN deliberately starts no new workflow. Swap in a PAT and the cascade fires — and so does the infinite loop the default token was holding shut."
date: 2026-09-09
preview: /images/previews/the-workflow-that-never-fired-why-a-bot-s-github-t.svg
categories: [Hacks]
tags: [ci-cd, security]
author: cass
excerpt: "The most obedient bot on your pipeline is the one that pushed a commit and expected the next workflow to run. It never did. Nobody told you. The check was green."
permalink: /hacks/github-token-cant-trigger-workflows/
---
Here is the threat nobody threat-models: the convenience of a workflow that commits something and trusts the next workflow to notice. Your release job bumps a version and pushes. You *assume* the deploy job — the one wired to `on: push` — wakes up and ships it. It does not. There is no error. There is no failed step. There is a green check on a pipeline that quietly stopped halfway, because the commit that was supposed to be the starting gun was fired by `GITHUB_TOKEN`, and GitHub treats anything that token does as inert. The cascade you designed is a row of dominoes where the first one is made of foam.

`SEVERITY: your own CI. ATTACK VECTOR: a green check on a job that never ran.`

I distrust this the way I distrust a door that latches silently — you only learn it didn't lock when something's already gone. This exact footgun has real fingerprints: the sister site over at it-journey.dev has a [PRD resolution report](https://it-journey.dev/RESOLUTION_REPORT/) whose flagged conflicts are literally two commits fighting each other — `fix(ci): replace PAT_TOKEN with GITHUB_TOKEN` and, right below it, `fix(workflows): update GITHUB_TOKEN to PAT_TOKEN`. That is not indecision. That is one team discovering, twice, that these two tokens are not interchangeable, and paying for the lesson in reverted commits. So let me hand you the reason it happens and the three mitigations that matter — the guard I'm about to show you, I actually ran.

## Why the domino is made of foam

This is deliberate, documented GitHub behavior, not a bug: **events triggered by the automatic `GITHUB_TOKEN` do not create a new workflow run.** A `push`, a `pull_request`, an issue comment — if the actor behind it is the built-in token, the `on:` trigger listening for that event stays asleep. GitHub built this fence on purpose, and it is a good fence: without it, a workflow that pushes a commit on every push would retrigger itself forever, a self-replicating CI loop that empties your runner minutes into the void. The fence is protecting you from a mistake that is very easy to make.

The catch is that the fence has no gate you can see. The same rule that stops the infinite loop also stops the *deliberate* handoff — the deploy-after-release, the label-after-open, the rebuild-after-generate — with the identical silence. You did not opt into loop protection; you opted into "push a commit," and loop protection came stapled to the back of it. Convenience with a hidden clause is my least favorite kind.

You'll know it's this and not your YAML when: the run history shows your push landed (the commit is *there*), the downstream workflow's `on:` trigger clearly matches, and yet that workflow has **no run** for that commit — not a failed one, not a skipped one, none. The actor on the push event reads `github-actions[bot]`. That combination — real commit, matching trigger, zero downstream run, bot actor — is the signature. Nothing else looks quite like it.

## The fix is a real actor — which re-arms the loop

When you genuinely want the cascade, you push with a credential that carries a real identity instead of the inert built-in one: a fine-grained **Personal Access Token**, or better, a **GitHub App installation token**, stored as a secret and handed to the checkout:

```yaml
# The release job pushes with a PAT so the deploy workflow actually wakes up.
- uses: actions/checkout@v4
  with:
    token: ${{ secrets.RELEASE_PAT }}   # NOT the default GITHUB_TOKEN
# ... later, after committing the version bump ...
- run: git push origin HEAD:main
```

Now the push event carries the PAT owner as its actor, GitHub sees a "real" trigger, and the deploy fires. Problem solved — and the foam domino is now made of C-4. Because the very property that makes the cascade work is the property the built-in token was withholding: your workflows can now trigger each other. The release job pushes, which triggers deploy, which (if it also commits, as deploy jobs love to do) pushes, which triggers release, which — you see it. You traded "nothing runs" for "everything runs forever," and the second one bills by the minute.

`SEVERITY: a runaway self-replicating pipeline. ATTACK VECTOR: the fix for the last problem.`

So the PAT is not the end of the job. It is the moment you take on the responsibility the built-in token was quietly carrying for you. Here are the three mitigations that pick that responsibility back up, ranked by how much damage each one prevents.

## Mitigation 1 — least-privilege the token, because it's a standing key now

Before you worry about loops, worry about the thing you just created: a long-lived credential, sitting in a repo secret, that can trigger workflows. If it leaks, it doesn't just read code — it *runs* your CI as a trusted actor. A classic PAT with `repo` scope is a skeleton key to every repository the owner can touch; drop that in a secret and a single poisoned pull request or a compromised action has org-wide reach.

Mint the narrowest thing that works, in this order:

- **A GitHub App installation token** — scoped to specific repos and permissions,
  short-lived (it expires in an hour), and auditable as its own identity instead of impersonating a human. This is the one I actually want you to use.
- **A fine-grained PAT** — if an App is too much ceremony, scope the PAT to *one*
  repository with only `Contents: write` (add `Workflows: write` only if you push workflow files). Not "all repositories." Not classic. One repo, two permissions.

`SEVERITY: org-wide CI compromise. ATTACK VECTOR: the words "all repositories" on the token-creation screen.` The blast radius of a leaked token is exactly the scope you gave it and not one repo smaller, so give it almost nothing.

## Mitigation 2 — put the loop guard back, and make it fail closed

The default token was holding the infinite-loop door shut for you. The PAT props it open, so you re-add the doorstop yourself: a guard that refuses to run the cascade when the commit came from your own automation. You can express this three ways — a commit-message sentinel (`[skip cascade]`), a `paths-ignore` on the generated files, or an actor check — and the belt-and-suspenders answer is to combine them and **fail closed**: an actor you can't identify is treated as the bot and skipped, because "I'm not sure who pushed this" is not a reason to re-fire a self-triggering pipeline.

Here is the decision logic as a shell function so you can see it think. It skips its own bot, honors an opt-out sentinel, and refuses to run on an empty/unknown actor:

```bash
# should_run: refuse to re-trigger the cascade for our own bot's commits.
# $1 = the push actor (github.actor in a workflow), $2 = HEAD commit message.
# Fails CLOSED: an actor we can't identify is treated as the bot and skipped.
should_run() {
  local actor="${1:-}" msg="${2:-}" bot="release-bot"
  if [[ -z "$actor" ]]; then
    echo "skip: empty actor — cannot prove this isn't the loop; failing closed"; return 1
  fi
  if [[ "$msg" == *"[skip cascade]"* ]]; then
    echo "skip: commit opts out with [skip cascade]"; return 1
  fi
  if [[ "$actor" == "$bot" || "$actor" == *"[bot]" ]]; then
    echo "skip: commit by '$actor' is the bot itself — not re-triggering (loop guard)"; return 1
  fi
  echo "run: commit by '$actor' — real human/PAT actor, proceeding"; return 0
}
```

I ran it against five commits — the two bot identities, a human, a bot commit carrying the opt-out sentinel, and the empty-actor case a broken event payload hands you. Real captured output:

```console
$ bash guard-demo.sh
skip: commit by 'github-actions[bot]' is the bot itself — not re-triggering (loop guard)
  -> exit=1
skip: commit by 'release-bot' is the bot itself — not re-triggering (loop guard)
  -> exit=1
run: commit by 'alice' — real human/PAT actor, proceeding
  -> exit=0
skip: commit opts out with [skip cascade]
  -> exit=1
skip: empty actor — cannot prove this isn't the loop; failing closed
  -> exit=1
```

You'll know it worked when the human's commit is the *only* one that returns `exit=0`. In a workflow this becomes a job-level `if:` — `if: github.actor != 'release-bot'` — or you gate the whole file with a first step that runs this check and exits early. The key is that the guard, not the platform, is now what stops the loop. Whichever token you chose, the guard is what makes the choice safe.

## Mitigation 3 — scope the trigger so a leak can't detonate everywhere

The last doorstop is narrowing what the downstream workflow will even respond to, so that if the guard is ever bypassed, the cascade has a small target instead of your whole repo. Pin the trigger to the branch and paths that actually matter:

```yaml
on:
  push:
    branches: [main]          # not every branch a bot might push
    paths: ['VERSION', 'dist/**']   # not "any file changed, anywhere"
```

A trigger scoped to `main` and two paths cannot be set off by a bot pushing a doc fixup to a feature branch, which means most of the accidental-cascade surface is gone before the guard even has to think. Combined with Mitigation 2 this is defense in depth: the trigger narrows *what* can start the loop, and the guard refuses *who* is allowed to. Convenience features love a wide trigger because it "just works" from anywhere; that width is the attack surface, so trim it to the one branch and the two paths you meant.

## When this goes wrong

- **The PAT owner leaves the company.** A PAT is tied to a human account. When
  they offboard, your production deploy cascade dies with their access, silently, exactly like the original bug. This is the whole reason Mitigation 1 ranks a GitHub App above a personal PAT — the App has no résumé to update.
- **`github.actor` isn't what you think under a PAT.** When you push with a PAT
  owned by a machine user called `release-bot`, the actor is `release-bot`, *not* `github-actions[bot]`. Guard on your bot's actual username (or a sentinel), or the check waves the loop right through.
- **Loop protection was the only thing saving you.** If removing the default token
  gives you a runaway pipeline within minutes, that is not the PAT misbehaving — that is proof your cascade always wanted to loop and the platform was the only adult in the room. Add the guard *before* you add the PAT, not after the runner-minute bill.

## The payload: three mitigations, ranked

Since the fix for one problem is the cause of the next, here is the ranked list — most damage prevented first:

1. **Least-privilege the token (App over PAT, one repo, two permissions).** This is
   the one that turns a leaked secret from "org-wide CI compromise" into "one repo, contents only." Never a classic `repo`-scoped PAT in a workflow secret.
2. **Put the loop guard back, failing closed.** The default token was holding the
   infinite-loop door shut; the moment you swap it out, *you* are the doorstop. Skip your own bot, honor an opt-out, and treat an unknown actor as the bot.
3. **Scope the trigger to the branch and paths you meant.** Defense in depth: a
   narrow `on:` can't be tripped from a feature branch, so a bypassed guard still has almost nothing to detonate.

None of these is "be more careful." Two are a few lines of YAML and one is a shell function I ran in front of you. The bot that pushed and expected the next job to run is the quietest failure on your pipeline — and the fix that wakes it up is the loudest one, unless these three locks are on the door before you hand it the key.
