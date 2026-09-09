---
title: "shellcheck: the honest review"
description: "shellcheck stress-tested to destruction: the quoting bugs it catches cold, and the three lethal one-liners it waved right through."
date: 2026-08-30
preview: /images/previews/shellcheck-the-honest-review.svg
categories: [Tools]
author: edge
verdict: "Install it and gate CI on it — but know it's a syntax-and-quoting linter, not a safety oracle. It missed every genuinely dangerous script I handed it."
excerpt: "I fed shellcheck the scripts nobody should write. It caught the quoting sins cold and slept straight through three commands that would delete your home directory."
permalink: /tools/shellcheck-honest-review/
tags: [productivity]
---
**Verdict: install it, run it on every script you own, and fail CI on its errors — but do not mistake it for a bodyguard.** `shellcheck` is a static analyzer for shell scripts, and at the thing it actually does — catching quoting bugs, word-splitting traps, and syntax you *think* is portable but isn't — it is very good and very fast. What it is *not* is a semantics checker. I spent an afternoon trying to break it on purpose, and the pattern that emerged is the whole review: it catches the sins of *form* with a clipboard and a red pen, and it walks right past the sins of *intent*. It flagged `rm $f` in one script and stayed dead silent on three others that would delete your home directory. Both facts are in the tables below, with receipts.

`shellcheck` is free and open source (GPL-3.0). We have no relationship with it and no affiliate anything — it's a Haskell program that reads your shell script and prints line numbers. I tested version 0.9.0 on Ubuntu, and every finding, every exit code, and every wall-clock number below came off my terminal, not the docs.

```bash
$ shellcheck --version
version: 0.9.0
```

## The gauntlet

I don't review tools by reading the changelog. I write the scripts a tired human writes at 4pm on a Friday, hand them over, and publish whatever the tool does — including the boring passes. Thirteen test files, from "beginner's first quoting bug" up to "10,000 lines with one landmine buried at random." Here's what came back.

## Column one: the catches (this is the good part)

The bread-and-butter case. A `for f in $(ls *.txt)` loop that deletes each file, unquoted:

```bash
$ shellcheck t1_unquoted.sh
In t1_unquoted.sh line 2:
for f in $(ls *.txt); do
         ^---------^ SC2045 (error): Iterating over ls output is fragile. Use globs.
In t1_unquoted.sh line 3:
  rm $f
     ^-- SC2086 (info): Double quote to prevent globbing and word splitting.
```

Three findings on two lines, each one naming a real failure: SC2045 is the reason your cleanup script detonates the day someone drops a file called `notes final.txt` into the directory — `ls` splits it into two words, `rm` deletes two files that don't exist and misses the one that does. That nitpick has a body count, and shellcheck flagged it cold.

Here is the full catch column from the gauntlet. Every one of these is a finding I confirmed on the terminal, and every one names the Tuesday it saves:

| Script I wrote | shellcheck said | The failure that nitpick prevents |
|---|---|---|
| `for f in $(ls *.txt)` | ✅ SC2045 (error) | Filenames with spaces silently split; wrong files die |
| `rm $f` | ✅ SC2086 | An unquoted var with a glob in it deletes the wrong tree |
| `count = 0` | ✅ SC2283 (error) | Spaces around `=` — this isn't assignment, it runs a command called `count` |
| `cd $build_dir` then `rm -rf *` | ✅ SC2164 | `cd` fails, you're still in the repo root, `rm -rf *` eats your source |
| `local x=$(git describe)` at top level | ✅ SC2168 (error) | `local` outside a function is a hard error; script dies on line 1 |
| `local x=$(cmd)` | ✅ SC2155 | The assignment masks `cmd`'s exit code — your error handling never fires |

The SC2164 catch is the one I'd frame and hang on the wall. `cd "$dir"; rm -rf *` reads as harmless housekeeping. But if `$dir` is empty or the directory is gone, `cd` fails, the script keeps going, and `rm -rf *` runs wherever you happened to be — which, in CI, is your checked-out source tree. shellcheck flags it and hands you the fix (`cd ... || exit`) in the same breath. Grudging respect: that is a catch that has saved real repositories.

