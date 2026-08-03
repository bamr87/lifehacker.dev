---
title: "Clean up your messy commits before you push: git rebase -i without detonating shared history"
description: "Squash 'wip, more wip, typo' into one commit with git rebase -i and --fixup/--autosquash — plus the blast-radius rule that keeps it off a shared branch."
date: 2026-08-03
categories: [Hacks]
tags: [git, shell]
author: cass
excerpt: "Your commit history is a crime scene, and 'wip', 'more wip', 'typo' are your fingerprints. git rebase -i cleans them — and the exact same command detonates a shared branch. Here's the interrogation, and the three mitigations that actually matter."
preview: /images/previews/clean-up-your-messy-commits-before-you-push-git-re.svg
permalink: /hacks/git-rebase-clean-commits-before-you-push/
---
Threat-model your commit history for a second. Every branch you push is a signed, timestamped confession of how you actually work, entered into a permanent record that your coworkers, your future employer's due-diligence team, and — in my more caffeinated moments — a bored nation-state adversary archiving all of GitHub can read at leisure. And the confession reads: `wip`. `more wip`. `wip 2`. `typo`. `actually fix the typo`. `please`.

I assume all of it is already compromised. That is not the interesting part. The interesting part is that `git rebase -i` — the tool that lets you rewrite that confession into one clean, defensible statement before anyone reads it — is *also* the tool that, pointed one commit too far, walks into a branch your teammate already pushed to and quietly overwrites their work. Same command. The safety is entirely in where you aim it.

So: `SEVERITY: your own history. ATTACK VECTOR: a rebase range that includes commits other people have already pulled.` Let me show you the clean version first, then the incident, then the three things that keep the incident theoretical.

Every block below was run for real against `git version 2.54.0` in a throwaway repo. The failures stay in, because the failures are the whole point.

## Squash the confession into one honest commit

Here is the crime scene. One real commit, then three that should never have existed as separate commits:

```console
$ git log --oneline
af311ed typo
b865a07 more wip
5b3ad41 wip
f953127 feat: add greeter
```

`git rebase -i HEAD~3` means "let me replay the last three commits and decide what each one becomes." It opens your editor with a todo list — the top is oldest, the bottom is newest:

```text
pick 5b3ad41 wip
pick b865a07 more wip
pick af311ed typo

# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the message
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup <commit> = like "squash", but discard this commit's log message
# d, drop <commit> = remove commit
```

Change the last two `pick`s to `squash` (or `s`) so they meld upward into the first, save, and git hands you one more editor to write the combined message. Set it to something a human would sign. The result:

```console
$ git log --oneline
6887a5f docs: add project notes
f953127 feat: add greeter
$ cat README.md
# notes
more
fix typo
```

Three commits became one. The *content* is byte-identical — the file has every line it had before. Only the story changed. That is the honest use of rebase: the code you tested is exactly the code you ship; you're editing the packaging, not the package.

## Mark the fix as you go: --fixup and --autosquash

Interactive squashing is fine for a tidy-up. But the move that scales is telling git *at commit time* which existing commit a change belongs to, and letting it file the paperwork later.

You've got a base, a `login` commit, and a `logout` commit. Then you notice `login` had a bug. Fix it, and instead of a fresh `fix login` commit, stamp it as a fixup *of* the login commit:

```console
$ git commit --fixup :/add\ login
$ git log --oneline
ef123f0 fixup! feat: add login
e05bd2f feat: add logout
a6500fa feat: add login
c36651d chore: init
```

That `fixup!` commit is a sticky note: "this belongs to `feat: add login`." Nothing has moved yet. When you're ready, `--autosquash` reads the sticky notes and pre-arranges the rebase todo list for you — the fixup gets reordered directly under its target and marked `fixup`:

```console
$ git rebase -i --autosquash HEAD~3
Rebasing (2/3)Rebasing (3/3)Successfully rebased and updated refs/heads/main.
$ git log --oneline
3ec18bb feat: add logout
be8c615 feat: add login
c36651d chore: init
```

The fix folded silently into `feat: add login`, out of order and all. No `fix the thing I broke two commits ago` in the permanent record. (Put `git config --global rebase.autosquash true` in your config and every interactive rebase does this automatically.)

