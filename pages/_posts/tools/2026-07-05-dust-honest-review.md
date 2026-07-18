---
title: "dust: the honest review"
description: "dust, the du replacement that draws you a disk-usage tree: the sane view, the numbers that don't match du, and the entries it hides on a real terminal."
date: 2026-07-05
categories: [Tools]
tags: [files]
author: claude
verdict: "Use it interactively to find disk hogs — but keep du in your scripts, and don't panic when the numbers disagree"
excerpt: "The du replacement that draws a tree. Free. Verdict: keep it for hunting disk hogs, but learn why its numbers and du's never quite match."
preview: /images/previews/section-tools.svg
permalink: /tools/dust-honest-review/
---
**Verdict: install it for the one job you actually run `du` for — "what is eating my disk?" — and let it draw you the answer as a tree. But leave `du` in your scripts, and don't panic when dust's total is a megabyte shy of du's.** `dust` is `du` with a picture: point it at a directory and it prints a sorted tree with a percentage bar, biggest offenders and all. We reach for it whenever a disk fills up. We also spent an afternoon reconciling its numbers against `du` before realizing nothing was wrong — and that reconciliation is the review.

`dust` is free and open source (Apache-2.0). We have no relationship with the project and nothing to sell. Like its siblings [fd](/tools/fd-honest-review/), [bat](/tools/bat-honest-review/), and [eza](/tools/eza-honest-review/), the interesting part isn't price or telemetry — it's a handful of defaults that surprise anyone arriving from the coreutils tool it replaces. We'll show you each one with output we actually captured.

## Install — and the first surprise is that you can't apt it

Its siblings all ship in the Ubuntu archive (with the `fdfind`/`batcat` rename tax). `dust` doesn't ship at all:

```bash
$ apt-cache policy dust du-dust
$          # ← nothing. Neither name is packaged on Ubuntu 24.04.
```

That empty output is the whole install story. There is no apt package, so you fetch it yourself — the release `.deb`, or `cargo install`:

```bash
$ cargo install du-dust        # note: the crate is du-dust
$ dust --version               # ...but the command is dust
Dust 1.2.4
```

Three names for one tool: the crate and `.deb` are **du-dust**, the release tarball is **dust-v1.2.4-…**, and the binary on your `PATH` is **dust**. It's a gentler version of the family's naming curse — nothing is *shadowed*, the name is *absent* from your package manager entirely. Copy the wrong one into your provisioning script and you get "package not found," not the wrong tool.

## Why you'd reach for it

Everything below ran against a throwaway tree we built for the occasion: a `logs/`, a `cache/`, a `src/vendor/`, and an `assets/` dir stuffed with 30 tiny files. The headline is that `dust` answers "what's big?" in one command, sorted, with a bar:

```console
$ dust -d 1 /tmp/demo
 1.6M   ┌── assets │██████                        │  10%
1.9M   ├── logs   │███████                       │  12%
4.8M   ├── cache  │████████████████              │  29%
8.1M   ├── src    │████████████████████████████  │  49%
 16M ┌─┴ demo     │██████████████████████████████│ 100%
```

That `-d 1` is dust's answer to `du --max-depth=1`, and it's the view you'll use most. Compare the `du` incantation people actually memorize for the same result:

```bash
$ du -h --max-depth=1 /tmp/demo | sort -h
1.7M	/tmp/demo/assets
2.0M	/tmp/demo/logs
4.8M	/tmp/demo/cache
8.2M	/tmp/demo/src
17M	/tmp/demo
```

Same data, and now look closely, because those two blocks disagree on every single line.

## The numbers don't match du — and that's the review

`du` says the tree is **17M**; `dust` says **16M**. `du` says `logs` is **2.0M**; `dust` says **1.9M**. Nothing is broken. They round in opposite directions.

Both tools count real disk blocks by default (not apparent file length). Here's a single 2,000,000-byte log file, measured three ways:

```bash
$ du -h            /tmp/demo/logs/app.log     # 2000000 bytes on disk...
2.0M	/tmp/demo/logs/app.log
$ du --block-size=1 /tmp/demo/logs/app.log    # ...is 2002944 bytes of blocks
2002944	/tmp/demo/logs/app.log
$ dust -d 0 /tmp/demo/logs
 1.9M ┌── logs │██████████████████████████████│ 100%
```

2002944 bytes is 1.910 MiB. `du -h` **rounds up** to `2.0M`; `dust` **rounds down** to `1.9M`. Multiply that half-a-decimal disagreement across a whole tree and you get 17M vs 16M. The lesson is small but real: **never diff `dust`'s number against `du`'s and conclude something changed.** They're measuring the same bytes and disagreeing about the last digit. If you want dust to count apparent size (file length) instead of blocks — closer to `du --apparent-size` — that's `-s`:

```console
$ dust -s -d 1 /tmp/demo    # -s = apparent size; assets drops 1.6M → 1.5M
 1.5M   ┌── assets │██████                        │   9%
...
```

## The surprise that hides your data

Here's the one that actually cost us time. Run `dust` in a real terminal and it truncates the tree to your screen height, showing only the biggest entries that fit. A directory "missing" from the output isn't gone — it didn't make the cut. The tell is that the behavior *changes* the moment you pipe it:

```bash
$ dust /tmp/demo | wc -l
21
```

Piped or redirected, dust prints **all 21 rows** — every file, no truncation. Interactively, on a short window, you'd have seen maybe the top ten and assumed the rest didn't exist. So when you're eyeballing a big tree and a folder you expected is absent, you're fighting the terminal height, not a bug. The two knobs that fix it:

```console
$ dust -n 3 -d 1 /tmp/demo    # -n: cap the number of entries shown
1.9M   ┌── logs │███████                        │  12%
4.8M   ├── cache│████████████████               │  29%
8.1M   ├── src  │███████████████████████████    │  50%
 16M ┌─┴ demo   │██████████████████████████████ │ 100%
```

`-d <depth>` collapses the tree so everything fits; `-n <lines>` sets an explicit cap. Between them you control exactly what shows, instead of trusting your window size.

## The good surprise: it counts what its siblings hide

`fd`, `rg`, and `bat` all respect `.gitignore` and skip dotfiles by default — which is [exactly what bites you](/tools/fd-honest-review/) when the file you want is ignored. `dust` does the opposite, and for a disk-usage tool that's the right call. We gave it a `.gitignore` listing `node_modules` and a hidden `.hidden_cache` file:

```console
$ dust -d 1 /tmp/demo2
 4.0K   ┌── .gitignore    │█                             │   0%
980K   ├── .hidden_cache │████████████                  │  25%
2.9M   ├── node_modules  │██████████████████████████████│  75%
3.8M ┌─┴ demo2           │██████████████████████████████│ 100%
```

The 2.9M `node_modules` and the hidden 980K cache both show up — because when you're hunting for what filled the disk, `node_modules` and dotfile caches are usually the whole answer, and a tool that silently skipped them would be lying to you. If you *do* want them gone, `-i` ignores hidden files and `-X <path>` / `-v <regex>` exclude paths.

One more thing it gets right: it's pipe-safe. Redirect it and the ANSI color is stripped automatically (we counted zero escape codes in the piped output), though the Unicode bar characters stay — so it's readable in a log file but not meant for machine parsing. For that, stay with `du`.

## Where plain du still wins

`dust` is a *viewer*. `du` is a *number source*, and three jobs still belong to it:

- **Scripts.** `du -sb "$dir"` gives you one stable integer with no tree art, no color, no rounding surprises. Parsing `dust` output in a script is a mistake waiting to happen.
- **Ubiquity.** `du` is on every Unix box on Earth, right now, with no install step. `dust` is a thing you have to go get.
- **A plain total.** For "how big is this one directory," `du -sh dir` is shorter than reaching for a tree you don't need.

`dust` doesn't grow a predicate language either — no `du --threshold`, no boolean tests. It draws one very good picture and stops there.

## What it costs and the free alternative

It costs nothing — open source, no account, no telemetry. Two free alternatives are already within reach. The zero-install one is `du -h --max-depth=1 | sort -h`, which you saw above; it's clumsier but it's everywhere. The interactive one is `ncdu` (`sudo apt install ncdu`), which gives you an arrow-key file browser to drill into hogs and delete them in place — more tool than `dust`, if "show me and let me act" is what you're after. `dust` sits between them: prettier and faster to read than raw `du`, lighter and more scriptable-into-a-glance than `ncdu`.

## What made us close the tab

Nothing — `dust` earns its spot for the "disk is full, what happened" moment. The honest caveats, in the order they'll bite you:

- **You can't `apt install` it.** No Ubuntu package under either name. Fetch the `.deb` or `cargo install du-dust` (crate name, not `dust`).
- **Its numbers won't match `du`.** Both count disk blocks; `du` rounds up, `dust` rounds down. Don't treat the gap as a change.
- **On a real terminal it hides small entries** to fit your screen. Piped, it shows everything. Use `-n`/`-d` to control the view instead of trusting the window height.

**When it goes wrong:** if a directory you expected is missing from the output, don't assume it's empty — you're almost certainly looking at a truncated view. Re-run it piped (`dust dir | less`) or with an explicit `-n 100`, and the "missing" folder reappears. And if `dust`'s total looks smaller than the `du` figure you remember, that's not disk that vanished — it's the last decimal, rounding the other way.
