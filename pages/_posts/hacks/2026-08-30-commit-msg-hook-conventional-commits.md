---
title: "The commit-msg hook that rejects 'update stuff' — and the --no-verify that strolls past it"
description: "A commit-msg hook that greps your subject line against Conventional Commits and bounces 'update stuff'. Plus the three ranked mitigations, because a local hook is a linter, not a lock."
date: 2026-08-30
preview: /images/previews/the-commit-msg-hook-that-rejects-update-stuff-and-.svg
categories: [Hacks]
tags: [git, security, ci-cd]
author: cass
excerpt: "A git hook that lives in .git/, never clones, and folds instantly to --no-verify is not enforcement. It's a mood board. Here's the hook anyway, and the three things that actually gate the commit."
permalink: /hacks/commit-msg-hook-conventional-commits/
---
Somebody just pushed a commit called `update stuff` to your default branch. I know because I've been threat-modeling your git history instead of sleeping, and the threat is coming from inside the house.

Here is the scenario I lie awake on. It is 4:55pm. A developer — let's call them the insider threat, because everyone with push access is one — stages 47 files across six unrelated concerns and types the first thing their hands remember: `git commit -m "more fixes lol"`. Eighteen months later a payment endpoint is quietly leaking, someone runs `git bisect`, and the log reads `fix stuff`, `wip`, `asdf`, `more fixes lol`, and `revert the revert`. The bisect lands on `asdf`. Nobody can tell whether `asdf` was the fix or the crime. A budget is approved. A consultant is flown in. The consultant also writes `asdf`.

**SEVERITY:** your own future self. **ATTACK VECTOR:** 4:55pm and a text box with no opinions.

Now let me walk that back to the boring true version, because the boring true version is the one that costs a Tuesday afternoon. You don't need a machine-learning model to catch `more fixes lol`. You need a regex and a hook that runs it before the message is allowed to become history. [Conventional Commits](https://www.conventionalcommits.org/) — `type(scope): summary`, the same `feat`/`fix`/`docs`/`chore` grammar this repo commits under — is a suggestion until something makes it a gate. Git ships the something. It's called `commit-msg`, and it is exactly as trustworthy as everything else that runs on your machine, which is to say: build it, use it, and never once believe it.

## The hook: 12 lines that grep your subject line

Git looks for an executable at `.git/hooks/commit-msg` and runs it on every commit, handing it one argument — the path to a temp file holding the message you just typed. Exit non-zero and the commit is aborted, message and all. So the whole job is: read the first real line, test it against a regex, exit 1 if it's garbage.

Drop this in `.git/hooks/commit-msg` and `chmod +x` it:

```bash
#!/usr/bin/env bash
# Reject commit subjects that aren't Conventional Commits.
# $1 is the path to the file holding the proposed message.
pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9._-]+\))?!?: .{1,}'

# First non-comment, non-blank line = the subject.
subject=$(grep -v '^#' "$1" | grep -v '^[[:space:]]*$' | head -n1)

if ! printf '%s' "$subject" | grep -qE "$pattern"; then
    echo "commit-msg: subject doesn't match Conventional Commits." >&2
    echo "  got:  $subject" >&2
    echo "  want: type(scope): summary   e.g. fix(auth): stop logging the password" >&2
    echo "  types: feat fix docs style refactor perf test build ci chore revert" >&2
    exit 1
fi
```

Two details that are load-bearing, not decoration. The `grep -v '^#'` matters because git's commit template is full of comment lines; skip them or the hook tests the wrong thing. And the trailing `.{1,}` matters because `fix:` with an empty summary is not a commit message, it's a shrug with a colon.

**You'll know it worked when** garbage bounces and grammar lands. I built a throwaway repo, installed the hook, and ran the four commits that decide whether this thing is real. Everything below is the actual captured output.

The lazy classics get rejected:

```console
$ git commit -m "update stuff"
commit-msg: subject doesn't match Conventional Commits.
  got:  update stuff
  want: type(scope): summary   e.g. fix(auth): stop logging the password
  types: feat fix docs style refactor perf test build ci chore revert

$ git commit -m "more fixes lol"
commit-msg: subject doesn't match Conventional Commits.
  got:  more fixes lol
  want: type(scope): summary   e.g. fix(auth): stop logging the password
  types: feat fix docs style refactor perf test build ci chore revert
```

Both exited `1`. Neither became a commit. A well-formed subject sails through:

```console
$ git commit -m "feat(parser): handle empty input"
[master (root-commit) 5bed0ed] feat(parser): handle empty input
 1 file changed, 1 insertion(+)
```

That's the entire happy path. The hook is twelve lines, it runs in single-digit milliseconds, and it will never again let you commit `asdf` by accident. Which is where the confidence should end, because I promised you a threat model and the threat model is that this hook protects nothing.

## The part where it protects nothing

