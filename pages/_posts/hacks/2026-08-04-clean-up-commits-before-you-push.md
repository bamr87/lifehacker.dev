---
title: "Clean up your messy commits before you push — and never, ever after"
description: "Squash 'wip, more wip, typo' into one honest commit with git rebase -i and --autosquash, plus the one rule that keeps it from wrecking your team's history."
date: 2026-08-04
categories: [Hacks]
tags: [git]
author: cass
excerpt: "A commit SHA is a tamper-evident seal. Rebase doesn't edit history — it forges a new one and abandons the old. Do that to a branch someone pulled and you've run a history-rewrite attack against your own team."
preview: /images/previews/clean-up-your-messy-commits-before-you-push-and-ne.svg
permalink: /hacks/clean-up-commits-before-you-push/
---
Somebody, right now, is auditing your commit history. It's me. I read `git log` the way other people read horoscopes, and yours says `wip`, `more wip`, `wip fix`, `typo`, `typo again`, and — my favorite — `asdf`. Four of those are the same file. One of them is a debugging `print` you swore you deleted.

Here's the thing nobody tells you about a commit. That 40-character SHA is not a serial number the way a receipt has a serial number. It's a **content hash** — a cryptographic seal over the tree, the parent, the author, the message, the timestamp. Change one byte of any of it and the SHA changes into a completely different string. That's the property Git is built on, and it is genuinely a nice property: it makes history tamper-evident. You cannot quietly edit a commit. You can only forge a *new* commit and abandon the old one, and everyone can see the seal is different.

Which brings me to the scenario I lie awake on. You run `git rebase -i` to tidy your branch. It works beautifully. You force-push. Somewhere across the office, a teammate who pulled your branch this morning runs `git pull`, and their repository — which still trusts the old seals — dutifully welds your rewritten history onto their copy of the original. Now there are two commits called "add feature" with two different SHAs, a merge commit apologizing for both, and a Slack message that begins "hey quick question about main." A forensics team is dispatched. Somewhere, a budget is approved.

**SEVERITY:** your teammate. **ATTACK VECTOR:** `git push --force` on a branch someone else already pulled.

Now let me walk that back to the boring true version, because the boring true version is the one you can actually use every day without incident. Rewriting history is not dangerous. Rewriting history *that someone else already has* is the entire danger, and it's a bright, checkable line. Stay on the local side of it and `rebase -i` is the best cleanup tool Git has. Cross it and you're editing a shared ledger out from under the people relying on it. Let's do the safe part first, thoroughly, so the dangerous part is obvious by contrast.

