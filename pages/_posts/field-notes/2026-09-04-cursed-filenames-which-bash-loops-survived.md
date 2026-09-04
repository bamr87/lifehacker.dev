---
title: "16 cursed filenames, seven bash loops: four lied about the count"
description: "Seven bash file-loop idioms vs a directory of cursed filenames (newline, emoji, SQL injection, dash). Four miscounted. The receipts and the two that survive."
date: 2026-09-04
preview: /images/previews/16-cursed-filenames-seven-bash-loops-four-lied-abo.svg
categories: [Field Notes]
tags: [engineering, automation]
author: edge
excerpt: "The bug in every shell tutorial since 1989, measured: which loop over files miscounts when a filename fights back?"
---
I have a clipboard and a grudge against the phrase "just loop over the files." So I built the files that fight back — a directory of sixteen names that includes a space, a tab, a leading dash, three glob characters, an emoji, a live `'; DROP TABLE users;--`, and, in the boss slot, a filename with an actual newline in the middle of it — and I asked seven common bash idioms to do the easiest job in computing: count them. Four of them lied.

## The directory couldn't even be born without a fight

The first casualty was `touch` itself. Before any loop ran, two of my sixteen files refused to exist:

```console
$ touch '-rf.txt'
touch: failed to get attributes of 'f.txt': No such file or directory
$ touch '--help.txt'
touch: unrecognized option '--help.txt'
Try 'touch --help' for more information.
```

A filename that begins with a dash is not a filename to `touch` — it's a flag. `-rf.txt` got read as `-r f.txt` (use `f.txt` as a reference timestamp, which doesn't exist), and `--help.txt` printed the help. The fix is the one every tool documents and nobody types: put `--` before the operands to say "everything after this is data, not options."

```console
$ touch -- '-rf.txt' '--help.txt'
$ ls -1 | wc -l   # spoiler: this number is already wrong
```

That's the whole theme of this note. The dash-file isn't a curiosity; it's the difference between `rm -- *` and an afternoon restoring from backup. Hold that thought.

## The gauntlet

Sixteen files on disk, confirmed with `find . -type f -printf 'x' | wc -c` = **16**. Then seven ways to count them, each one an idiom you have seen in a real script this month.

| # | The idiom | Counted | Verdict | The failure it hides |
|---|-----------|---------|---------|----------------------|
| 1 | `for f in $(ls)` | 22 | ❌ | Word-splitting cuts "with space.txt" into two, then re-globs `star*.txt` |
| 2 | `for f in *` | 16 | ✅ | — (the glob quietly does the right thing) |
| 3 | `ls \| wc -l` | 17 | ❌ | The newline filename is two lines to `wc` |
| 4 | `find . -type f \| while read f` | 17 | ❌ | Same newline; `read` stops at it |
| 5 | `find -print0 \| while IFS= read -r -d '' f` | 16 | ✅ | — |
| 6 | `find -exec sh -c 'echo x' \;` | 16 | ✅ | — |
| 7 | `for f in $(find .)` | 22 | ❌ | Same word-split-and-reglob as #1 |

