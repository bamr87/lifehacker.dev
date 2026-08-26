---
title: "Rebase your messy commits — before you push, never after"
description: "Squash 'wip, more wip, typo' into one commit with git rebase -i and --autosquash — plus the shared-history rewrite that diverges your whole team."
preview: /images/previews/rebase-your-messy-commits-before-you-push-never-af.jpg
date: 2026-08-05
categories: [Hacks]
tags: [git, security]
author: cass
excerpt: "git rebase -i is a time machine. The moment you point it at a commit someone else already pulled, it's a time machine that edits everyone's past but yours."
permalink: /hacks/git-rebase-clean-commits-before-you-push/
---
Somebody, right now, is reading your commit history. It's me. I threat-model version control graphs instead of sleeping.

Here is the scenario I lie awake on. You force-push a rebased branch at 6pm. By 6:04pm the rewritten commits have propagated to a build farm, three teammates' laptops, a CI cache in another timezone, and a mirror nobody remembers configuring. Somewhere a release tag now points at a commit that no longer exists. A three-letter agency, subpoenaing your repository for reasons you'd rather not know, receives two contradictory versions of the same "Add b" commit and concludes you are running a disinformation operation. A budget is approved.

**SEVERITY:** cinematic. **ATTACK VECTOR:** the word "just" in "I'll just clean up the history real quick."

Now let me walk that back to the boring true version, because the boring true version is the one that eats your Tuesday afternoon and a coworker's afternoon too.

`git rebase -i` is genuinely one of the good ones. It turns a branch full of `wip`, `more wip`, and `typo` into a single commit you'd be willing to sign your name to. The catch — the entire catch, the thing this whole post is about — is that rebasing does not *edit* commits. It *replaces* them with new commits that have new SHAs. Do that to history only you have, and it's housekeeping. Do it to history someone else has already pulled, and you have handed your team two parallel universes and told them to merge.

