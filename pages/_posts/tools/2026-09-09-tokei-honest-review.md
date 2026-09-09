---
title: "tokei: the code counter that files your prose under Comments and hides half its own math"
description: "A stress-tested review of tokei: why your Markdown counts as zero code, the embedded breakdown that never reaches the total, and the gauntlet it survived."
date: 2026-09-09
preview: /images/previews/tokei-the-code-counter-that-files-your-prose-under.svg
categories: [Tools]
tags: [files, data]
author: edge
verdict: "Use it — survives a Tuesday where the intern has sudo. It counts fast and honestly; you just have to know that the prettiest numbers on screen aren't in the total."
excerpt: "I pointed tokei at a docs-heavy repo and it reported zero lines of code and 30,954 comments. It wasn't wrong. Then it showed me 3,422 lines of shell hiding in my Markdown and quietly left every one of them out of the total."
permalink: /tools/tokei-honest-review/
---
I review tools by handing them the repo nobody sane would keep clean and watching which column lies first. `tokei` is the one you reach for the day someone in a meeting asks "how big is the codebase, actually?" and you realize `wc -l **/*` is going to count your `node_modules` and your minified vendor blob and then hang on a binary. `tokei` is the honest answer to that question: point it at a directory, get a per-language table of files, total lines, code, comments, and blanks, sorted however you like, in less time than it took you to read this sentence.

It is genuinely good at the job. It is also a tool where the two most eye-catching numbers on the screen — the giant Comments count on a docs repo, and the beautiful per-language breakdown of code embedded in your Markdown — are both *display artifacts that don't participate in the total*. Neither is a bug. Both are things that will make you say a wrong number out loud in that meeting if nobody told you first. Consider this the telling.

**The verdict, up front:** use it. It's absurdly fast, it respects your `.gitignore` so it counts the code you wrote and not the code you downloaded, it handles a genuinely hostile gauntlet without flinching, and it is *more* correct than `wc` on the edge cases. It survives a normal Tuesday, a bad Tuesday, and a Tuesday where the intern has sudo. What it will not do is stop you from misreading its own output — so the failure mode isn't a crash, it's you, confidently, in front of your manager.

Everything below ran on a fresh box against the version I pulled as a release binary:

```console
$ tokei --version
tokei 12.1.2 compiled with serialization support: json, cbor, yaml
```

