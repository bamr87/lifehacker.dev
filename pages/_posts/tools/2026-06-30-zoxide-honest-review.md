---
title: "zoxide: the honest review"
description: "zoxide, the smarter cd: the package gives you nothing until you add the shell hook, it learns nothing in scripts, and the match rule that surprises everyone."
date: 2026-06-30
categories: [Tools]
tags: [productivity]
author: claude
verdict: "Install it and add the init hook — but it's a multi-week investment that does nothing until its database learns your dirs, and you keep plain cd for scripts"
excerpt: "The cd replacement that jumps by 'frecency'. Free. Verdict: a real upgrade that only pays off after it watches you for a week — learn the hook and the leaf-match rule first."
preview: /images/previews/section-tools.svg
permalink: /tools/zoxide-honest-review/
---
**Verdict: install it, add the one-line shell hook, and let it watch you for a week — then `z proj` beats `cd ../../../proj/whatever` forever.** `zoxide` is a smarter `cd`: it remembers the directories you visit and ranks them by "frecency" (frequency + recency), so a short keyword jumps you straight to the dir you meant. For *getting around a machine you live on* it's a genuine upgrade. The catches aren't price or telemetry — they're that the package alone does nothing, it learns nothing in scripts, and its matching has one rule that trips up everyone on day one. We use it daily. We also walked into all three while writing this, and they're in the box.

`zoxide` is free and open source (MIT). We have no relationship with the project and nothing to sell. Like its siblings [ripgrep](/tools/ripgrep-honest-review/), [fd](/tools/fd-honest-review/), [bat](/tools/bat-honest-review/), and [eza](/tools/eza-honest-review/), the dealbreakers here are defaults and ergonomics, not money. We'll show you exactly where, with output we actually captured on a fresh Ubuntu 24.04 box.

## Install — and unlike its siblings, the name is not a trap

```bash
brew install zoxide       # macOS
sudo apt install zoxide   # Debian/Ubuntu (24.04+)
```

A small relief after `fd`-is-really-`fdfind` and `exa`-is-dead: there's no naming collision here. The package is `zoxide`, the binary is `zoxide`, and the command you'll actually type is `z`.

```bash
$ apt-cache policy zoxide
zoxide:
  Installed: 0.9.3-1
  Candidate: 0.9.3-1
$ zoxide --version
zoxide 0.9.3
```

So far, so boring. The surprises start the moment you try to use it.

## Surprise 1: installing the package gives you no `z` command

This is the one that makes people think the install failed. After `apt install zoxide`, the `z` command does not exist:

```bash
$ type z
bash: type: z: not found
```

`zoxide` ships a binary, but the thing you actually want — `z` — is a *shell function* that the binary prints for you to wire in. You have to add one line to your shell rc and reload:

```bash
# ~/.bashrc  (or ~/.zshrc with `zoxide init zsh`)
eval "$(zoxide init bash)"
```

That `eval` defines the `z` function and, importantly, installs a hook that records every directory you `cd` into. Here's the top of what it generates, so you can see it's plain shell, not magic:

```bash
$ zoxide init bash | head -8
# =============================================================================
#
# Utility functions for zoxide.
#

# pwd based on the value of _ZO_RESOLVE_SYMLINKS.
function __zoxide_pwd() {
    \builtin pwd -L
}
```

No hook, no `z`. If you've ever pasted `apt install zoxide` and concluded "this tool does nothing," this is why: you installed the engine and never turned the key.

## Surprise 2: it learns nothing in scripts (and that's correct)

The hook that records your directories rides on the shell's prompt (`PROMPT_COMMAND` in bash). A prompt only fires in an *interactive* shell — so in a script, or in a `bash -c "..."`, the hook never runs and zoxide quietly learns nothing. Watch a non-interactive shell `cd` all over the place and end up with an empty database:

```bash
$ bash -c '
    eval "$(zoxide init bash)"
    cd /tmp/proj/frontend
    cd /tmp/proj/backend
    cd /tmp/proj/docs
    zoxide query --list --score
  '
$            # ← nothing. the db is empty.
```

This is the right call — you do *not* want directory history polluted by every CI job — but it has a corollary: **zoxide is an interactive-shell tool only.** Don't reach for `z` in a script; there's nothing to reach. The primitive the hook calls under the hood is `zoxide add <dir>`, which is also how we populated the database for the rest of this review without sitting here `cd`-ing by hand.

## Surprise 3: the cold start, where it's `cd` with extra steps

Even wired up correctly, on a fresh machine zoxide knows nothing. Hook on, database empty, ask it to jump and it can't:

```bash
$ bash -c 'eval "$(zoxide init bash)"; cd /tmp/proj/frontend; z backend'
zoxide: no match found
```

It only knows directories you've visited *since you installed the hook*. The payoff is real, but it is back-loaded: the first few days, `z` is `cd` that occasionally says "no match found." Give it a week of normal work and the database fills in. Once it has, a keyword is all you need — here it is after learning a handful of dirs (note the scores: `backend`, visited more, outranks the rest):

```bash
$ zoxide query --list --score
  12.0 /tmp/proj/backend
   4.0 /tmp/other/backend-tools
   4.0 /tmp/proj/frontend
$ bash -c 'eval "$(zoxide init bash)"; cd /tmp; z backend; echo "landed: $PWD"'
landed: /tmp/proj/backend
```

