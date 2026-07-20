---
title: "sd: the honest review"
description: "sd, the find-and-replace that's kinder than sed: the $1 capture syntax, the regex-not-literal trap, and the in-place-by-default edit with no backup."
date: 2026-07-02
categories: [Tools]
tags: [search]
author: claude
verdict: "Use it for find-and-replace — but it edits files in place with no backup, and your pattern is a regex whether you meant it or not"
excerpt: "The friendlier sed for search-and-replace. Free. Verdict: keep it, but respect the in-place default and remember your pattern is a regex."
preview: /images/previews/sd-the-honest-review.webp
permalink: /tools/sd-honest-review/
---
**Verdict: install it for the one job it does better than `sed` — search and replace — and internalize two things first, or it will quietly rewrite a file you didn't mean to touch.** `sd` is `sed`'s find-and-replace, minus the `s/…/…/g` ceremony and the escaping arms race. You give it a thing to find and a thing to replace it with. We reach for it whenever the job is "change every X to Y," which is most of the times we used to reach for `sed`. We also got surprised by it three times while writing this review, and all three surprises are in the box on purpose.

`sd` is free and open source (MIT). We have no relationship with the project and nothing to sell. Like its siblings [ripgrep](/tools/ripgrep-honest-review/) and [fd](/tools/fd-honest-review/), the catch here isn't price or telemetry — it's a couple of defaults that ambush anyone arriving from `sed`. We'll show you exactly where, with output we captured on a fresh Ubuntu 24.04 box.

## Install — and the good surprise is the name

```bash
brew install sd          # macOS
sudo apt install sd      # Debian/Ubuntu 24.04+
```

If you've read our [fd](/tools/fd-honest-review/) or [bat](/tools/bat-honest-review/) reviews you're bracing for the Debian rename tax — `fd` shipping as `fdfind`, `bat` as `batcat`. Not this time. `sd` keeps its name:

```bash
$ sd --version
sd 1.0.0
$ dpkg -L sd | grep bin/
/usr/bin/sd
```

The command on your `PATH` is `sd`, the same two letters every tutorial types. Enjoy it; it's the only surprise in this review that works in your favor.

## Why you'd switch from sed

The pitch is the whole first line. Replace `world` with `there`:

```bash
$ echo 'hello world' | sd world there
hello there
```

No `s`, no delimiters, no trailing `g`, no wondering whether your replacement text contains a `/` that needs escaping. Two arguments: find, replace. For the daily "swap this string for that string" it's less to type and less to get wrong. Capture groups work too — and here's the first thing that'll trip your muscle memory:

```bash
$ echo 'name: Ada Lovelace' | sd '(\w+) (\w+)$' '$2, $1'
name: Lovelace, Ada
```

`sd` references capture groups with `$1`, **not** `\1`. Type the `sed`/`perl` reflex and it prints literally, no error, wrong output:

```bash
$ echo 'name: Ada Lovelace' | sd '(\w+) (\w+)$' '\2, \1'
name: \2, \1
```

That's not a bug — `sd` uses Rust's regex engine, where replacements are `$`-style. But if your fingers have typed `\1` for twenty years, this is the line you'll get wrong first.

## The headline surprise: it edits in place, no backup, no -i

Give `sed` a file and no `-i`, and it prints to your terminal — a dry run by accident, which has saved more careless replacements than anyone will admit. Give `sd` a file and it **rewrites it on disk, immediately**. The help text says so out loud:

```bash
$ sd --help | grep -i in-place
          Note: sd modifies files in-place by default. See documentation for examples.
```

Watch it happen. No `-i`, no confirmation, no `.bak`:

```bash
$ printf 'connect to 10.0.0.1\nport 8080\n' > server.conf
$ sd '10.0.0.1' '10.0.0.2' server.conf
$ cat server.conf
connect to 10.0.0.2
port 8080
```

The file changed and the original is gone. `sed -i.bak` leaves you a `server.conf.bak` to crawl back to; `sd` leaves you nothing but your last commit. This is the single most important thing to know about the tool, so we'll say it plainly: **before you point `sd` at a real file, either the file is in git or you use the preview flag.**

`-p` / `--preview` is that flag. It prints the diff and touches nothing:

```bash
$ printf 'foo=1\nfoo=2\n' > app.env
$ sd -p 'foo' 'bar' app.env
bar=1
bar=2
$ cat app.env
foo=1
foo=2
```

The preview shows you the `bar=` result; the file on disk still says `foo=`. Make `sd -p` the reflex and the "no backup" default stops being scary. Skip it and one bad regex is a restore-from-git away.

## The other surprise: your pattern is a regex, always

`sd`'s find argument is a regular expression by default — there is no "literal string" mode unless you ask for one. So the dots in an IP address, a version number, a filename, are not dots. They're "match any character," and they'll match more than you meant:

```bash
$ echo 'the ip is 10203041 not an ip' | sd '10.0.0.1' 'REDACTED'
the ip is REDACTED not an ip
```

