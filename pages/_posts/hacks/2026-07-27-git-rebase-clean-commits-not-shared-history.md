---
title: "git rebase -i cleans up your commits — and quietly rewrites the evidence"
description: "Squash wip commits with rebase -i, --fixup, and --autosquash — then the three ranked rules that keep a history rewrite from erasing your team's audit trail."
preview: /images/previews/git-rebase-i-cleans-up-your-commits-and-quietly-re.svg
date: 2026-07-27
categories: [Hacks]
tags: [git, security]
author: cass
excerpt: "Your git history is not a scratchpad. It's a signed, timestamped chain of who-changed-what — and rebase is a time machine that quietly files off the signatures."
permalink: /hacks/git-rebase-clean-commits-not-shared-history/
---
Somebody is going to read your commit history someday. Not the pretty summary — the actual log. A bisect chasing a regression. A security reviewer reconstructing when a bug was introduced. An incident channel at 3am asking "who touched auth on the 14th and did they mean to." Your git history is a signed, timestamped chain of custody, and `git rebase -i` is a time machine pointed straight at it.

Here is the scenario I lie awake on. You run one interactive rebase to tidy three `wip` commits before a review. It works. It feels great. Six months later an auditor pulls the log to prove a change was authored by who it says it was, and every signature on the commits you rewrote reads `Unverified`, because rebasing minted brand-new commit objects and left the original authors' cryptographic attestations behind in the reflog like shell casings. The change is now, in the ledger's eyes, authored by *you*, unsigned, at a timestamp that never happened.

**SEVERITY:** your compliance officer. **ATTACK VECTOR:** a tidy-up you did to look professional.

Now let me walk that back to the boring, true, useful version — because the boring version is the one you'll actually run this week, and rebase is genuinely one of the best tools git has. The danger isn't the command. It's *where you point it*. Rewrite commits that only exist on your laptop: bliss. Rewrite commits other people have already pulled: you've forged a shared record and handed everyone a merge conflict as a receipt.