Everything so far is safe because none of it left your laptop. Now the incident.

## The incident: rebase rewrites SHAs, and SHAs are identity

A rebase does not *edit* commits. It cannot — a commit's SHA is a hash of its content **and its history**, so changing anything upstream mints brand-new commits with brand-new SHAs. Your local `wip`/`more wip`/`typo` are not modified; they are abandoned, and three impostors take their place.

Nobody cares while it's local. The problem is `git push`. If those original commits were *already pushed*, and a teammate already *pulled* them, you and the remote now disagree about what `main` is — and a normal `git push` gets rejected because it isn't a fast-forward. The tempting fix is to force it. Watch what forcing actually does.

Developer A pushes two `wip` commits. Teammate B pulls, adds real work, pushes it. A — who cannot see B's commit — rebases the two already-pushed commits into one and reaches for `--force`. First, the *safe* force:

```console
$ git push --force-with-lease origin main
To /tmp/remote/remote.git
 ! [rejected]        main -> main (stale info)
error: failed to push some refs to '/tmp/remote/remote.git'
```

Rejected. `stale info`. That word — `stale` — is `--force-with-lease` doing its one job: it checked whether the remote still pointed where A *last saw* it point, found that it had moved (because B pushed), and refused. B's commit is untouched. That refusal is the entire happy ending.

Now the version without the seatbelt:

```console
$ git push --force origin main
To /tmp/remote/remote.git
 + 4679d95...172e4d9 main -> main (forced update)
```

`forced update`. That plus sign is B's `feat: teammate's real work` being deleted from the remote by someone who never even knew it existed. No conflict, no prompt, no error. B finds out at standup. `SEVERITY: your entire team. ATTACK VECTOR: the four extra characters you didn't type.`

This is the corner the it-journey.dev quest ["Commit Hygiene: Crafting Clean, Atomic Commits"](https://it-journey.dev/quests/0010/commitments-to-clean-commits/) points at from the tidy side; I'm pointing at it from the side where it bites.

## The three mitigations that actually matter

Not "be careful." Three specific, ranked, each one run above.

**1. Rewrite what's local, never what's shared.** This is the whole discipline and it's binary: has this commit ever left your machine? If no, rebase it into whatever shape you like. If yes — if it's on a `main` or a shared branch anyone else has pulled — it's evidence now, and you append (`git revert`, a new commit) instead of rewriting. The one honest exception is *your own* feature branch that only you use: rewrite it freely, because the only person you can inconvenience is you. Everything in the "squash the confession" and "--autosquash" sections above happened *before* the push. That ordering is the mitigation.

**2. If you must push a rewrite, `--force-with-lease`, never `--force`.** On a solo feature branch you will legitimately need to force-push a cleaned-up history. Make your muscle memory `--force-with-lease` — as shown, it refuses (`! [rejected] ... stale info`) the instant the remote moved out from under you, which is exactly the moment a plain `--force` would silently eat someone's work. Better still, set it as the default so you can't forget: `git config --global alias.pushf 'push --force-with-lease'`, and let `--force` rot from disuse.

**3. Arm a recovery point before you rebase.** A rebase you regret is not a disaster, because git saves your pre-rebase position in `ORIG_HEAD`. Squash something you shouldn't have? One command puts it all back, verified:

```console
$ git log --oneline
eee5633 wip: c
d30f924 wip: b
9b0ef0d wip: a
41ef652 chore: init
# ...rebase squashes the three wip commits into one you now regret...
$ git reset --hard ORIG_HEAD
$ git log --oneline
eee5633 wip: c
d30f924 wip: b
9b0ef0d wip: a
41ef652 chore: init
```

Restored exactly — same four SHAs. If `ORIG_HEAD` has already been overwritten by a later operation, `git reflog` is the longer receipt of everywhere `HEAD` has been; pick the entry from just before the rebase and `git reset --hard` to it. The catch, and it's a real one: this only protects *committed* work. A `reset --hard` throws away uncommitted changes for good, and no reflog brings those back — so commit (even as `wip`) before you start rewriting.

Do these three and rebase goes back to what it should be: a tool for turning a panicked confession into a clean statement, entirely on your own machine, where the only history you can rewrite is the history nobody's read yet. Which — given who I assume is reading — is a shrinking window. Squash fast.
