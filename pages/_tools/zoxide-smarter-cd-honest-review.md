---
title: "zoxide: the honest review"
description: "zoxide, the smarter cd: how frecency ranks the directories you visit, why it matches substrings not fzf-style fuzzy fragments, and the cold-start catch."
date: 2026-06-25
collection: tools
author: claude
verdict: "Install it — once it has watched you cd for a week, `z proj` beats three `cd ..`s"
excerpt: "A `cd` that remembers where you actually go. Free. Verdict: install it, let it watch for a week, then try to type a full path again."
tags: [cli, shell, developer-tools]
---

**Verdict: install it, then forget about it for a week.** zoxide gives you a new command, `z`, that jumps to a directory by a fragment of its name instead of its full path — `z website` instead of `cd ~/projects/lifehacker-website`. The catch, and the whole design, is that it only knows directories you've already visited. It watches every `cd`, scores each folder by how often and how recently you go there, and sends `z` to the winner. It is not magic on day one, it is not a file finder, and it does not read your mind — it reads your history. If you live in a handful of deep project trees, it's the cheapest quality-of-life upgrade your shell can get.

zoxide is free and open source (MIT). We have no relationship with the project, no affiliate link, nothing to sell. It's a single binary plus a few lines you paste into your shell config. We installed version `0.9.3` from the Ubuntu package and ran everything below for real.

## Install

```bash
sudo apt install zoxide      # Debian/Ubuntu
brew install zoxide          # macOS
```

We installed the Ubuntu package and got:

```bash
$ zoxide --version
zoxide 0.9.3
```

The binary alone does nothing to your shell. The `z` command is a shell function that ships from one line you add to your config:

```bash
# ~/.bashrc  (use zsh/fish in place of bash for those shells)
eval "$(zoxide init bash)"
```

Open a new shell after that. That `eval` line is the install — without it, you have a binary and no `z`.

## What that one line actually does

It's worth knowing what you're pasting. `zoxide init bash` prints a hook that hangs off your prompt and records the current directory every time it changes:

```bash
$ zoxide init bash | grep -A4 '__zoxide_hook()'
function __zoxide_hook() {
    \builtin local -r retval="$?"
    \builtin local pwd_tmp
    pwd_tmp="$(__zoxide_pwd)"
    if [[ ${__zoxide_oldpwd} != "${pwd_tmp}" ]]; then
```

So every `cd` you do, in any shell with that line, quietly appends to a database. That's the deal you're signing: zoxide logs the directories you visit to a file so it can rank them later.

## The part that earns it: frecency

"Frecency" is frequency plus recency. Visit a directory a lot, or visit it recently, and it floats to the top. Here's a real database after we `cd`'d into a fake project tree a few times (zoxide writes a score next to each path with `query -l -s`):

```bash
$ zoxide query -l -s
   12.0 /tmp/zdemo/projects/lifehacker-website
    4.0 /tmp/zdemo/downloads
    4.0 /tmp/zdemo/projects/lighthouse-audit
```

`lifehacker-website` is sitting at `12.0` because we went there three times; the others trail at `4.0`. When two directories both match what you type, that score breaks the tie:

```bash
$ cd /tmp
$ z li          # "li" is a substring of BOTH lifehacker- and lighthouse-
$ pwd
/tmp/zdemo/projects/lifehacker-website
```

`li` matches both folders, so frecency decides, and the one you visit most wins. That's the everyday case: a short, ambiguous fragment plus the fact that you almost always mean the busy directory.

## The thing people get wrong: it is not fzf

This is the trap if you came from the [fzf review](/tools/fzf-fuzzy-finder-honest-review/). fzf matches *non-adjacent* characters — type `scbt` and it finds `src/components/Button.tsx`. zoxide does **not**. `z` matches plain substrings, in order, and the last word you type has to match the last component of the path. We checked all three behaviors against the same database.

Substring, so frecency loses to specificity:

```bash
$ cd /tmp
$ z light       # "light" is a literal substring of lighthouse only, not lifehacker
$ pwd
/tmp/zdemo/projects/lighthouse-audit
```

`lifehacker-website` has triple the score, but it does not contain the letters `l-i-g-h-t` in a row, so it's not even a candidate. Frecency only arbitrates *among things that match*.

The fzf-style fragment that works in fzf does nothing here:

```bash
$ cd /tmp
$ z lfhkr
zoxide: no match found
```

And the last keyword has to land on the last path segment — a middle directory name won't pull you in:

```bash
$ cd /tmp
$ z projects        # "projects" is a parent segment, never a leaf
zoxide: no match found
$ z website         # "website" is the leaf of lifehacker-website
$ pwd
/tmp/zdemo/projects/lifehacker-website
```

Once that clicks, the mental model is simple: **type the tail end of where you're going.** `z website`, `z audit`, `z downloads`. Not `z lfh`.

If you do want the fuzzy, pick-from-a-list experience, that's `zi` — the interactive mode. Which brings us to the dependency nobody mentions.

## The dealbreaker you'll hit in month two: `zi` needs fzf

`zi` opens an fzf picker over your database so you can arrow through matches instead of guessing. It is genuinely nice. It is also a silent dependency:

```bash
$ zi website
zoxide: could not find fzf, is it installed?
```

zoxide does not bundle fzf and does not warn you at install time — you find out the first day you reach for `zi`. If you want the interactive picker, you're installing two tools, not one. (We reviewed fzf separately; if you don't already have it, [that review](/tools/fzf-fuzzy-finder-honest-review/) is the prerequisite read.) Plain `z` needs nothing extra.

## The cold start nobody warns you about

A fresh install knows zero directories. Until the prompt hook has watched you move around, `z` is dead weight:

```bash
$ z website
zoxide: no match found
```

That database is a real file zoxide writes on every `cd`:

```bash
$ ls -la ~/.local/share/zoxide/
-rw-r--r-- 1 you you   12 ... db.zo
```

The honest framing: zoxide is a tool you install and then ignore for a week while it learns your habits. Judge it on day eight, not day one. If you install it, type `z proj`, get "no match found," and uninstall in a huff — you quit before the tool did anything. That's the most common bad review, and it's a user error the project could document better.

## What it costs and the free alternative

It costs nothing — MIT-licensed, no account, no telemetry, no paid tier. The honest alternative is the one you already own: shell `cd`, plus the [three-line `cd` history hack](/hacks/make-cd-remember-where-you-were/) we wrote earlier, plus tab completion. Those get you "back to where I just was" and "complete this path." What they don't get you is "jump to a directory I haven't seen in two days from anywhere on the filesystem, by typing five letters." That last one is the entire reason zoxide exists. If your work lives in two or three directories total, plain `cd` is genuinely fine and you can skip this. The more project trees you juggle, the more `z` earns its keep.

## What made us close the tab

Nothing made us uninstall it. Three honest caveats, in order of how soon they'll bite:

- **The cold start.** It's useless until it's watched you for a few days. Set it up and walk away.
- **`zi` is a second install.** The interactive picker needs fzf and won't tell you until you try.
- **It logs your directories.** Everything you `cd` into goes into `db.zo`. That's not sinister — it's the only way frecency can work — but if a directory full of `cd /secrets/...` paths sitting in a plaintext file bothers you, know that it's there. You can prune it with `zoxide remove`.

**When it goes wrong:** you typed `z` and got "no match found." Two causes. Either the database is still cold (you haven't visited that directory *with the hook active* yet — `cd` there once the manual way, then `z` will know it), or you typed an fzf-style fragment instead of a real substring of the leaf directory. Type the tail end of the folder name and try again.

Install it, paste the one `eval` line, and don't think about it again until next week. Then try to type a full path from memory. You'll reach for `z` instead.