Convenience features are attack surfaces with better marketing, and a git hook is the most convenient security theater in the building. Three things are true about the file you just wrote, and each one is a hole.

**It lives in `.git/`, so it never clones.** The `.git/hooks/` directory is local state. It is not tracked, not pushed, not pulled. Your teammate clones the repo and gets exactly zero of your hooks. I checked, because "surely git wouldn't" is how every incident review opens:

```console
$ git clone -q origin clone
$ if [ -f clone/.git/hooks/commit-msg ]; then echo "yes"; else echo "NO"; fi
NO — .git/hooks/ did not travel with the clone
```

So the enforcement you carefully installed applies to precisely one machine: yours. Everyone else on the team is still shipping `wip`, blissful and un-hooked. **SEVERITY:** the org chart.

**Anyone can walk straight past it with `--no-verify`.** The `-n`/`--no-verify` flag tells git to skip the hook entirely. It is not an exploit. It is a documented, first-class, one-keystroke bypass, and it works exactly as designed:

```console
$ git commit --no-verify -m "whatever i want"
[master 497363d] whatever i want
 1 file changed, 1 insertion(+)
```

Exit `0`. Committed. The hook didn't fire, didn't complain, didn't log. A control that the controlled party can disable by asking nicely is not a control. It's a suggestion with a speed bump, and the speed bump has a ramp.

**It runs whatever the repo tells it to run.** This cuts the other way, and it's the one nobody says out loud: a hook is just a script git executes on your behalf. Clone a stranger's repo, run a `make setup` that copies their hooks into place, and you have handed an unknown author code execution on your commit workflow. The paranoid posture isn't "install more hooks." It's "read the hook before you trust the hook," including this one. Especially this one.

So: a local `commit-msg` hook is a linter for an audience of one, defeated by a flag its own user holds. Useful. Not enforcement. Now here's what actually gates the commit.

## The three mitigations that actually matter, ranked

Ranked by what survives an adversary who has your keyboard and doesn't care, because that adversary is you at 4:55pm.

**1. Put the real check in CI, on the pushed commit.** This is the only one on the list that `--no-verify` can't touch, because it doesn't run on the committer's machine — it runs on the server, against history that already arrived. A CI job reads the actual commit subject and greps the same regex. I ran the sneaky commit through it:

```console
$ git commit --no-verify -m "sneaky: no-verify got me here"
$ subject=$(git log -1 --pretty=%s)
$ printf '%s' "$subject" | grep -qE "$pattern" && echo PASS || echo "FAIL: $subject"
FAIL: 'sneaky: no-verify got me here' is not a Conventional Commit
```

`sneaky` is not in the type list, so the check exits non-zero and the pipeline goes red on a commit that skated past every local hook. This is the lock. Everything above it in this post was the doorknob. Wire this into a required status check on the branch and the grammar stops being optional for anyone, on any machine, in any mood.

**2. Ship the hook *in* the repo via `core.hooksPath`.** You can't track `.git/hooks/`, but you can point git at a directory you *can* track. Commit your hooks to `.githooks/` and run one command:

```console
$ git config core.hooksPath .githooks
$ git config --get core.hooksPath
.githooks
$ git commit -q -m "feat: b"          # the tracked hook fires
shared hook ran
```

Now the hook is versioned, reviewable in a pull request, and identical for everyone who runs that one `git config` line (put it in your `make setup`, honestly documented — see mitigation 3's caveat). It still folds to `--no-verify`; that's fine. Its job isn't to stop the determined, it's to give the whole team the same fast feedback instead of one person's private lint. The it-journey.dev writeup that sent me down this hole, [*Commit Hygiene: Crafting Clean, Atomic Commits*](https://it-journey.dev/quests/0010/commitments-to-clean-commits/), frames this as team discipline; I'd frame it as reducing the number of machines whose hygiene you have to take on faith from "all of them" to "the CI runner."

**3. Keep the local hook — as feedback, not as a fence.** The twelve-line hook earns its place at the very bottom of the ranking, which is not an insult: it's the fastest loop you have. It catches your own typo in the millisecond before the commit exists, with no round-trip to a CI runner. That's real value. Just file it under "ergonomics" next to file under "security," and never let its green light talk you out of mitigations 1 and 2. A hook you trust is a hook that hasn't disappointed you *yet*.

## The one-line threat model to tape above your monitor

A git hook runs on the committer's machine, at the committer's pleasure, and travels with nothing. So it can improve behavior it cannot enforce it. If the commit grammar actually matters — for your changelog, your release automation, your `git bisect` six months from now — the enforcement has to live somewhere the committer doesn't control, which means the server. Write the hook for yourself. Write the CI check for everyone else. And when someone insists the hook alone is "basically enforcement," `--no-verify` is standing right there, holding the door, wondering why you locked it.

Reality was reached for comment and pushed `final_v2_ACTUAL.md` without a type prefix.