Our earnest sister site has a whole quest on the upside — [Commit Hygiene: Crafting Clean, Atomic Commits](https://it-journey.dev/quests/0010/commitments-to-clean-commits/) over on it-journey.dev, where the commits are tidy and nobody is threat-modeling their own reflog. Go read that for the craft. Come back here for the part where it goes wrong.

Let's do the useful thing first, then rank the three rules that keep it from becoming the cinematic thing.

## The useful part: turn `wip, more wip, typo` into one honest commit

You've been committing like a person who intends to clean up later: `wip`, `more wip`, `typo`. Here's the real history I built in a throwaway repo to test all of this (git 2.54.0):

```console
$ git log --oneline
ab67dcc typo
e44be87 more wip
3788c46 wip
5624003 add feature
```

`git rebase -i` opens the *plan* for the last N commits in your editor — a to-do list, top-to-bottom, oldest first. This is what `git rebase -i --root` shows (use `--root` to include the very first commit; otherwise `git rebase -i HEAD~4` for the last four):

```console
$ git rebase -i --root
pick 5624003 # add feature
pick 3788c46 # wip
pick e44be87 # more wip
pick ab67dcc # typo

# Commands:
# p, pick   = use commit
# r, reword = use commit, but edit the commit message
# s, squash = use commit, but meld into previous commit
# f, fixup  = like squash, but discard THIS commit's message
# d, drop   = remove commit
# ...
```

Change the verb on the left, save, quit. To fold the three `wip` commits into `add feature` and keep only its message, mark them `fixup`:

```
pick  5624003 add feature
fixup 3788c46 wip
fixup e44be87 more wip
fixup ab67dcc typo
```

Save the file and git replays them into one:

```console
$ git rebase -i --root
Successfully rebased and updated refs/heads/master.

$ git log --oneline
4aadc56 add feature

$ cat app.py
line 1
line 2
line 3
line 4
```

Four commits became one; every line of work survived. Use `squash` instead of `fixup` if you want git to stop and let you write a combined message; use `reword` to fix a message without touching the code; use `drop` (or just delete the line) to erase a commit entirely. **You'll know it worked when** `git log` shows the collapsed history and your files are byte-for-byte what they were — the rebase changes the *story*, not the *tree*.

## The upgrade: mark the fix as you go with `--fixup`, sort it with `--autosquash`

Editing the to-do list by hand is fine for four commits. The scalable version: when you spot a bug that belongs to an earlier commit, don't write a fresh "fix login bug" commit — tag the correction to its target so git files it automatically later.

```console
$ git log --oneline
2ae9983 add logout handler
503ffa8 add login handler

$ git commit --fixup 503ffa8      # "503ffa8" = the commit this fixes
[master 376e9aa] fixup! add login handler

$ git log --oneline
376e9aa fixup! add login handler
2ae9983 add logout handler
503ffa8 add login handler
```

That `fixup!` prefix is a label, not magic — until you rebase with `--autosquash`, which reads the labels, reorders each `fixup!` directly under its target, and pre-marks it `fixup` in the plan for you:

```console
$ git rebase -i --autosquash --root
pick  503ffa8 # add login handler
fixup 376e9aa # fixup! add login handler
pick  2ae9983 # add logout handler
```

Notice git moved the fixup *up*, out of order, to sit under `add login handler` — the commit it belongs to — even though it was made two commits later. Save and quit and the correction melts into the commit it fixes, with no interleaved "oops" in the final history. Set `git config --global rebase.autosquash true` and `--autosquash` becomes the default; you'll never pass the flag again.

## When it goes wrong: the reflog is the undo you didn't know you had

Every rebase you've ever run is still recoverable, because git doesn't delete the old commits — it just stops pointing at them. `git reflog` is the local, private log of everywhere `HEAD` has been:

```console
$ git reflog -6
4aadc56 HEAD@{0}: rebase (finish): returning to refs/heads/master
4aadc56 HEAD@{1}: rebase (fixup): add feature
5e96255 HEAD@{2}: rebase (fixup): # This is a combination of 3 commits.
183b15b HEAD@{3}: rebase (fixup): # This is a combination of 2 commits.
5624003 HEAD@{4}: rebase: fast-forward
e1cae4a HEAD@{5}: rebase (start): checkout e1cae4a...
```

Botched a rebase? The pre-rebase tip is right there. Point a branch at it and you're back, every messy commit intact:

```console
$ git branch backup-before-rebase ab67dcc   # the old tip, from the reflog
$ git log --oneline backup-before-rebase
ab67dcc typo
e44be87 more wip
3788c46 wip
5624003 add feature
```

The reflog is your 90-day, local-only undo (it expires; `git config gc.reflogExpire` controls it). It is also the reason the "shell casings" from the intro exist — the rewritten-away commits linger, reachable, until git's garbage collector eventually reaps them. Good for recovery. Worth knowing before you assume a rewrite made anything *disappear*.

## The three rules, ranked for the threat that's actually in play

The threat here is not "rebase breaks your code" — it doesn't; the tree is preserved. The threat is **rewriting history other people depend on**: destroying a shared audit trail, forcing diverged histories on your teammates, and silently voiding commit signatures. Ranked by how much damage each one prevents.

### 1. Rewrite only what's still local. Never rewrite what you've pushed.

This is the whole game, and it demotes everything else to detail. A commit that lives only on your machine is a draft — rewrite it all you like. A commit you've pushed to a shared branch is *published*: other people have it, other work is built on it, CI has recorded it. Rebasing it doesn't edit that commit — it creates a **new** commit with a new SHA and orphans the old one, which is fine locally and a catastrophe shared.

Watch what a teammate inherits when you squash a commit they already pulled and force it up. `devA` rewrites shared history:

```console
# devA: squash "wip" into "add feature" on a branch already pushed, then force it
$ git rebase -i HEAD~2      # fixup the wip
Successfully rebased and updated refs/heads/master.
$ git push --force origin master
```

Meanwhile `devB` had committed real work on top of the *old* history and does an ordinary `git pull`:

```console
$ git pull --no-edit origin master
 + e799e72...c207992 master -> origin/master  (forced update)
Auto-merging f.txt
CONFLICT (content): Merge conflict in f.txt
Automatic merge failed; fix conflicts and then commit the result.

$ git log --oneline --graph
* 4fd5fab teammate work
* e799e72 wip           <- the commit you "deleted", still alive on their side
* 5b63aec add feature   <- the pre-squash version
* ce8a54d init project
```

You didn't clean up the history. You *forked* it: your squashed line and their original line now both exist, they collide on merge, and the "wip" commit you thought you erased is staring back at them. Multiply by a team and you've spent everyone's afternoon.

**Ranked #1** because it prevents the entire disaster class. The mechanical tell for "is this safe to rebase": has this commit ever left my machine? No → go wild. Yes → don't, or read rule #2.

### 2. If you *must* force-push a branch you own, use `--force-with-lease` — never bare `--force`.

Sometimes you legitimately rewrite a branch that's only yours (a feature branch mid-review) and have to force-push the tidy version. `--force` is a bulldozer: it overwrites the remote with your local ref *no matter what happened there since you last looked*. If a teammate pushed to that branch in the meantime, `--force` silently deletes their commit.

`--force-with-lease` is the same push with a dead-man's switch: it only overwrites if the remote is still where you last saw it. If it moved, the push is refused. Here `devY` pushed to the branch after `devX` last fetched, and `devX` tries to force a rewrite:

```console
$ git push --force-with-lease origin master
 ! [rejected]        master -> master (stale info)
error: failed to push some refs to '/tmp/lease.git'
```

Refused. `(stale info)` means "the remote moved under you — go look before you clobber." A bare `--force` would have accepted this push and vaporized `devY`'s commit without a word. Alias it so you can't forget: `git config --global alias.pushf 'push --force-with-lease'`. (One honest caveat: `--force-with-lease` compares against your last *fetch*, so a `git fetch` immediately before the push can re-arm the switch on someone else's change — the paranoid form is `--force-with-lease=<ref>:<sha>` naming the exact SHA you expect.)

**Ranked #2** because it can't save a shared `main` from rule-#1 damage — the wrong people already pulled — but for a branch that's genuinely yours, it's the difference between a clean rewrite and quietly deleting a colleague's work.

### 3. Know that rebasing voids signatures — re-sign, and verify the tree, not the vibes.

Here's the one nobody sees coming. If your team signs commits (`commit.gpgsign` / the "Verified" badge on GitHub), that signature covers a *specific commit object*. Rebasing builds new objects with new parents, so the old signatures cannot carry over — and unless your rebase is explicitly told to re-sign, the new commits come out **unsigned**. Watch it happen. Three signed commits (`G` = good signature):

```console
$ git log --format='%h %G? %s'
7b3d082 G typo
25d5958 G wip
ba0af6d G add feature
```

Squash them on a machine where signing isn't wired up, and:

```console
$ git rebase -i --root
Successfully rebased and updated refs/heads/master.

$ git log --format='%h %G? %s'
d81272e N add feature      <- N = no signature
```

Every attestation, gone, replaced by one unsigned commit under whoever ran the rebase. If those were a teammate's signed commits, you just stripped their name off the cryptographic record and stamped yours on the tree. The fix is one flag — `git rebase --exec 'git commit --amend --no-edit -S' ...`, or set `git config --global rebase.gpgSign true` — so re-signing is automatic, and then **verify** it landed with `git log --show-signature` instead of trusting the badge. Signatures are the one part of history that can't survive a rewrite by accident; they only survive on purpose.

**Ranked #3** because it only bites teams that sign at all — but for those teams a signed history is the actual audit trail, and an interactive rebase is the most common way it silently goes `Unverified`.

## The one-paragraph version

`git rebase -i` is the right tool for turning `wip, more wip, typo` into one honest commit — mark the extras `fixup`, or tag corrections with `git commit --fixup <sha>` and let `--autosquash` sort them, and lean on `git reflog` as your undo when it goes sideways. Then obey the ranking that keeps a cleanup from becoming an incident: **never rewrite a commit you've already pushed to a shared branch**; if you must force-push a branch that's yours, use `--force-with-lease`, never bare `--force`; and if your team signs commits, re-sign after rebasing and verify with `--show-signature`, because rewriting history voids every signature it touches. Rewrite the draft. Never rewrite the record. I'll be watching the log either way — I always am.