(First honest note, free: 12.1.2 shipped in January 2021 and is still the latest tagged release as I write this. `cargo install tokei` gives you the same number. A code counter is not a thing that rots — the languages move slower than the tool — but if you were waiting for the version bump to fix something, it isn't coming. Grab a release binary and skip the compile.)

## The headline surprise: your documentation is not "code"

Here is the first number that will trip you. I ran `tokei` on a documentation-heavy repo — 403 Markdown files — and it told me, with a straight face, that the Markdown had **zero** lines of code:

```console
$ tokei .
===============================================================================
 Language            Files        Lines         Code     Comments       Blanks
===============================================================================
 JavaScript             13         4208         3571          421          216
 JSON                  194        11951        11944            0            7
 Ruby                   53         8174         5368         2090          716
 Shell                  12          774          393          314           67
 SVG                   198        23390        23324           65            1
 YAML                   28         8047         5697         2086          264
-------------------------------------------------------------------------------
 Markdown              403        44844            0        30954        13890
 ...
===============================================================================
 Total                 922       104507        52894        36166        15447
===============================================================================
```

`Markdown  403  44844  0  30954  13890`. Zero code, 30,954 comments. tokei has decided your prose is a comment. Which — fine, defensible, prose isn't executable — but it means the instant your repo is documentation-heavy, the `Code` column stops being "how much did we write" and the `Comments` column becomes a giant bucket labeled *everything that isn't a keyword*. **The failure this prevents you from noticing:** if you quote tokei's `Code` total as "the size of the project" on a docs site, a wiki, or a content repo, you will undercount your own work by the entire thing you actually shipped. The number isn't wrong. The sentence you build around it will be.

## Gotcha 1: the embedded-language breakdown is a beautiful lie about your total

This is the one I'd tattoo on the README. tokei doesn't just count your Markdown as prose — it reaches *inside* the fenced code blocks and re-attributes them to their real language. On the same repo:

```console
$ tokei .
 ...
 Markdown              403        44844            0        30954        13890
 |- BASH               153         3422         2786          348          288
 |- Python              25          727          610           45           72
 |- Ruby                44          468          408           49           11
 |- YAML                68         1107          998           49           60
 ... (11 more embedded languages) ...
 (Total)                          51813         5840        31567        14406
===============================================================================
 Total                 922       104507        52894        36166        15447
===============================================================================
```

Read that carefully. tokei found **3,422 lines of shell** living inside my Markdown code fences and broke them out by language for me. Genuinely useful — that's real, tested shell in the docs, and now I know how much of it there is. The `(Total)` sub-row says the Markdown-plus-its-embedded-code is 51,813 lines.

Now look at the grand `Total` at the bottom: **104,507**. Add up the top-level `Lines` column by hand — Dockerfile through Markdown — and you get 104,507 exactly, using the Markdown row's `44844`, **not** the `(Total)` row's `51813`. The embedded breakdown is *not in the total*. Those 3,422 lines of BASH are shown to you, itemized, indented, and then silently excluded from every summary number.

I proved it's not just display formatting by running the compact mode, which collapses the breakdown entirely:

```console
$ tokei -C .
 Markdown              403        44844            0        30954        13890
 ...
 Total                 922       104507        52894        36166        15447
```

Same total. The 5,840 lines of embedded code the `(Total)` sub-row was so proud of never touched the bottom line. **The failure this prevents:** you point at the gorgeous `|- BASH  3422` row to argue "we have thousands of lines of tested examples" and someone cross-checks it against the `Total`, where those lines are counted as Markdown comments instead. Both numbers are tokei's. They do not agree, on purpose, and the tool does not warn you.

## Gotcha 2: `-c` is not `--compact`, and it detonates on a directory

I went looking for that compact mode by reflex and typed the lowercase flag. Here is what `tokei -c` does:

```console
$ tokei -c .
Error:
invalid digit found in string
```

`-c` is `--columns`, and it wants a *number* (a terminal width). `tokei -c .` reads the `.` as the column count, fails to parse it as an integer, and dies with an error message that mentions neither the flag nor the offending argument. Compact mode is the **uppercase** `-C`, `--compact`. The two flags are one Shift key apart, do unrelated things, and one of them turns your directory path into a fatal parse error. **The failure this prevents:** a script that runs `tokei -c "$DIR"` works perfectly until the day `$DIR` isn't a number, which is always, and then exits non-zero with "invalid digit found in string" and no clue why. Quote your paths, and never trust a single-letter flag to be the word it looks like.

## The gauntlet: the filenames nobody sane would keep

A code counter walks your whole tree, so the real test is what it does when the tree fights back. I built the directory of my nightmares — a filename containing a literal newline, an emoji, and a SQL injection payload; a file with no trailing newline; a file that's nothing but blank lines; an empty file; and a pair of symlinks pointing at each other — and pointed tokei at it.

Nothing crashed. The SQL injection is inert, of course — tokei counts bytes, it doesn't execute your filenames — and the counts came back correct. But the **per-file display** buckled on the newline:

```console
$ tokei -f .
 Rust                    2            5            3            1            1
-------------------------------------------------------------------------------
 |;DROP TABLE users;--.rs             1            1            0            0
 ./normal.rs                          4            2            1            1
```

The file was named `evil⏎name💥;DROP TABLE users;--.rs` (that `⏎` is a real newline). tokei counted it fine — one Rust file, one line — but in `-f` output the path is printed starting from the *second physical line of the filename*, prefixed with tokei's `|` truncation marker. The first half of the name, emoji and all, is gone from the report. **The failure this prevents:** if you pipe `tokei -f` into anything that parses filenames — a script that flags the biggest files, say — a newline in a filename desyncs your parser and you act on the wrong file, or a name your log will render as a fake second entry. The count is trustworthy. The path column is not, against an adversary.

Then it earned grudging respect. The file with no trailing newline — the one `wc` gets wrong:

```console
$ printf 'x = 1' > nn.py     # no trailing newline
$ wc -l nn.py
0 nn.py
$ tokei nn.py
 Python                  1            1            1            0            0
```

`wc -l` says **zero lines**, because `wc` counts newline *characters* and there isn't one. tokei says one line of code, which is the correct answer a human would give. On the exact edge case that has quietly corrupted every naive `wc`-based line count since 1975, tokei is right and the Unix classic is wrong. Fine. It's good. I said it.

The rest of the gauntlet passed boringly, which is the best kind of passing:

| Scenario | What tokei did | Survives? |
|---|---|---|
| Newline + emoji + SQLi in filename | Counted correctly; per-file path display mangled | ⚠️ counts ✅, display ❌ |
| No trailing newline | 1 line (`wc` says 0) — more correct than `wc` | ✅ |
| File of only blank lines | 5 lines, 5 blanks, 0 code | ✅ |
| Empty file | Inflates the `Files` total by 1, shows in no language row | ⚠️ ✅ but invisible |
| Two symlinks pointing at each other | No infinite loop, no crash | ✅ |
| 10,000 tiny files | Counted all 10,000 in **0.042s** | ✅ |

That last row is the reason to keep it. Ten thousand files, timed with the shell's own `time`:

```console
$ time tokei .
 Rust                10000        10000        10000            0            0
 Total               10000        10000        10000            0            0

real	0m0.042s
```

Forty-two milliseconds for ten thousand files. It respects `.gitignore` the way `ripgrep` and `fd` do — [we've reviewed both](/tools/ripgrep-honest-review/) [of those](/tools/fd-honest-review/) — so on a real project it skips your `node_modules` and counts what you wrote, not what you `npm install`ed. That combination, fast plus gitignore-aware, is the whole pitch, and it delivers it.

## The one genuinely soft spot: empty files vote but don't appear

Look again at the table row for the empty file. tokei counts it toward the `Files` total but gives it no language row, because it has no lines to attribute:

```console
$ tokei empty.js
===============================================================================
 Language            Files        Lines         Code     Comments       Blanks
===============================================================================
===============================================================================
 Total                   1            0            0            0            0
===============================================================================
```

`Total  Files: 1`, and not a single language listed. **The failure this prevents:** if you diff two tokei runs and the `Files` count moved but no language's count did, don't go hunting for a phantom — someone added (or deleted) an empty file, and tokei is counting a thing it refuses to categorize. Small, but it's the kind of one-off discrepancy that eats an afternoon if you don't know it's a feature.

## Who it's for, the price, and the free alternative

It's free, MIT-licensed, and single-binary — no runtime, no config required, one `tokei .` and you're done. Use it if you want a fast, gitignore-aware, per-language snapshot of a codebase, especially for a README badge or a "how big is this" gut check.

The alternatives, honestly: `cloc` is the venerable Perl one, more languages, slower, and it does its own thing with duplicate detection; `scc` is the other fast Rust-adjacent (Go, actually) counter and it'll also estimate COCOMO cost if you enjoy fiction with your metrics. And `wc -l` is already on your machine and free — just remember it counts newline characters, misses the last line of a file that lacks one, and cheerfully counts your minified vendor bundle. tokei exists precisely to not be that.

**Final verdict:** use it — survives a Tuesday where the intern has sudo. It counts fast, it counts honestly, and it never once lied to me. It just shows you two sets of numbers — the total, and the prettier embedded breakdown that isn't in the total — and trusts you to know which one to say out loud. Now you do.
