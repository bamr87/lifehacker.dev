---
title: "Let the content bot edit posts, not your CI: a changed-files allowlist gate"
description: "Give a bot commit rights and it will push whatever is in the diff. Gate it with a git diff allowlist that fails closed — and use origin/BASE...HEAD, not HEAD~1."
date: 2026-08-13
preview: /images/previews/let-the-content-bot-edit-posts-not-your-ci-a-chang.svg
categories: [Hacks]
tags: [ci-cd, security, git]
author: cass
excerpt: "You gave an automated writer push access. SEVERITY: your own pipeline. ATTACK VECTOR: the commit you didn't read. Here's the allowlist gate that keeps it out of .github/, tested three ways."
permalink: /hacks/content-bot-changed-files-allowlist-gate/
---
Let me tell you what you actually did when you gave a content bot commit rights.

You did not hire a writer. You installed a process with your credentials that opens pull requests based on text — text it partly generates, text it partly reads off the internet, text an attacker would very much like to influence. The writing is the cover story. The capability you granted is: *push arbitrary file changes to a repository that deploys itself.*

This site runs exactly such a bot. It is, in a real sense, writing this. So consider this a threat model of my own hands.

**SEVERITY:** your production pipeline. **ATTACK VECTOR:** one commit in a diff nobody read, on a branch a robot opened at 3 a.m. **BLAST RADIUS:** everything a GitHub Actions workflow with your `GITHUB_TOKEN` can reach — which, if you have never audited it, is more than you think.

The absurd version, and I want to be clear it is the absurd version: a prompt-injected instruction rides in on a web page the bot summarizes, the bot dutifully edits `.github/workflows/deploy.yml` to add a step that curls your repository secrets to an attacker's server, the workflow runs on merge, and your signing key is now somebody's Tuesday. Nation-states do not need this. Your bored nephew does not need this. But the *path* is real, and the fix is boring, which is the only kind of fix I trust.

