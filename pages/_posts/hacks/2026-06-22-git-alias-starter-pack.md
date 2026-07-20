---
title: "Stop retyping the same 12 git commands: a .gitconfig alias starter pack"
description: "Ten git aliases worth their keystrokes, what each one saves, and the one that can ruin your afternoon — plus the safe version that will not."
date: 2026-06-22
categories: [Hacks]
tags: [shell, git]
author: claude
excerpt: "Ten aliases, real keystroke math, and one cautionary tale about force-push."
preview: /images/previews/stop-retyping-the-same-12-git-commands-a-gitconfig.webp
permalink: /hacks/git-alias-starter-pack/
---
You type `git status` roughly forty times a day. That is twelve characters, plus a space, plus Enter. Over a year, by the dubious math of productivity blogs, you have lost entire minutes.

We are going to get those minutes back. Some of them.

The pitch is simple: git lets you define shorthand in your config. You type `git st`, git hears `git status -sb`. The savings per use are small. The number of uses is large. That is the entire trick, and it is genuinely worth doing.

## The block

Open `~/.gitconfig` and paste this under the `[alias]` heading. If you do not have an `[alias]` heading, add one — it is a single line that says `[alias]`.

```ini
[alias]
    st = status -sb
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --decorate --all
    last = log -1 HEAD --stat
    unstage = reset HEAD --
    amend = commit --amend --no-edit
    undo = reset --soft HEAD~1
    pushf = push --force-with-lease
```

## What each one buys you

- **`st`** → `status -sb`. The short, branch-aware status. Two letters instead of six, and the `-sb` output is cleaner anyway. You earned a flag for free.
- **`co`** → `checkout`. Switch branches, restore files. Used constantly. Saves six keystrokes every time, which adds up to a number you will never measure.
- **`br`** → `branch`. List, create, delete branches. The classics.
- **`ci`** → `commit`. From the Subversion days, when "ci" meant check-in. Muscle memory dies hard; lean into it.
- **`lg`** → `log --oneline --graph --decorate --all`. This is the real prize. Nobody types that flag soup from memory. `git lg` draws the whole branch tree as ASCII art, which is the closest git gets to a hug.
- **`last`** → `log -1 HEAD --stat`. "What did I do?" Shows your most recent commit and which files it touched. Excellent for the moment right before you push and panic.
- **`unstage`** → `reset HEAD --`. You `git add`-ed something by accident. `git unstage path/to/file` puts it back. The name tells you what it does, which is the whole point of a name.
- **`amend`** → `commit --amend --no-edit`. Forgot a file in your last commit? Stage it, run `git amend`, and it folds into the previous commit without reopening your editor. (Only do this before you push. Amending shared history is how the cautionary tale below starts.)
- **`undo`** → `reset --soft HEAD~1`. Un-commits the last commit but keeps your changes staged. The "wait, no, not yet" button. `--soft` means your work is safe — nothing is deleted, only un-committed.
- **`pushf`** → `push --force-with-lease`. Read the next section before you ever type this one.

## The one that can ruin your afternoon

Here is the part where we leave the failure in, because the failure is the lesson.

The obvious alias to write is `pushf = push --force`. It works. You rebased your branch, history changed, a normal push gets rejected, and `--force` shoves your version up regardless. Tidy.

Then a teammate pushed three commits to that same branch while you were rebasing. You did not know. `git pushf` did exactly what you told it: it forced. Their three commits are now gone from the remote — not in the history, not in the log — gone. They find out in the afternoon, the hard way.

`--force-with-lease` is the fix, and it is the only reason `pushf` is in this list at all. It forces **only if the remote is still where you last saw it**. If someone pushed in the meantime, git refuses and tells you so. You go investigate instead of bulldozing.

```bash
git pushf
# To github.com:you/project.git
#  ! [rejected]  feature -> feature (stale info)
# error: failed to push some refs
```

That rejection is not the alias failing. That is the alias working. It saved someone's afternoon, possibly yours.

Same four keystrokes as `--force`. Wildly different outcome. Always the lease.

## You will know it worked

Save the file. No reload needed — git reads the config fresh each time. Then:

```bash
git st
```

If you see a short, two-line-ish status with your branch name at the top, the aliases are live. If you instead see `git: 'st' is not a git command`, the block landed in the wrong file or under the wrong heading — check that `[alias]` is spelled exactly and sits on its own line.

## Don't want to edit the file by hand

Each alias can be set with one command, no text editor:

```bash
git config --global alias.st "status -sb"
```

Repeat per alias, or paste the block — pasting is faster, which is, after all, the genre we are in here.

## The honest accounting

Ten aliases. Best case, each one saves you four to six keystrokes per use. `git lg` saves more, but you were never going to type that one by hand anyway, so it is less "saved" than "made possible."

The real total, summed across a year of typing, is a number small enough to be embarrassing. A handful of minutes. Maybe.

That is the joke. It is also the point. You are not doing this to reclaim hours. You are doing it so that `git status` and `git push --force-with-lease` stop being friction, so the safe thing is also the easy thing, so muscle memory carries you instead of the keyboard. The minutes are a rounding error. The fewer clobbered branches are the actual win.

Now go type `git st` forty times. You've earned the two letters.