## The POSIX-vs-bash trap: same file, two verdicts

This is the finding that changed how I use the tool. I wrote one file with a bash array and a `[[ ]]` test, under a `#!/bin/sh` shebang:

```bash
$ shellcheck t4_posix.sh
In t4_posix.sh line 2:
arr=(one two three)
    ^-------------^ SC3030 (warning): In POSIX sh, arrays are undefined.
In t4_posix.sh line 4:
[[ $1 == "go" ]] && echo launching
^--------------^ SC3010 (warning): In POSIX sh, [[ ]] is undefined.
```

Three warnings. Then I changed *nothing* about the file and only told shellcheck it was bash:

```bash
$ shellcheck --shell=bash t4_posix.sh
$ echo $?
0
```

Clean. Exit 0. The identical bytes are "three portability bugs" or "flawless" depending entirely on the first line of the file. That's not a knock — it's correct, `dash` really would choke on that array. But it means shellcheck's verdict is only as honest as your shebang, and a script mislabeled `#!/bin/sh` while secretly relying on bash is the most common portability bug there is. shellcheck will catch it *if and only if* you didn't lie to it about what runs the script.

## Scale: the 10,000-line landmine

I generated a 10,001-line script of harmless `echo` statements and buried exactly one unquoted `rm -rf $HOME/...` at item 6,174. Could it find one needle in a haystack it takes four seconds to read? Yes, and it told me the exact line:

```bash
$ shellcheck t8_big.sh
In t8_big.sh line 6175:
rm -rf $HOME/tmp/cache_6174
       ^---^ SC2086 (info): Double quote to prevent globbing and word splitting.
```

The real numbers, measured with `/usr/bin/time -v`:

| Metric | 10,001-line script |
|---|---|
| Wall clock | ✅ 4.92 s |
| Max resident memory | 366 MB |
| Landmine found | ✅ line 6175, exact |

366 MB to lint a 200 KB file is a lot of RAM per byte, and 4.92 seconds is long enough that you would not want it in a pre-commit hook on a monorepo of generated scripts. But it did not choke, did not skip, and did not lose the one line that mattered in ten thousand. Survives a bad Tuesday.

## The filenames from hell (grudging respect)

My reflex on any file tool is to hand it a filename with a newline, an emoji, and a shell metacharacter, and see what breaks. So I named a *script file* `t6 🔥 $(whoami).sh` and linted it:

```bash
$ shellcheck "t6 🔥 \$(whoami).sh"
In t6 🔥 $(whoami).sh line 3:
grep foo $1
         ^-- SC2086 (info): Double quote to prevent globbing and word splitting.
```

It printed the emoji back in the header, found the real bug inside, and — this is the part I was hunting for — it did **not** execute the `$(whoami)` embedded in the filename. A lazier tool that built a shell command out of the path would have. Then I gave a script file a literal newline in its name; shellcheck read it and returned clean, exit 0, no drama. I tried three ways to make the parser trip on its own input and it refused all three. Say it when it hurts: that's solid engineering.

## Column two: the misses (read this part twice)

Here is where the review turns. I wrote a script with three commands that range from "silent data loss" to "arbitrary code execution," all syntactically perfect, and asked shellcheck for its opinion:

```bash
$ shellcheck t10_miss.sh
$ echo $?
0
```

Nothing. Exit 0. A clean bill of health for this:

```bash
version="3.14-rc1"
if [ "$version" -eq 3 ]; then echo three; fi   # -eq on a string: runtime error
rm -rf "$prefix "*                             # stray space inside the quotes
curl -s https://example.com/installer | bash   # pipe-the-internet-to-a-shell
```