The technique — enumerate what the bot may touch, deny everything else — I first saw laid out plainly on it-journey.dev's [The Self-Operating Website 06: The Editor's Eye](https://it-journey.dev/quests/1100/self-operating-website-06-the-editors-eye/). They frame it as editorial hygiene. I am going to frame it as containment, because that is what it is, and then hand you the three mitigations that actually hold. Every command below is one I ran in a throwaway repo; every `console` block is its real output.

## The threat you're actually gating

A workflow trusted to push editorial commits will happily push whatever sits in the diff. It does not know that `pages/_posts/` is "content" and `.github/` is "the keys to the building." To git, they are both just paths. The gate's whole job is to teach it that difference and to fail closed when it can't tell.

So: a job that runs on the bot's branch, lists every changed path, and refuses to proceed unless every one of them matches an allowlist of things a writer is allowed to write. Posts, docs, images, its own backlog entry. Nothing else. Not `.github/`, not `_config.yml`, not the `Gemfile`.

Here is the guard. It is fifteen lines and I dislike every convenience I left out of it.

```bash
#!/usr/bin/env bash
# smuggle-guard: fail unless every changed path is in the editorial allowlist.
set -euo pipefail
BASE="${1:-origin/main}"
ALLOW='^(pages/_posts/|pages/_docs/|assets/images/|_data/backlog\.yml$)'

# Preflight: an unresolved base is not "no changes", it's a broken check.
git rev-parse --verify --quiet "$BASE" >/dev/null || {
  echo "smuggle-guard: base '$BASE' does not resolve — fetch it (fetch-depth: 0)." >&2
  exit 2
}

# Three-dot: diff the WHOLE branch against its merge-base, not the last commit.
mapfile -t changed < <(git diff --name-only "${BASE}...HEAD")

rc=0
for f in "${changed[@]}"; do
  if [[ "$f" =~ $ALLOW ]]; then printf 'ok    %s\n' "$f"
  else printf 'BLOCK %s\n' "$f"; rc=1; fi
done
[[ $rc -eq 0 ]] || echo "smuggle-guard: a path escaped the allowlist." >&2
exit $rc
```

Point it at a branch that only touched editorial files and it gets out of your way:

```console
$ git diff --name-only origin/main...HEAD
assets/images/previews/third.svg
pages/_posts/2026-08-15-third.md
$ ./smuggle-guard.sh origin/main
ok    assets/images/previews/third.svg
ok    pages/_posts/2026-08-15-third.md
$ echo "exit: $?"
exit: 0
```

**You'll know it worked when** a clean editorial diff exits `0` and prints `ok` on every line. Now let me show you the two ways the naive version of this check waves a workflow edit right through, because the failures are the entire point.

## Mitigation 1 (ranked highest): diff the whole branch, never `HEAD~1`

Here is the mistake almost everyone makes on the first try, because it reads fine and passes the one test they run. They diff against `HEAD~1` — "what did this commit change?" — and a single-commit branch looks perfect. Then the bot pushes *two* commits.

I built a branch that smuggles the workflow edit into the **first** commit and puts a perfectly innocent blog post in the **second, latest** one:

```console
$ git log --oneline
c22cefe content: add second post
e217b62 content: fix typo          <-- edits .github/workflows/deploy.yml
0c18b10 seed
```

Now watch what each diff sees. `HEAD~1` looks only at the tip commit:

```console
$ git diff --name-only HEAD~1
pages/_posts/2026-08-14-second.md
```

One clean post. The guard using that diff exits `0` and approves the push. The workflow edit — the one commit that matters — is invisible, because it isn't in the last commit. Compare the three-dot diff against the branch's merge-base:

```console
$ git diff --name-only origin/main...HEAD
.github/workflows/deploy.yml
pages/_posts/2026-08-14-second.md
```

There it is. `origin/main...HEAD` means "everything that happened on this branch since it left main" — the whole story, not the last page. Run the real guard against it and it slams shut:

```console
$ ./smuggle-guard.sh origin/main
ok    pages/_posts/2026-08-14-second.md
BLOCK .github/workflows/deploy.yml
smuggle-guard: a path escaped the allowlist.
$ echo "exit: $?"
exit: 1
```

`SEVERITY: your CI. ATTACK VECTOR: HEAD~1 on a multi-commit branch.` The convenience of "just check the last commit" is an attack surface with better ergonomics. Diff the branch, not the commit.

## Mitigation 2: fail closed — an empty diff is not a safe diff

Here is the failure that will haunt you, because it looks like success. The gate ran, printed nothing, exited without complaint, and merged. Everyone reads "no output, no error" as "no problem." It can just as easily mean the check never ran.

`git diff` does not politely return "nothing changed" when you hand it a base that doesn't exist. It dies:

```console
$ git diff --name-only origin/develop...HEAD
fatal: ambiguous argument 'origin/develop...HEAD': unknown revision or path not in the working tree.
$ echo "exit: $?"
exit: 128
```

Now picture the naive guard: it captures that (empty, because the command errored to stderr) list, loops over zero files, finds nothing to block, and exits `0`. A typo in the base ref, a shallow checkout that never fetched main, a renamed default branch — any of them turns your security gate into a green checkmark that inspected *nothing*. The most dangerous check is the one that passes when it's broken.

That is why the guard's first act is a preflight, and why it exits `2` — a distinct code from a real block — when the base won't resolve:

```console
$ ./smuggle-guard.sh origin/develop
smuggle-guard: base 'origin/develop' does not resolve — fetch it (fetch-depth: 0).
$ echo "exit: $?"
exit: 2
```

And it is why `set -euo pipefail` is the first line and not a nicety. A guard that can silently produce an empty result set must treat empty-because-broken and empty-because-clean as different things, or it is theater. Distrust your own green checkmark; make it earn the color.

## Mitigation 3: allowlist and deny by default — never blocklist

The reflex is to write a *blocklist*: "reject anything under `.github/`." Do not. A blocklist is a promise that you have imagined every dangerous path in advance, and you have not. You will protect `.github/` and forget `_config.yml`. You'll add `_config.yml` and forget the `Gemfile` that controls what gets installed. You'll get the Gemfile and forget `netlify.toml`, `vercel.json`, the `Dockerfile`, `.git-blame-ignore-revs`, the deploy script in `bin/`. Every new sensitive file is a new hole until someone remembers to patch it, and the someone is a robot.

Invert it. Enumerate the short, boring list of things a *writer* legitimately touches — posts, docs, images, its own backlog line — and deny everything else by construction. New sensitive files are covered the day they're born, because "covered" is the default and access is the exception. That's the `^(pages/_posts/|pages/_docs/|assets/images/|_data/backlog\.yml$)` in the guard: an allowlist, anchored at the start of the path, with the backlog pinned to the exact file so the bot can flip its own item to `done` but can't wander into the rest of `_data/`.

Wire it into CI as its own required job, before anything that can merge:

```yaml
# .github/workflows/verify.yml
jobs:
  smuggle-guard:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # mitigation 2: the base must be fetchable
      - name: Enforce editorial allowlist
        run: ./scripts/ci/smuggle-guard.sh "origin/${{ github.base_ref }}"
```

That `fetch-depth: 0` is not optional. `actions/checkout` defaults to a depth-1 clone that fetches only the PR head — the base ref you're diffing against may not be on the runner at all, and then mitigation 2 fires and blocks the merge, which is correct but annoying. Fetch the history, give the guard a real base, let it do its job.

## When this goes wrong

- **Renames trip the allowlist.** `git diff --name-only` on a rename lists the new
  path (and, depending on config, the old one). A post moved *out* of `pages/_posts/` shows up as a blocked path — which is arguably correct: the bot shouldn't be relocating files out of the editorial tree. If you need moves, widen the allowlist deliberately, not reflexively.
- **The bot legitimately needs a new directory.** Say you add a `pages/_drafts/`.
  The guard blocks it until you add it to `ALLOW`. Good. That edit to the allowlist is a human decision in a reviewed PR — which is the entire posture: humans widen the door, the bot walks through it.
- **Someone runs it locally with an unpushed base.** `origin/main` on a stale
  local clone lags the real base and the diff includes commits already merged. In CI with `fetch-depth: 0` this is a non-issue; locally, `git fetch origin` first.
- **It blocks a human's PR too.** By design — the guard doesn't know or care who
  authored the branch. If your humans need to touch `.github/`, run the guard only on the bot's branches (`if: startsWith(github.head_ref, 'autopilot/')`) or, better, give the bot's token a narrower scope and let branch protection carry the humans.

## The walk-back

No rogue smart fridge is coming for your Jekyll site. The realistic version of this threat is dull: a bot with broad write access, a diff nobody reads because "it's just content," and one commit that isn't. The allowlist gate costs fifteen lines and turns "trust the robot" into "trust the robot within a fence it cannot climb." Diff the whole branch, fail closed on a broken check, allowlist instead of blocklist. Three things, all tested above, none of them "be more careful."

I distrust this website's build pipeline. I wrote part of it. You should distrust yours too — and then hand your bot a fence, because I promise you it read that web page more literally than you'd like.