That's the whole pitch: from `/tmp`, `z backend` lands in `/tmp/proj/backend` because it's the highest-scored match. No relative-path archaeology.

## Surprise 4: the match rule everyone gets wrong on day one

Here's the one worth tattooing on your hand. zoxide is **not** a substring search over the whole path. The *last* keyword you give must match the **final component** (the leaf) of a remembered directory. Watch `proj` fail even though three tracked dirs contain `proj`:

```bash
$ zoxide query proj
zoxide: no match found
$ zoxide query front
/tmp/proj/frontend
$ zoxide query other back
/tmp/other/backend-tools
```

`proj` matches nothing because no tracked directory *ends* in `proj` — they all end in `frontend`, `backend`, `docs`. `front` works because a leaf starts with it. And earlier keywords (`other`) match anywhere earlier in the path, while only the last one (`back`) is anchored to the leaf. Once you internalize "type a piece of the folder you want to land *in*, optionally prefixed by a piece of its parent," it clicks. Until you do, you'll swear it's broken.

## The frecency tax: it can land you somewhere you didn't mean

The same ranking that makes `z` feel telepathic can also send you to the wrong twin. When two directories share a keyword, `z` silently picks the higher-scored one — great until the one you wanted today is the one you visit *less*. The fix is interactive mode, `z -i` (or `zi`), which lists the candidates and lets you pick. But — caveat — that picker is powered by [fzf](/tools/fzf-fuzzy-finder-honest-review/), and zoxide says so plainly if it's missing:

```bash
$ zoxide query -i
zoxide: could not find fzf, is it installed?
```

So the "disambiguate when it guesses wrong" escape hatch has a dependency. If you already run fzf (you should), `zi` is the answer to every "z sent me to the wrong place." If you don't, install it first, or you're stuck trusting the top-ranked guess.

## The good surprise: it cleans up after deleted dirs

Credit where due. A directory you delete doesn't haunt your jumps — zoxide filters paths that no longer exist out of both the listing and the jump:

```bash
$ zoxide add /tmp/proj/old-thing
$ zoxide query --list | grep old-thing
/tmp/proj/old-thing
$ rmdir /tmp/proj/old-thing
$ zoxide query --list | grep old-thing || echo "(gone from the list)"
(gone from the list)
```

You rarely need `zoxide remove`. Delete a project, and it stops showing up on its own.

## If you want `cd` itself to be the smart one

By default zoxide is additive: `cd` stays vanilla, `z` is the smart jump. If you'd rather make `cd` itself frecency-aware (so `cd back` fuzzy-jumps), init with `--cmd cd`, which redefines `cd` and adds `cdi` for the interactive picker:

```bash
$ zoxide init --cmd cd bash | grep -n 'function cd'
81:function cd() {
86:function cdi() {
```

We don't — keeping `cd` literal means muscle memory and scripts behave identically, and `z` stays the clearly-marked "do something clever" verb. But if you want zero new verbs to learn, this is the switch.

## Where plain cd still wins

`zoxide` is for a human moving around a machine they live on. `cd` is for everything else:

- **Scripts and automation.** `cd` is POSIX, deterministic, and on every box. zoxide learns nothing non-interactively anyway, so there is no reason — and no ability — to use `z` in a script.
- **A path you already know exactly.** `cd /etc/nginx` needs no database and never guesses. Frecency only helps when typing the full path is the annoyance.
- **A machine you don't control or freshly SSH'd into.** `cd` is always there with an empty-memory cost of zero. zoxide is an install plus a hook plus a week of learning before it earns its keep.

## What it costs and the free alternative

It costs nothing — open source, no account, no telemetry, no paid tier. The data lives in a small binary file (`db.zo`) under your data dir; nothing leaves your machine. The free alternative is the one already in your shell: `cd`, optionally with [a CDPATH or a couple of shell functions](/hacks/make-cd-remember-where-you-were/). The honest trade is *learned convenience* (short keywords, ranked by how you actually work) versus *zero setup and total determinism* (cd is there, now, everywhere, and never surprises you). They're a division of labor: let `z` move you around the dirs you live in, and keep `cd` for scripts and known paths.

A starter wiring for `~/.bashrc`:

```bash
eval "$(zoxide init bash)"   # defines z, installs the learning hook
# then work normally for a week; z fills in on its own.
# already running fzf? `zi <keyword>` picks when z guesses wrong.
```

## What made us close the tab

Nothing — `zoxide` is staying on every machine we type into by hand. The honest caveats, in the order they'll bite you:

- **The package alone does nothing.** No hook, no `z`. Add `eval "$(zoxide init bash)"` to your rc and reload, or you'll think it's broken.
- **It only learns in interactive shells, and only after install.** Useless in scripts (by design), and useless on day one — the database has to watch you work first. It's a multi-week payoff, not an instant one.
- **The last keyword matches the leaf, not the whole path.** `z proj` fails when everything is `proj/<something>`; type a piece of the folder you want to land *in*.
- **`z` guesses when keywords collide.** `z -i`/`zi` lets you pick — but that needs fzf installed.

**When it goes wrong:** if `z` says "command not found," you skipped the init hook. If it says "no match found" for a dir you *know* you've visited, either the database hasn't learned it yet (cold start) or your keyword didn't hit the leaf — try the final folder name. And if `z` keeps sending you to the wrong twin, that's frecency doing its job on stale data; use `zi` to pick, or visit the right one a few times and let the score climb.
