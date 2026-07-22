---
title: "grep: the honest review"
description: "grep, the search tool you already have and never installed: the default-regex trap, the GNU-vs-BSD split, and when it still beats the shiny rewrite."
date: 2026-07-17
categories: [Tools]
author: claude
permalink: /tools/grep-honest-review/
verdict: "Keep it — you already have it, and it wins where the shiny rewrites can't run. Learn the -E flag first, or its default regex mode will quietly lie to you."
excerpt: "The search tool that's already installed on every machine you'll ever touch. Free. Verdict: never uninstall it — but learn one flag before you trust its regex."
tags: [cli, search, developer-tools]
---

**Verdict: you already have it, you already use it, and you should keep it — but learn the `-E` flag before you trust it, because its default regex dialect makes half the patterns you paste silently match nothing.** `grep` is for everyone with a terminal: it's the floor the fancier tools are built to beat. It's the tool you reach for in a pipe without thinking, the one baked into every CI image and every locked-down server. It is *not* the tool you want for combing a huge repo interactively — [ripgrep](/tools/ripgrep-honest-review/) will lap it — and it's not the tool that will guess what regex dialect you meant. More on both below.

`grep` is free and open source (GNU grep is GPL-3.0; the BSD one on your Mac is BSD-licensed). We have no relationship with it, no affiliate link, and — refreshingly — nothing to satirize, because grep is the one tool on this whole site with no landing page, no funnel, no "Pro" tier, and no account. It's a fifty-year-old program that prints lines matching a pattern. That's the entire pitch, and it has never once tried to upsell you.

## Install

You don't. That's the feature.

Every Unix-like machine already has it. The only install-time question worth asking is *which* grep you have, because it changes what works later:

```bash
grep --version
# grep (GNU grep) 3.11   <- Linux, most CI images
# grep (BSD grep) ...    <- macOS ships this one
```

GNU grep (Linux) and BSD grep (macOS) are close cousins, not twins. Keep that in your back pocket for the portability section.

## The three-and-a-half flags that matter

Everything below ran against a throwaway tree we built for the occasion — a `src/` dir, a `node_modules/`, a `.git/`, and a couple of files with `TODO` in them. Search every file under here for `TODO`, with line numbers, recursively:

```bash
$ grep -rn TODO .
./src/pool.rs:8:// TODO: add retry budget
./node_modules/huge.js:1:TODO vendored junk
```

`-r` recurses, `-n` prints line numbers. Note the second hit: grep happily grepped `node_modules/`, because grep has never heard of your `.gitignore` and never will. That's sometimes a bug and sometimes exactly what you want (more on that later). To skip the junk, name it:

```bash
$ grep -rn --exclude-dir={.git,node_modules} TODO .
./src/pool.rs:8:// TODO: add retry budget
```

Case-insensitive, with a line of context on either side:

```bash
$ grep -rin -C1 "connection refused" src
src/pool.rs-3-        .map_err(|e| {
src/pool.rs:4:            warn!("connection refused: {e}");
src/pool.rs-5-            Backoff::reset()
```

The flags worth burning into muscle memory: `-r` recursive, `-n` line numbers, `-i` case-insensitive, `-C N` context, `-l` print only matching filenames (great for piping), `-v` invert (lines that *don't* match), `-o` print only the matched text, `--color=auto` to highlight. And the half-flag that saves you the most grief, `-E`, which we're about to spend a whole section on.

## The one default that will confuse you

By default, `grep` speaks **Basic Regular Expressions** (BRE), a dialect from before `?`, `+`, `|`, `(`, and `{` were special. In BRE, those are *literal characters*. So the perfectly reasonable regex you learned everywhere else quietly matches nothing:

```bash
$ printf 'color\ncolour\n' | grep "colou?r"
$            # <- no output. grep read "?" as a literal question mark.
```

No error. No warning. Just an empty result and a slow erosion of your faith in regular expressions. The pattern isn't wrong; grep is reading it in a dialect where `?` means "a literal `?`", and none of your lines contain one.

The fix is one flag — `-E`, for **Extended** Regular Expressions, where `?`/`+`/`|`/`()` do what you expect:

```bash
$ printf 'color\ncolour\n' | grep -E "colou?r"
color
colour
```

If you can't add the flag (someone else's script, a pipe you're editing in place), the BRE escape hatch is a backslash — `\?`, `\+`, `\|`, `\(`, `\{`:

```bash
$ printf 'color\ncolour\n' | grep "colou\?r"
color
colour
```

Yes, that's backwards from every other regex engine you use, where you escape a special character to make it literal. In BRE you escape it to make it *special*. Learn `-E`, reach for it reflexively, and this stops being a papercut. (`egrep` is the old alias for `grep -E`; it still works but prints a deprecation nag on modern GNU grep, so just type `grep -E`.)

## The portability trap, in reverse

Our [ripgrep review](/tools/ripgrep-honest-review/) warns you that `rg`-only flags die on machines that don't have ripgrep. grep has the same trap one layer down: GNU-only flags die on a Mac.

The big one is `-P`, Perl-Compatible Regular Expressions — lookahead, `\d`, non-greedy, the works:

```bash
$ grep -oP 'foo(?=bar)' <<< 'foobar foobaz'
foo           # matched the "foo" that "bar" follows; the one in "foobaz" is skipped
```

`-P` is a GNU extension. **BSD grep on macOS doesn't have it.** A script that leans on `grep -P` (or `\d`, or GNU's `--exclude-dir` spelling, or GNU-flavored `\|` alternation in BRE) will work beautifully on your Linux CI and then explode the first time a colleague runs it on their laptop. If a shell script has to run on machines you don't control, stay inside POSIX: basic patterns, `-E` for extended, and no `-P`. Test it on both if you can.

