---
title: "Threat-model your merge conflict: the resolution that quietly deletes a coworker's commit"
description: "A git merge conflict is where a coworker's commit quietly dies. Read the markers, keep both sides, bail with --abort, and know why --ours flips in a rebase."
date: 2026-08-28
preview: /images/previews/threat-model-your-merge-conflict-the-resolution-th.svg
categories: [Hacks]
tags: [git, security]
author: cass
excerpt: "The markers aren't the emergency. The emergency is the reflex that 'resolves' a conflict by keeping your half and silently deleting theirs."
permalink: /hacks/git-merge-conflict-dont-delete-your-coworkers-work/
---
Somebody, right now, is deleting a coworker's committed work and calling it "resolving the conflict." It might be you. It might be in about four minutes.

Here is the scenario I lie awake on. A merge stops on `CONFLICT`. Seven angry lines of `<<<<<<<` and `>>>>>>>` appear in a file, the terminal turns the color of a smoke alarm, and a countdown starts in your head because the standup is in six minutes. So you do the thing. You delete the markers, keep the half that says what you wrote, stage it, commit, push. The build goes green. Everyone claps. Somewhere three commits back, a coworker's carefully-reviewed change — the one that added the CI runners to the firewall allowlist — has been quietly assassinated, and it will not resurface until the CI runners can't reach anything at 2 a.m. and the on-call engineer (also you) starts bisecting.

**SEVERITY:** insider threat. **ATTACK VECTOR:** the standup timer. **THREAT ACTOR:** you, six minutes ago, being efficient.

Now let me walk that back to the boring true version, because the boring true version is a `git blame` that points at your name on a line nobody remembers you touching.

A merge conflict is not an error. Git is not confused. Git is telling you, with the only vocabulary it has, that two commits changed the same neighborhood and it refuses to guess which human is right — because guessing wrong deletes work, and git has decided that's *your* liability, not its. The markers are a hand-off. The dangerous moment is not the conflict; it's the resolution, where a keystroke can drop a reviewed, committed, someone-else's change on the floor and leave zero trace in the diff you're about to approve. IT-Journey's [Git Workflow Mastery](https://it-journey.dev/quests/0001/git-workflow-mastery/) walks the happy path; this is the part where the happy path has a trapdoor.

I built a throwaway repo to trigger the trapdoor on purpose. Everything below is real captured output from it.

## The crime scene: two branches editing the same allowlist

The file is a firewall allowlist — the kind of thing where a silently-deleted line is a security incident, not a typo. On my branch I added the on-call laptop range. On my coworker's branch (`teammate`), they added the CI runner range. Same block, same commit region. Watch git stop:

```console
$ git merge teammate
Auto-merging allow.conf
CONFLICT (content): Merge conflict in allow.conf
Automatic merge failed; fix conflicts and then commit the result.
```

Here is what git actually wrote into the file. Read the markers like a sentence, because they are one:

```console
$ cat allow.conf
allow 10.0.0.0/24   # office
allow 10.0.5.0/24   # vpn
<<<<<<< HEAD
allow 10.0.7.0/24   # on-call laptops
=======
allow 10.0.9.0/24   # ci runners
>>>>>>> teammate
```

`<<<<<<< HEAD` down to `=======` is your side. `=======` down to `>>>>>>> teammate` is theirs. That much everyone knows. What everyone forgets under the standup timer is that these are not two *versions of the same line* — they are two *different lines*, both added, both real, both wanted. The conflict isn't "pick a winner." The conflict is "git can't tell that you want both."

## The mistake, in one command

Here is the reflex, and here is exactly what it costs. `git checkout --ours` sounds like "keep my changes." It does something more total: it throws away the entire conflicted file and replaces it with *your* whole side — every line of theirs in that hunk included.

```console
$ git checkout --ours allow.conf
$ git add allow.conf
$ cat allow.conf
allow 10.0.0.0/24   # office
allow 10.0.5.0/24   # vpn
allow 10.0.7.0/24   # on-call laptops
```

Clean. No markers. Looks resolved. Now watch the reviewed, committed work evaporate — this is the merged file diffed against what the teammate actually shipped:

```console
$ git diff --staged teammate -- allow.conf
diff --git a/allow.conf b/allow.conf
index 9a1bddf..9ef999d 100644
--- a/allow.conf
+++ b/allow.conf
@@ -1,3 +1,3 @@
 allow 10.0.0.0/24   # office
 allow 10.0.5.0/24   # vpn
-allow 10.0.9.0/24   # ci runners
+allow 10.0.7.0/24   # on-call laptops
```

The `-allow 10.0.9.0/24   # ci runners` is the murder weapon. Commit this and the teammate's change is gone from `HEAD` with a merge commit sitting on top of it that *says* their branch was merged. `git log` will show their commit is an ancestor. `git blame` will show their line is missing. Both are true. That's the part that ruins the afternoon: the history lies by omission and every tool agrees with it.

## Fix #1: turn on the conflict style that shows you the deletion before you make it

The reason the mistake is invisible is that the default markers hide the one fact that would stop you: what was there *before*. Turn on the three-way style and git shows you the common ancestor between a new pair of markers:

```console
$ git config --global merge.conflictStyle zdiff3
$ git merge teammate
$ cat allow.conf
allow 10.0.0.0/24   # office
allow 10.0.5.0/24   # vpn
<<<<<<< HEAD
allow 10.0.7.0/24   # on-call laptops
||||||| 86861b5
=======
allow 10.0.9.0/24   # ci runners
>>>>>>> teammate
```

Look at the section between `|||||||` and `=======`. It's **empty**. That emptiness is the whole ballgame: it means the base had *nothing* here, so both sides *added* a line to blank space. Neither is replacing the other. Keeping one side isn't choosing — it's deleting. When that middle section has content, you're genuinely picking between two edits of the same original and "keep mine" is a real answer. When it's empty, "keep mine" is a data-loss event wearing a resolution's clothes. `zdiff3` is the flag that makes the difference legible at a glance instead of forensically.

**Ranked #1** because it converts the silent failure into a visible one, on every conflict, forever, for the cost of one line in `~/.gitconfig`. (`zdiff3` needs git 2.35+; older git spells it `diff3`.) You cannot mitigate a threat you can't see, and this is the one that makes you see it.

## Fix #2: keep both, then prove there are no markers left in the file

With the deletion now visible, the resolution is boring, which is the goal. Both lines are real, so keep both — delete only the marker lines, leave the content:

```console
$ cat allow.conf
allow 10.0.0.0/24   # office
allow 10.0.5.0/24   # vpn
allow 10.0.7.0/24   # on-call laptops
allow 10.0.9.0/24   # ci runners
```

Before you stage anything, run the one check that catches a marker you missed — a stray `=======` left in a file is its own outage, and it is astonishingly easy to leave one in a big conflict:

```console
$ git diff --check
$ echo "exit: $?"
exit: 0
```

`git diff --check` scans for conflict markers (and whitespace crimes) and exits non-zero if it finds any. Zero means the file is clean. *Now* stage and commit. Verify the merge actually kept everyone's work — four ranges in, four ranges out:

```console
$ grep -c "allow " allow.conf
4
$ grep -E "ci runners|on-call" allow.conf
allow 10.0.7.0/24   # on-call laptops
allow 10.0.9.0/24   # ci runners
```

**Ranked #2** because "keep both, then `--check` before you stage" is the habit that turns a resolution from a guess into a verified fact. The check takes half a second and it has caught me leaving a marker in a file more than once.

## Fix #3: when the timer wins, bail — and know that --ours *flips* in a rebase

Sometimes you don't have the ten seconds to think. The correct move then is not to guess; it's to retreat. As long as you haven't staged anything, `git merge --abort` puts the working tree back exactly as it was, conflict un-happened:

```console
$ git merge --abort
$ git status -s
$ echo "exit: $?"
exit: 0
```

Clean tree, nothing lost, walk away and come back after standup. (`git rebase --abort` does the same for a rebase.) This is free and it is always available and there is no shame in it.

And here is the trap that turns the `--ours` shortcut from *merely* dangerous into actively treacherous: **during a rebase, `--ours` and `--theirs` mean the opposite of what they mean during a merge.** Not "sometimes." Every time. Here's the same kind of conflict, but reached through `git rebase main` instead of a merge — one branch set a timeout to 90, the other to 10:

```console
$ git rebase main
CONFLICT (content): Merge conflict in config.ini
$ cat config.ini
<<<<<<< HEAD
timeout = 10   # theirs: fail fast
||||||| parent of 1894cf7 (mine: bump timeout to 90)
timeout = 30
=======
timeout = 90   # mine: long-running job
>>>>>>> 1894cf7 (mine: bump timeout to 90)
```

Read `HEAD` carefully. In a merge, `HEAD` was *your* branch. In a rebase, `HEAD` is the branch you're rebasing *onto* — the other people's work — because a rebase replays *your* commits on top of theirs one at a time, so at each step "the current state" is their base plus whatever replayed so far, and your commit is the incoming patch. The labels follow that, ruthlessly:

```console
$ git checkout --ours config.ini
$ cat config.ini
timeout = 10   # theirs: fail fast
```

`--ours` just handed me `timeout = 10` — the *other* branch's value. The exact shortcut that kept my work in a merge threw it away in a rebase. The one that keeps my replaying commit here is `--theirs`:

```console
$ git checkout --theirs config.ini
$ cat config.ini
timeout = 90   # mine: long-running job
```

**Ranked #3** because `--abort` is your always-available safety, and the ours/theirs flip is the single most reliable way to delete your *own* work by muscle memory. The mitigation is a rule, not a command: never fire `--ours`/`--theirs` on reflex. Read the `>>>>>>>` marker — it names the commit each side belongs to — and decide from the names, not from the word "ours."

## The one-paragraph version

A merge conflict is git refusing to guess which human's committed work to delete, and handing you the liability. Turn on `merge.conflictStyle = zdiff3` so an empty base section warns you that both sides *added* a line and keeping one deletes the other. Resolve by keeping both when both are real, then run `git diff --check` before you stage so a stray marker doesn't ship. When the clock beats you, `git merge --abort` (or `git rebase --abort`) costs nothing and loses nothing. And burn one fact into memory above all the others: `--ours` and `--theirs` swap sides in a rebase, because `HEAD` is no longer you — so read the marker that names the commit, and never trust the word "ours." I threat-model firewalls for a living, and the call is still coming from inside the repo.
