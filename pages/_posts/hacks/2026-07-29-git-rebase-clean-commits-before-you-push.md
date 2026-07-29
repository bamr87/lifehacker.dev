---
title: "Clean your commits before you push, and treat the ones you've pushed as a crime scene"
description: "git rebase -i, --fixup and --autosquash squash 'wip, more wip, typo' into one clean commit — plus the rebase that becomes a duplicate-commit incident."
date: 2026-07-29
categories: [Hacks]
tags: [git, security]
author: cass
excerpt: "Rewriting local history is hygiene. Rewriting pushed history is an unauthorized modification of a shared system of record — and I have the reproduced incident to prove it. Squash cleanly, then land the three mitigations that keep the blast radius on your own machine."
preview: /images/previews/clean-your-commits-before-you-push-and-treat-the-o.svg
permalink: /hacks/git-rebase-clean-commits-before-you-push/
---

Your commit history is a log. A tamper-evident, cryptographically-chained, append-only log — the one artifact in your whole workflow that an auditor, a bisect, and a very annoyed future you all agree to trust. And you are about to rewrite it, on purpose, with a tool whose name is literally "re-base."

I want to be clear about what I think of that: **rewriting history is fine, right up until the history belongs to someone else.** Before you push, your commits are notes on your own machine — scribble, tear up, redo. After you push, those same commits are a shared system of record that other people have already pulled, branched from, and built on. Rewrite *that* and you're not cleaning up. You're issuing a silent, unauthenticated modification of everyone else's copy of the truth.

`SEVERITY: your teammate's entire Tuesday.`
`ATTACK VECTOR: git push --force to a branch someone else already pulled.`
`BLAST RADIUS: every clone. Yes, including the CI runner's.`

Spotted the useful half of this on it-journey.dev's [Commit Hygiene: Crafting Clean, Atomic Commits](https://it-journey.dev/quests/0010/commitments-to-clean-commits/) quest. This is the same workflow with the threat model bolted back on, and every command below run for real against `git version 2.54.0`.

## The good part: squashing "wip, more wip, typo" into one honest commit

Here is the history nobody wants their name on:

```console
$ git log --oneline
dfc385f typo
a9b0773 more wip
27581f7 wip
5113ed0 Add app
```

Three commits that should be one. `git rebase -i HEAD~3` opens an editor with a *plan* — one line per commit, oldest at the top, each starting with the word `pick`:

```console
$ git rebase -i HEAD~3
pick 27581f7 # wip
pick a9b0773 # more wip
pick dfc385f # typo

# Rebase 5113ed0..dfc385f onto 5113ed0 (3 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
#                    commit's log message
# d, drop <commit> = remove commit
# ...
# However, if you remove everything, the rebase will be aborted.
```

You don't type commands, you *edit the plan*. Change the last two `pick`s to `squash` (fold the commit in and keep its message for the combined edit) or `fixup` (fold it in and throw its message away). Leave the first as `pick`. Save, and git hands you one more editor to write the single combined message.

The result — three commits collapsed into one, with a message you actually chose:

```console
$ git log --oneline
9b0c87c Add feature()
5113ed0 Add app
```

**You'll know it worked when** `git log --oneline` shows one commit where three used to be, and `git status` says nothing about a rebase in progress. If instead it says `interactive rebase in progress`, git hit a snag and is waiting — `git rebase --abort` puts everything back exactly as it was. That escape hatch is not a footnote; it's the whole reason this is safe to practice.

## The precise part: `--fixup` marks the correction, `--autosquash` files it

Squashing by hand-editing a plan is fine for three commits in a row. It gets fiddly the moment the commit you need to fix is buried under later work. So you don't reorder by hand — you *label* the fix and let git reorder.

Say your branch is: `Add login form`, then `Add password reset`, and now you realize the login form needed input validation. Make the fix a normal change, then commit it as a *fixup pointed at the commit it belongs to*:

```console
$ git commit --fixup $(git rev-parse HEAD~1)
$ git log --oneline
5d70788 fixup! Add login form
eabb5b3 Add password reset
6321b0f Add login form
394c249 Initial commit
```

Note the commit message git wrote for you: `fixup! Add login form`. That `fixup!` prefix is a tag with a target's name on it. Now run the rebase with `--autosquash`:

```console
$ git rebase -i --autosquash HEAD~3
pick 6321b0f # Add login form
fixup 5d70788 # fixup! Add login form
pick eabb5b3 # Add password reset
```

Look at what `--autosquash` did *to the plan before you saw it*: it pulled the `fixup!` commit up directly under `Add login form` and pre-changed its verb to `fixup`. You just save. The fix folds into the right commit, and the unrelated `Add password reset` is left completely alone:

```console
$ git log --oneline
d25b27e Add password reset
2c01e7c Add login form
394c249 Initial commit

$ git show HEAD~1:login.py
def login(): pass
def validate(): pass
```

The validation now lives *inside* the login-form commit, as if you'd written it right the first time. **You'll know it worked when** the `fixup!` commit is gone and the target commit contains the change.

Want autosquash on by default so you never forget the flag? `git config --global rebase.autosquash true`. Convenience, and for once a convenience I endorse, because it changes nothing about *which* commits get rewritten — only how the plan is drawn.

### The part where the fold isn't free

Autosquash reorders commits, and reordering means git replays diffs in a new sequence. If your `fixup!` touches the same lines a commit between it and its target also touched, you get a real merge conflict mid-rebase:

```console
$ git rebase -i --autosquash HEAD~3
Rebasing (2/3)
Auto-merging f.txt
CONFLICT (content): Merge conflict in f.txt
error: could not apply 09b66f6... fixup! Add login form
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
```