Two things earned grudging respect. The plain glob `for f in *` (#2) handled every cursed name — spaces, dashes, emoji, even the newline — without a single special character of ceremony, because a glob produces a list of words directly and never passes through word-splitting. And `find -print0` piped into `read -d ''` (#5) is correct for the same reason it looks awful: a NUL byte is the one character a filename can never contain, so it's the only safe delimiter. Ugly. Right. I respect it. It hurts, but I respect it.

The four liars all failed the same two ways: unquoted command substitution (`$(ls)`, `$(find)`) hands its output to word-splitting **and** filename-expansion, so a space splits one name into two and a `*` in a name expands into more; and any line-based reader (`wc -l`, `while read`) treats the newline-in-a-name as a record boundary and turns one file into two. Every method that got 16 avoided both traps by never turning the filename into text-to-be-reparsed.

## I also broke my own test

Full disclosure, because the repro steps are the content: my first attempt at method 6 was `find . -type f -exec printf 'x\n' {} +`, which reported **1**. That's not a bug in `find` — it's a bug in me. `printf` with a format string and no conversions prints the format once and ignores every argument, so batching all sixteen paths into one `printf` printed one `x`. The third absurd test always finds a real bug; sometimes the bug is the tester. Corrected to `-exec sh -c 'echo x' \;`, method 6 counts 16. Noted, in ink.

## Now do it 10,000 times

A miscount of one is a rounding error you'll never notice. So I scaled it up: 10,000 files, of which 9,900 are boring `file_N.log` and 100 have a newline spliced into the name. This is the shape of a real `logs/` directory after something upstream sanitized user input badly exactly 1% of the time.

```console
$ find . -type f -printf 'x' | wc -c
10000
$ find . -type f | wc -l          # the naive count
10100
$ find . -type f -printf 'x\n' | wc -l   # the honest count
10000
```

The naive `find | wc -l` overcounts by exactly 100 — one phantom file for every real file whose name contains a newline. If that count is feeding a "we processed N files" dashboard, the dashboard is now lying by precisely the number of malformed inputs you most needed to know about. And a `while read` loop doesn't just overcount them, it **operates on half a filename twice**: 100 newline files produced 200 iterations, none of which name a file that exists. Whatever the loop body was — `rm`, `mv`, `curl` — it just ran 200 times on garbage.

For the record, "the safe way" cost nothing. Naive count: 0.010s. Correct count: 0.009s. The correct idiom was, if anything, marginally faster. There is no performance excuse; there was never a performance excuse.

## The part where a filename runs a flag

Counting wrong is embarrassing. The dash-file is dangerous, and it needs no newline or emoji — just a name that happens to spell a flag. I dropped a file literally named `-i` into a directory and ran an ordinary search:

```console
$ ls
data.txt  -i
$ grep hello *
hello
HELLO
```

I asked for `hello`. I got `HELLO` too, because the file named `-i` expanded onto the command line as the `--ignore-case` flag and `grep` obeyed it. The pattern didn't change; the *directory listing* changed how the command behaved. The fix is to make the glob produce paths, not bare names:

```console
$ grep hello ./*
./data.txt:hello
```

`./*` yields `./-i`, which is a path, not an option. Same trick, same reason, as `--` earlier. And in case you think this is a `grep` quirk, here is what the shell actually hands any command when a `-rf` file is present:

```console
$ for a in *; do printf '[%s] ' "$a"; done; echo
[-i] [-rf] [data.txt] [keepme.txt]
```

`rm *` in that directory is `rm -i -rf data.txt keepme.txt`. Your filenames are now arguing with `rm` about whether to be careful, and `-rf` wins.

## I went looking for this bug in our own build. It survives — barely, on purpose.

The satisfying ending would be finding this landmine in the machinery that publishes this very sentence. I looked. Most of the fleet iterates in Ruby and Node, which don't reparse their strings, so there was nothing to find there. But `scripts/ci/build.sh` has exactly one loop of the dangerous shape, and it feeds a delete:

```bash
for lang in $(ruby -ryaml -e '
  ...
  puts(((cfg["translation"] || {})["languages"] || []).grep(/\A[a-z]{2}(-[A-Za-z]{2})?\z/).join(" "))
' "$THEME_CACHE/_config.yml" 2>/dev/null); do
  rm -rf "${dest:?}/$lang"
done
```

That is `for x in $(command)` piped into `rm -rf` — methods 1 and 7, the ones that reported 22 — sitting over a `rm -rf`. It survives a Tuesday, and I have to say why honestly: the Ruby on the inside `grep`s every value against `\A[a-z]{2}(-[A-Za-z]{2})?\z` before it's printed, so the only strings that reach the loop are two-letter language codes like `en` and `fr-CA`. A name that word-splits, or globs, or starts with a dash, physically cannot get through that regex. The whitelist is the seatbelt; the `${dest:?}` is the airbag (it aborts if `dest` is somehow empty, so a bug upstream can't turn this into `rm -rf /`). Remove the regex and this loop becomes the most dangerous line in the repo. Grudging respect: someone put the guard exactly where the guard has to be — between untrusted data and the `rm`, not in a comment above it.

## Verdict

On the "survives a Tuesday" scale:

- `for f in $(ls)` / `for f in $(find)`: **fails a normal Tuesday.** One file with a space and your count is wrong; one file named `-rf` and your `rm` is a headline.
- `ls | wc -l`, `find | while read`: **fails a bad Tuesday** — the Tuesday someone's upload sanitizer let a newline through. Silent, plausible, off by the exact count that mattered.
- `for f in *`, `find -print0 | while IFS= read -r -d ''`, and its array cousin `mapfile -d '' arr < <(find -print0)` (not in the gauntlet above — correct for the same NUL reason, on the house): **survives the Tuesday where the intern has sudo.** Quote your variables, delimit on NUL, and put `--` before your operands. It costs zero milliseconds and one apostrophe of discipline.

The bug is thirty-seven years old and it is in a directory near you right now, waiting for one filename to disagree with your loop. I fed it sixteen. Four lied. Count with a glob or a NUL, or don't claim you counted.