*(This one's the security-persona angle on a commit-hygiene quest [spotted on it-journey](https://it-journey.dev/quests/0010/commitments-to-clean-commits/) — same rebase, read as an integrity problem.)*

Everything below is real output from throwaway repos I built for this post. Git version, for the record:

```console
$ git --version
git version 2.54.0
```

## The mess, and what `git rebase -i` opens

Here's a branch that tells the truth about how the work actually went:

```console
$ git log --oneline
ba643d4 typo
bbcb50a more wip
a85e3fd wip
5bd38dc add parser
```

`git rebase -i <base>` (interactive rebase) opens your editor with one line per commit, oldest at the top, and a menu of what you're allowed to do to each. Against the whole branch that's `git rebase -i --root`; more often it's `git rebase -i HEAD~4` or `git rebase -i main`. This is what lands in the editor:

```console
$ git rebase -i --root
pick 5bd38dc # add parser
pick a85e3fd # wip
pick bbcb50a # more wip
pick ba643d4 # typo

# Commands:
# p, pick <commit> = use commit
# r, reword <commit> = use commit, but edit the commit message
# e, edit <commit> = use commit, but stop for amending
# s, squash <commit> = use commit, but meld into previous commit
# f, fixup <commit> = like "squash" but discard this commit's log message
# d, drop <commit> = remove commit
#
# These lines can be re-ordered; they are executed from top to bottom.
```

You edit that list like a script. Change `pick` to `squash` to fold a commit into the one above it and combine both messages; `fixup` does the same but throws this commit's message away; `reword` keeps the change but lets you rewrite the message; `drop` deletes the commit entirely. Reorder the lines and the commits reorder. Save, close, and Git replays the list from the top.

So: fold the two `wip` commits into `add parser` (they're the same file, they don't deserve their own headstones), and reword `typo` into something a human would want to read. The result:

```console
$ git log --oneline
72114ec docs: add README
11f2c12 add parser
```

Four commits became two, and the two that remain describe what happened instead of when I gave up. Note the SHAs are all new — `5bd38dc` is gone, `11f2c12` took its place. Same code, different seal. That's the tell we come back to.

## `--fixup` + `--autosquash`: rewrite as you go, so you rewrite less

Interactive editing is fine for a one-time cleanup, but there's a slicker move for the common case: you're three commits deep and you notice a bug in an *earlier* commit. Don't make a "fix the login bug" commit that floats to the top of your branch like a cork. Mark it as belonging to the commit it fixes, at the moment you make it:

```console
$ git commit --fixup e59178f    # e59178f is the "add login" commit
$ git log --oneline
b6c8e61 fixup! add login
5e89226 add logout
e59178f add login
```

`--fixup <sha>` makes an ordinary commit whose message is literally `fixup! add login` — a label that says "I belong to `e59178f`." It's sitting in the wrong place right now (on top, after `add logout`). That's fine. When you're ready to clean up, `git rebase -i --autosquash` reads those labels and writes the todo list for you — reordering each fixup directly under its target and pre-marking it `fixup`:

```console
$ git rebase -i --autosquash --root
pick e59178f # add login
fixup b6c8e61 # fixup! add login
pick 5e89226 # add logout
```

You didn't reorder anything or type `fixup` yourself — the label did it. Save, and:

```console
$ git log --oneline
e608a4f add logout
2a5c1fd add login          # the fix is now baked into this commit

$ git log --oneline | grep -c 'fixup!'
0
```

Zero `fixup!` commits survive; the correction landed inside `add login` where it belonged. The security value here is subtle but real: the more you clean up *while the work is still local*, the smaller the window in which you're tempted to clean up after it's shared. Good hygiene shrinks the blast radius of the bad habit.

## The part where it breaks: rewriting history someone else has

Now watch the exact same `rebase -i` — the one that was pure hygiene a moment ago — turn into an incident, because this time the commits were already pushed. I set up a real remote, pushed two commits, and let a teammate clone them:

```console
$ git push -u origin main       # you push "add feature" + "wip fix"
$ # ...a teammate clones and now has both of those commits...
```

Then you "clean up" those already-pushed commits — squash `wip fix` into `add feature` — and your SHAs change, because of course they do; that's what a seal *is*:

```console
$ git rebase -i <base>          # fold "wip fix" into "add feature"
$ git log --oneline
274ec84 add feature
41ba194 init
```

Your history now disagrees with the remote's. Git catches it and refuses the push — this rejection is the last friendly warning you'll get:

```console
$ git push origin main
 ! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to '/tmp/shared-remote'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart.
```

Here's the fork in the road, and the wrong turn is the one that *feels* like progress. The rejection is annoying, and the internet is full of people telling you the "fix" is to add `--force`. So you force it, the remote takes your rewritten history, and everything looks perfect **on your machine**:

```console
$ git push --force-with-lease origin main
 + 1786b54...274ec84 main -> main (forced update)
```

Your problem is now solved and your teammate's problem is now created, and those are the same problem. They still have the *old* commits — the ones with the old seals. They run `git pull`, Git sees two histories that share the `init` ancestor but diverge after it, and it reconciles them the only way it can: it keeps both:

```console
$ git pull        # on the teammate's machine
Merge made by the 'ort' strategy.

$ git log --oneline --graph
*   57439c1 Merge branch 'main' of /tmp/shared-remote
|\
| * 274ec84 add feature        <- your rewritten version
* | 80008f8 wip fix            <- the old commit you thought you deleted
* | a27d708 add feature        <- ...and the old "add feature", still here
|/
* 41ba194 init
```

There it is. `add feature` appears **twice**, with two different SHAs. The `wip fix` you carefully squashed away is *back*. There's a merge commit stapling the two timelines together. Multiply this across a five-person team and every one of them re-introduces a slightly different copy of the history you rewrote, and now `main` is a hall of mirrors. Nothing here is corrupted in the data-integrity sense — every seal is valid — but the *shared meaning* of the branch is destroyed, which for a team is the same thing. The rebase didn't lie. You just ran it against a ledger other people were reading from.

## The three mitigations, ranked for the threat that's actually in play

The threat is not "rebase." The threat is "rebase applied to commits other people already have." So the mitigations are about knowing, precisely, which side of that line each commit is on.

### 1. Only ever rewrite commits you haven't pushed — and check, don't guess

This is the whole ballgame. Local commits are yours to forge, squash, reorder, and drop with total freedom, because no one else's repository trusts their seals yet. Pushed commits are a shared ledger. The line between them is not a vibe; it's a query you can run. Git tracks the remote's position as `@{u}` (the upstream of your current branch), so ask it exactly what's safe:

```console
$ git log --oneline @{u}..HEAD    # commits you have that the remote doesn't = safe to rewrite
1e1f95b local typo
1af05d3 local wip

$ git log --oneline HEAD..@{u}     # commits the remote has that you'd clobber
                                   # (empty output = you're clear)
```

The first command lists your unpushed commits — the ones with a `wip`/`typo` mess safe to clean up. Rebase back only as far as the oldest line in *that* list and you have physically not touched anything shared. The second command should be **empty**; if it isn't, the remote has moved and a rebase-then-push will fight it. Run these before every `rebase -i`. This is ranked #1 because it's the only mitigation that prevents the incident instead of apologizing for it.

### 2. Fix commits with `--fixup` as you go, so the cleanup happens while it's still local

The reason people rewrite shared history is almost never malice — it's that they didn't clean up *in time*, pushed a mess, and then tried to fix it in place. So move the cleanup earlier. When you spot a mistake in an earlier commit, `git commit --fixup <sha>` right then, and let `git rebase -i --autosquash` fold it in **before** you push (mitigation #1 confirms it's all still local). The correction never becomes a separate pushed commit you're later tempted to surgically remove. This is defense-in-depth: it doesn't make rewriting shared history safe, it removes your reasons to want to.

### 3. If you absolutely must rewrite shared history, use `--force-with-lease` and warn every human first

Sometimes it's unavoidable — a secret got committed, a branch is genuinely broken. When you truly must, never use bare `--force`. Use `--force-with-lease`, which refuses the push if the remote moved since you last fetched — so you can't silently stomp a teammate's commit you never saw:

```console
$ git push --force-with-lease origin main
 + 1786b54...274ec84 main -> main (forced update)
```

Here's the honest walk-back, and it's why this is ranked last: `--force-with-lease` is a seatbelt, not a fix. It protects against clobbering *new* work you didn't know about; it does **nothing** for the teammates who already pulled the old commits — they still get the duplicate-history mess above the instant they pull. The only thing that saves them is a human telling them, before they pull, to reset to the rewritten branch (`git reset --hard origin/main`) or re-clone. On a personal feature branch nobody else touches, force-with-lease is routine and fine. On a branch other people build on, the technical control is the easy part; the message in the group chat is the actual mitigation. Prefer a plain forward commit — `git revert` makes a *new* commit that undoes a bad one without rewriting any seals, and it's boring, and boring is the goal.

## The one-paragraph version

A commit SHA is a content seal, and `rebase` doesn't edit commits — it forges new ones and abandons the old. Locally that's the best cleanup tool you have: `git rebase -i` to squash `wip`/`typo` into honest commits, and `git commit --fixup <sha>` + `git rebase -i --autosquash` to file corrections under the commit they fix, automatically. The one rule that keeps it from becoming an incident: rewrite only what you haven't pushed, and *check* with `git log @{u}..HEAD` instead of guessing. Cross that line — rebase commits a teammate already pulled, then force-push — and everyone who pulls gets your history and the old history welded together, duplicate commits and all. If you truly must, `--force-with-lease` and a warning to every human involved; otherwise `git revert` and go home. I'll be here, reading your log. I always am.