This is not the tool betraying you; it's the tool refusing to guess. Fix the file, `git add` it, `git rebase --continue`. Or `git rebase --abort` and walk away unharmed. The conflict only exists *inside your own uncommitted rebase* — nobody else can see it, which is exactly the property we are about to lose.

## The crime scene: rewriting history you already pushed

Everything above happened on commits that never left my laptop. Now watch the identical tool become an incident when the commits have already been shared.

I push three commits. A teammate clones. Then I decide `Add y` needs a better message and reword it — a one-word "cleanup" on an *already-pushed* commit:

```console
$ git log --oneline
14be4b9 Add z
7b058b1 Add y
7757203 Add x
c747c70 Initial commit

$ git rebase -i HEAD~3      # reword "Add y"
$ git log --oneline
4f873be Add z
cc391b6 Add y (validation)
7757203 Add x
c747c70 Initial commit
```

Read those hashes carefully. I only *reworded* `Add y`, but **`Add z` got a new hash too** (`14be4b9` → `4f873be`). A commit's identity includes its parent, so rewriting any commit re-mints every commit after it. Every SHA from the edit point forward is now a stranger to the copy sitting in the shared repo.

Which the shared repo notices immediately:

```console
$ git push origin main
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '/tmp/origin.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart.
```

That rejection is git defending the log. This is the last moment before the incident — and the correct response is to *stop*. The tempting response is `--force`, which is the digital equivalent of "I know the alarm is going off, hand me the crowbar":

```console
$ git push --force origin main
 + 14be4b9...4f873be main -> main (forced update)
```

Meanwhile the teammate — who cloned the *old* history — did an honest day's work on top of the old `Add y` and runs `git pull`. Git dutifully reconciles the two versions of reality the only way it can: it keeps **both**.

```console
$ git pull --no-rebase origin main
Merge made by the 'ort' strategy.

$ git log --oneline --graph
*   8e6d7ea Merge branch 'main' of /tmp/origin
|\
| * 4f873be Add z
| * cc391b6 Add y (validation)
* | a2ae8ed Teammate: add work
* | 14be4b9 Add z
* | 7b058b1 Add y
|/
* 7757203 Add x
* c747c70 Initial commit
```

There it is. `Add y` and `Add z` now exist **twice** — the original pair and my rewritten pair — stitched together by a merge commit nobody asked for. Multiply that by a team, a CI cache, and a release tag pointing at a hash that no longer exists, and you have spent your afternoon and three other people's afternoons manufacturing a problem that did not exist before you "cleaned up." I have watched teams `git reset` their way out of this for an hour. The log stopped being trustworthy the instant two versions of the same commit became findable.

## The three mitigations that actually matter

The fear is the bit. This part is not a bit — each of these I ran during research, and each one keeps the blast radius on your own machine.

**1. Know the line, and never rewrite past it.** The only history you may rewrite is the history you haven't pushed. Git will tell you exactly where that line is — `@{u}` (upstream) is the last commit the shared repo has seen:

```console
$ git log --oneline @{u}..HEAD     # LOCAL-ONLY — fair game to rebase
6294b94 more wip
75f59f0 wip
```

Those two commits are yours alone; squash them into next Tuesday. Anything at or below `@{u}` has been published and is frozen. If a shared commit truly must be corrected, you don't rewrite it — you add a *new* commit (`git revert` for undoing, a follow-up commit for fixing) so the log stays append-only. Rewrite what's local; append to what's shared. This one rule prevents every incident above.

**2. When you must force, force *with a lease*.** `--force` overwrites the remote no matter what moved under you. `--force-with-lease` overwrites *only* if the remote is still where you last saw it — so if a teammate pushed in the meantime, it refuses instead of deleting their work:

```console
$ git push --force-with-lease origin main
 ! [rejected]        main -> main (stale info)
error: failed to push some refs to '/tmp/o2.git'
```

Plain `--force` would have silently dropped that teammate's commit. The lease caught it. Make `--force-with-lease` your muscle memory and let plain `--force` feel like reaching for the crowbar it is. (It is not bulletproof — a background `git fetch` can refresh the lease's idea of "last seen" — but it turns a silent overwrite into a loud stop, which is the entire job of a mitigation.)

**3. Assume you'll forget #1 and #2 — so lock the shared branch.** The mitigations that depend on human discipline fail on the day you're tired. Put the last line of defense on the server, where a bad `--force` gets rejected no matter who runs it. On a bare repo, that's one config key:

```console
$ git config receive.denyNonFastForwards true
$ git push --force origin main
remote: error: denying non-fast-forward refs/heads/main (you should pull first)
 ! [remote rejected] main -> main (non-fast-forward)
error: failed to push some refs to '/tmp/o3.git'
```

On GitHub/GitLab the same thing is branch protection: "do not allow force pushes" on `main`. The server refusing to be rewritten is the only mitigation that doesn't care how tired you are.

## And your undo, for when a *local* rebase goes sideways

None of the above helps if you botch a rebase on your own machine — wrong commits squashed, message eaten. Good news: every rebase saves your old tip in `ORIG_HEAD` before it touches anything. One command puts the world back:

```console
$ git reset --hard ORIG_HEAD
HEAD is now at 6ac4243 typo
```

The three "wip" commits I'd just squashed came back byte-for-byte — same tip hash as before I started. And even if `ORIG_HEAD` has moved on, `git reflog` is the local receipt of every position `HEAD` has ever held; the commit isn't gone, it's just unreferenced. (I distrust most safety nets. I trust the reflog, because it's append-only and it's on *my* disk — which, you'll notice, is the same reason I trust a commit log right up until someone rewrites it.)

Rewrite freely on your own machine. Publish once. Treat every pushed commit as evidence. The tool is the same either way — the only variable is whether the history you're editing is still only yours.
</content>
</invoke>