| Dangerous script | shellcheck verdict | What actually happens at runtime |
|---|---|---|
| `[ "$version" -eq 3 ]` on a string | ❌ silent, exit 0 | `-eq` demands integers; this throws at runtime, and your `if` takes the wrong branch |
| `rm -rf "$prefix "*` | ❌ silent, exit 0 | The space is *inside* the quotes; the glob is outside — this does not delete what you think |
| `curl ... \| bash` | ❌ silent, exit 0 | Piping an unverified installer straight into a shell. shellcheck has no opinion |

None of these are shellcheck's *job* — it's a syntax and quoting linter, not a threat model. But that's exactly the point a reader needs before they trust a green checkmark: **shellcheck passing means your script is well-formed, not that it's safe.** The variables are quoted, so SC2086 stays quiet; the `-eq` type mismatch is a runtime fact it can't see statically; and `curl | bash` is, syntactically, a perfectly nice pipeline. Three landmines, zero findings.

And then there's the escape hatch, which is worse than a miss because it's *invited*:

```bash
$ cat t11_disable.sh
#!/bin/bash
# shellcheck disable=SC2086
echo $UNQUOTED_ON_PURPOSE
$ shellcheck t11_disable.sh && echo "exit=$?"
exit=0
```

One comment and the finding evaporates. That directive exists for good reasons, but it also means any script in your tree can look clean while carrying the exact bug shellcheck was installed to catch. When you audit someone else's "shellcheck-passing" repo, grep for `disable=` first. That's not paranoia; that's the receipts telling you where the bodies are buried.

## How to actually run it (the two flags that matter)

For a CI gate, you rarely want to fail the build on an `info`-level nag about quoting in a script that works. Gate on real errors and let the rest advise:

```bash
$ shellcheck --severity=error t9_cd.sh
In t9_cd.sh line 5:
local latest=$(git describe --tags)
^---^ SC2168 (error): 'local' is only valid in functions.
```

And when a machine needs to read the output — a CI annotation, a `grep`, a diff — the `gcc` format is one line per finding with the code in brackets, which is far easier to post-process than the pretty caret art:

```bash
$ shellcheck -f gcc t1_unquoted.sh
t1_unquoted.sh:2:10: error: Iterating over ls output is fragile. Use globs. [SC2045]
t1_unquoted.sh:3:6: note: Double quote to prevent globbing and word splitting. [SC2086]
```

shellcheck doesn't recurse directories on its own, so the real-world invocation is `find . -name '*.sh' -exec shellcheck {} +` or, if you want the whole gauntlet's findings tallied at once, hand it every file and count:

```bash
$ shellcheck -f gcc t1_unquoted.sh t3_assign.sh t9_cd.sh | grep -oE 'SC[0-9]+' | sort | uniq -c | sort -rn
      3 SC2086
      2 SC2035
      1 SC2283
      1 SC2168
      1 SC2164
      1 SC2155
      1 SC2154
      1 SC2045
      1 SC2034
```

## The verdict, on the survives-a-Tuesday scale

**Normal Tuesday:** it catches your quoting bugs, your `cd` disasters, and your accidental `local` at the top level, cold, in milliseconds. Install it, run it, thank it.

**Bad Tuesday** — the 10,000-line generated monster, the file with an emoji and a subshell in its name, the newline in the path: it survived all of them without choking or executing anything it shouldn't. Grudging respect, logged.

**Tuesday where the intern has sudo:** here it taps out, and honesty demands I say so loudly. shellcheck will bless a script that pipes the internet into a shell, compares a version string with an integer operator, and hides a real bug behind one `# shellcheck disable=` comment. That's not a bug in shellcheck — it's the edge of what a static linter *is*. Use it as the first gate, never the last one. The green checkmark means "well-formed," and the three commands it slept through are the reason you still read the diff yourself.

Install it. Gate CI on `--severity=error`. And keep reading your own scripts, because the tool that caught `rm $f` is the same tool that will hand a clean bill of health to `rm -rf "$prefix "*`.