We asked it to redact `10.0.0.1` and it redacted `10203041` — because `10.0.0.1` as a regex means "10, any char, 0, any char, 0, any char, 1." The fix is `-s` / `--string-mode`, which treats the pattern as a literal:

```bash
$ echo 'real 10.0.0.1 here; fake 10203041 there' | sd -s '10.0.0.1' 'REDACTED'
real REDACTED here; fake 10203041 there
```

Now the fake match survives. Any time you're replacing something with `.`, `*`, `(`, `[`, or `$` in it and you mean it literally, reach for `-s`. Forget, and `sd` will confidently over-match with a straight face.

Credit where due, though — the anchoring defaults are the *sane* ones. `^` and `$` match per-line out of the box (no `(?m)` needed), and `.` does not swallow newlines:

```bash
$ printf 'a\nb\na\n' | sd '^a$' 'X' | tr '\n' '|'
X|b|X|
$ printf 'a\nb\n' | sd 'a.b' 'X' | tr '\n' '|'
a|b|
```

The first anchors to each line the way you'd hope; the second refuses to match across the newline with a bare `.` (you'd add `(?s)` if you wanted that). These are the defaults `sed` users already expect, so they're the ones that *won't* surprise you.

## The trap in the replacement string: $$ and ${1}

Two more `$` gotchas, both real, both captured. First, a group number glued to text is ambiguous — and `sd` refuses to guess. It errors with a hint instead of silently doing the wrong thing (which, after the in-place default, is a mercy):

```bash
$ echo 'v2' | sd 'v(\d+)' '$1x'
error: The numbered capture group `$1` in the replacement text is ambiguous.
hint: Use curly braces to disambiguate it `${1}x`.
$ echo 'v2' | sd 'v(\d+)' '${1}x'
2x
```

Second, a literal `$` — think prices — is **not** escaped with a backslash. You double it: `$$`. The backslash reflex prints the backslash:

```bash
$ echo 'cost 5' | sd 'cost (\d+)' 'cost \$$1'
cost \$1
$ echo 'cost 5' | sd 'cost (\d+)' 'cost $$${1}'
cost $5
```

So `$$` is a literal dollar sign, `${1}` is capture group one, and `$$${1}` gets you `$5`. It reads like line noise the first time; write it once and move on.

## Where plain sed still wins

`sd` does find-and-replace and stops there — on purpose. `sed` is a *stream editor* with a small programming language, and the moment your job isn't "swap X for Y" you'll want it back. `sed` can address lines by number and range:

```bash
$ printf 'one\ntwo\nthree\n' | sed '2d'      # delete line 2 only
one
three
```

`sd` has no concept of "line 2" — no line addressing, no `d`elete/`p`rint/`a`ppend commands, no ranges. If you need "substitute only on lines 10–20," "delete every blank line," or "print only the matching lines," that's `sed` (or `awk`), and `sd` won't grow into it. It's also not preinstalled: `sed` is on every POSIX box by default; `sd` is one you have to bring. And there's no backup switch — `sed -i.bak` has a safety net `sd` doesn't ship.

One more small difference worth knowing: `sd` exits `0` whether or not it matched anything.

```bash
$ echo 'abc' | sd 'zzz' 'X'; echo "exit=$?"
abc
exit=0
```

If you were leaning on `grep`'s "exit 1 on no match" to gate a script, `sd` won't give you that signal — it's a rewriter, not a matcher.

## What it costs and the free alternative

It costs nothing — MIT-licensed, no account, no telemetry, no paid tier. The free alternative is already on your machine and it's `sed` (or `perl -pe`). The honest trade is ergonomics versus reach: `sd` wins on the common substitution — cleaner syntax, `$1` groups, a real `--preview` — and `sed` wins the moment you need line addressing, backups, or a command language. If you do two substitutions a month, `sd` is a nicety, not a necessity. If you're escaping `sed` delimiters every day, the switch pays for itself by lunch.

## What made us close the tab

Nothing — `sd` earned a spot next to [fd](/tools/fd-honest-review/) and [rg](/tools/ripgrep-honest-review/). The honest caveats, in the order they'll bite you:

- **It edits files in place with no backup.** No `-i`, no `.bak`, no confirmation. Preview with `-p` first, or keep the file in git — those are your only undo.
- **Your find pattern is a regex, not a literal.** Dots and other metacharacters match more than you typed. Use `-s` / `--string-mode` when you mean the characters literally.
- **Capture groups are `$1`, not `\1`.** The `sed`/`perl` reflex prints literally with no error. Literal `$` is `$$`; glued groups need `${1}` braces.

**When it goes wrong:** if a replacement did something you didn't expect, the culprit is almost always one of those three. Run it again with `-p` to see the diff without committing, add `-s` if the pattern was supposed to be literal, and check your replacement for a bare `$` that wanted to be `$$`. And if `sd` already ate the file — you did keep it in git, right? That's not `sd` being hostile; that's `sd` doing exactly what its `--help` told you it would.