The useful thing is real. The danger is also real. Both stay in. (The clean-commits angle here was spotted on the sister site's [Commit Hygiene quest](https://it-journey.dev/quests/0010/commitments-to-clean-commits/); this is the paranoid edition.)

## The housekeeping: squash the wips into one honest commit

Everything below is real output. I built throwaway repos on the box that rendered this page and ran every command; the SHAs are whatever git actually generated. Start with the classic mess — four commits where three of them are noise:

```console
$ git log --oneline
362155b typo
f8b3eae more wip
30c4d2f wip
ce9a7b6 Add feature skeleton
```

`git rebase -i HEAD~3` opens the last three commits as an editable to-do list. This is the part that scares people, and it shouldn't — it's just a text file where the left column is a verb:

```console
$ git rebase -i HEAD~3
pick 30c4d2f # wip
pick f8b3eae # more wip
pick 362155b # typo

# Rebase ce9a7b6..362155b onto ce9a7b6 (3 commands)
#
# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup <commit> = like "squash" but discard this commit's log message
# d, drop <commit> = remove commit
```

Change the second and third `pick` to `squash` (meld them upward into the first), save, and git hands you one more editor to write the combined message. The three noise commits collapse into one:

```console
$ git log --oneline
18802ac Add feature
ce9a7b6 Add feature skeleton
```

Look closely: `ce9a7b6` (the commit I didn't touch) kept its SHA. The squashed commit is `18802ac` — a brand-new object. That is the whole security model of rebase in one line: **anything at or above the commit you edit gets a new identity.** Hold that thought; it's the villain in the third act.

## The mechanical version: --fixup, so you don't hand-edit anything

Hand-editing the to-do list is where you `drop` the wrong line at 6pm. The lower-adrenaline workflow: when you spot a bug in an earlier commit, don't reorder anything yourself — mark the fix and let git file it. Say you're deep in the signup work and notice the login commit is broken:

```console
$ git commit --fixup :/login
[main ff19be1] fixup! Add login handler
 1 file changed, 1 insertion(+), 1 deletion(-)

$ git log --oneline
ff19be1 fixup! Add login handler
ae3583b Add signup handler
d218e5c Add login handler
8380c39 Initial commit
```

The fix sits on top, stamped `fixup! Add login handler`, pointed at its target like a luggage tag. Keep working. When you're ready, `git rebase -i --autosquash` writes the to-do list *for* you — notice it has already hoisted the fixup up directly beneath the commit it belongs to, with the `fixup` verb pre-filled:

```console
$ git rebase -i --autosquash HEAD~3
pick d218e5c # Add login handler
fixup ff19be1 # fixup! Add login handler
pick ae3583b # Add signup handler
```

Save an unchanged file and the fix vanishes into `Add login handler` where it always should have been. No manual reordering means no manual reordering *mistakes*. (Set it as the default with `git config --global rebase.autosquash true`.)

## The part where it broke: rewriting history the team already had

Here's the failure I promised to leave in. I set up a shared "origin", pushed two commits, let a teammate clone them, and *then* rewrote one — the exact sin. I rebased to reword the already-pushed "Add b" commit, fixing its typo. The reword worked locally; its SHA changed from `a309611` to something new. Then I tried to push:

```console
$ git push origin main
 ! [rejected]        main -> main (non-fast-forward)
hint: Updates were rejected because the tip of your current branch is behind
```

That rejection is git protecting you. It noticed my history and the remote's history had *diverged* — same story, different SHAs — and refused. The correct response to this message is to stop and think. The 6pm response is `--force`, and I did it so you don't have to:

```console
$ git push --force origin main
```

The remote now has the rewritten "Add b". My teammate — who built "Add c" on top of the *old* "Add b" — knows none of this. They run a completely ordinary `git pull`:

```console
$ git pull origin main
Merge made by the 'ort' strategy.

$ git log --oneline --graph
*   be5d82d Merge branch 'main' of /tmp/share/origin
|\
| * f8aa9e1 Add b
* | ff844e3 Add c
* | a309611 Add b (tpyo in msg)
|/
* f4c22aa Add a
```

There it is. **The same change to `b` now appears twice** — once as my reworded `f8aa9e1 Add b`, once as the original `a309611 Add b (tpyo in msg)` that my teammate's branch was still standing on. Their innocent `pull` welded the two universes together with a merge commit. Multiply by a team, and you get an afternoon of untangling duplicate commits and a git graph that looks like subway wiring. Nobody attacked anyone. I just rewrote a commit that had already left the building.

## The three mitigations, ranked for the threat that's actually in play

The threat is not "rebase". Rebase is fine. The threat is *rebasing published history*. Rank the fixes accordingly.

### 1. Rebase only what you haven't pushed — and let git tell you what that is

This is the golden rule and it is the only mitigation that prevents the divergence disaster outright: **rewrite what's local, never what's shared.** The good news is you don't have to guess where the line is. `@{upstream}` (or `@{u}`) means "the remote branch you track", and one command lists exactly the commits that are yours alone — the safe-to-rebase set:

```console
$ git log @{upstream}..HEAD --oneline
59154f8 more wip
dd4da18 wip
```

Those two are unpushed: squash, reword, drop, reorder them to your heart's content. Everything from `origin/main` down is off limits, because someone else may be standing on it. If that command lists a commit you're about to rebase, don't. **Ranked #1** because it's the only item here that makes the other two unnecessary: obey it and the force-push scene above never happens.

### 2. Rewrite mechanically, and mark your exit before you start

Two seatbelts, both one command. First, prefer the `--fixup`/`--autosquash` flow from earlier over hand-editing the to-do list — the manual edit is where you `drop` the line you meant to `squash`. Second, before you touch anything, drop a bailout ref so the pre-rebase state has a name:

```console
$ git branch pre-rebase          # silent on success — pre-rebase now marks the tip, 30c5eb9
```

And if a rebase goes sideways *while it's running* — a conflict, or you just changed your mind — you are never trapped. `git rebase --abort` rewinds the whole thing as if you'd never started:

```console
$ git rebase -i HEAD~2
Stopped at c2eceda...  # Add f
$ git rebase --abort
  # HEAD is back at 30c5eb9, nothing rewritten
```

**Ranked #2** because it shrinks the odds of a botched *local* rebase, which is the only kind you should be doing anyway (see #1).

### 3. When you botched it anyway, ORIG_HEAD and the reflog are your undo

Say you finished a rebase, THEN realized you mangled it. The old commits are not gone — git almost never actually deletes objects. Before every rebase, git stamps the pre-rebase tip into `ORIG_HEAD`. Recovery from a bad *local* rebase is one command:

```console
$ git log --oneline          # after a squash you regret
938d8b3 Add f, cleaned up
17317e8 Initial commit

$ git reset --hard ORIG_HEAD
HEAD is now at e015129 more wip

$ git log --oneline
e015129 more wip
abf36a1 wip
4ab4639 Add f
17317e8 Initial commit
```

The three commits came back from the dead. If `ORIG_HEAD` has since moved (it gets overwritten by the next operation), `git reflog` is the full receipt of everywhere HEAD has ever pointed — find the `rebase (start)` line and `git reset --hard` to the entry just before it.

Now the honest walk-back, and it's why this is ranked last: the reflog is **local and per-clone**. It can resurrect a rebase *you* botched on *your* machine. It cannot reach into your teammate's clone and un-rewrite the commit they already pulled — that damage is done the instant you force-pushed, and no `reset` of yours touches their repo. Also, uncommitted changes were never in the reflog to begin with; a `reset --hard` eats them without ceremony. Mitigation #3 undoes your mistakes. It does not undo mitigation #1's.

## The one-paragraph version

`git rebase -i` replaces commits with new ones; treat it like a power tool, not a magic wand. Squash your `wip`/`typo` noise into honest commits, use `--fixup` + `--autosquash` so you're never hand-reordering a to-do list at 6pm, and above all run `git log @{u}..HEAD` first — if a commit you want to rewrite isn't in that list, it's already shared, and rewriting it forces everyone who pulled it into a diverged, duplicate-commit mess. Rewrite what's local. Never what's shared. If you slip, `git reset --hard ORIG_HEAD` will save you — on your own machine. It has never once saved your teammate. I've checked. I check everything.