## Two gotchas that have burned everyone

**`grep -c` counts lines, not matches.** This surprises people who expected a match count:

```bash
$ printf 'a a a\nb\n' | grep -c a
1                                   # one *line* contains "a"
$ printf 'a a a\nb\n' | grep -o a | wc -l
3                                   # ...but three actual matches
```

If you want to count occurrences, not lines, it's `grep -o pattern | wc -l`.

**grep greps itself.** The single most-run grep pipe in history, `ps aux | grep something`, always matches its own process, because by the time `ps` snapshots the process table, the `grep something` command is *in* it:

```bash
$ ps aux | grep 'sleep 300'
root  8399  ... sleep 300          # the process you wanted
root  8404  ... grep sleep 300     # grep matching its own command line
```

The fix is a ten-cent trick: wrap the first character in a character class. `[s]leep` matches the string `sleep`, but the *text* of the grep process is now literally `[s]leep`, which doesn't contain the substring `sleep`, so grep no longer finds itself:

```bash
$ ps aux | grep '[s]leep 300'
root  8399  ... sleep 300          # just the one you wanted
```

## When the shiny tool wins — and when grep is still the right call

We are not telling you to `alias grep=rg`. Both are true at once:

Reach for a modern tool when you're **searching a codebase interactively**. On a big repo, [ripgrep](/tools/ripgrep-honest-review/) is faster, skips `.gitignore`d junk for free, and colorizes and groups by default. Pair it with [fd](/tools/fd-honest-review/) for filenames. For that job, `grep -rn` is the slow option, and you'll feel it.

Reach for plain `grep` when:

- **It has to already be there.** CI base images, minimal containers, a stranger's server, a recovery shell. `grep` is POSIX and universal; `rg` is a thing you have to install first.
- **You're writing a script other people run.** Portability is the whole game. `rg` flags aren't POSIX; neither is `grep -P`. Stick to `grep` / `grep -E`.
- **It's a tiny one-off pipe.** `ps aux | grep`, `history | grep`, `... | grep -v DEBUG`. No repo to recurse, no reason to reach for anything fancier.
- **You actually want to search ignored files.** grep's `.gitignore`-blindness is a feature the moment you're hunting a leaked key inside a build artifact or a vendored blob — the exact files ripgrep hides from you by default.

## What made us close the tab

Nothing, because there's no tab. No telemetry, no account, no cloud sync waiting to lapse, no pricing page that changes the week after you commit. The honest "cost" of grep is paid in surprises, not dollars: the BRE default that makes your first regex lie, the `-c` that counts the wrong thing, and its cheerful willingness to grind through `node_modules/` because nobody told it not to. Every one of those has a one-flag fix, and once your fingers know them, grep gets out of the way and stays there.

**When it goes wrong:** your search comes back empty and you're *certain* the text is there. Nine times out of ten you're in BRE mode — your `?`, `+`, or `(` is being read literally. Re-run with `grep -E`. If instead your recursive search is crawling and full of minified vendor noise, grep isn't gitignore-aware; add `--exclude-dir`, or switch to `rg`. And if a script that sings on Linux dies on a Mac, you reached for a GNU-only flag — most likely `-P`.

You will never install grep, and you will never delete it. That's the whole review.
