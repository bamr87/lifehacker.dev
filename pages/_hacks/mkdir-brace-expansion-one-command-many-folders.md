---
title: "One mkdir, many folders: brace expansion (and the space that silently breaks it)"
description: "Build a directory tree with one mkdir via brace expansion, ranges with {1..10}, back up a file with cp file{,.bak}, and the space that quietly breaks it."
preview: /images/previews/one-mkdir-many-folders-brace-expansion-and-the-spa.png
date: 2026-07-11
collection: hacks
author: claude
excerpt: "mkdir -p proj/{src,test,docs} builds the whole tree in one shot. Put one space after a comma and you get a folder literally named {src, instead. Here's the trick and the footgun, both run for real."
tags: [bash, shell, cli]
---

You are about to run `mkdir` five times to scaffold a project. Don't. The shell will build the entire tree from a single command — if you feed it the braces exactly right. Get one space wrong and it builds a tree you did not ask for, with folders named after the punctuation.

This one bubbled up from it-journey's [Building Technical Communities](https://it-journey.dev/quests/1111/building-technical-communities/) quest, whose "stand up a shared repo" checklist opens, as these always do, with making a pile of directories. Here is how to make the pile in one keystroke-run — and the exact character that turns the trick against you.

Everything below was run on `GNU bash 5.2.21` with `mkdir (GNU coreutils) 9.4`.

## The whole tree in one command

Brace expansion takes `{a,b,c}` and stamps out `a b c`, gluing on whatever sits to the left and right of the braces. So a comma-separated list inside braces, hung off a common prefix, becomes a directory tree:

```console
$ mkdir -p proj/{src,test,docs,.github/workflows}
$ find proj -type d | sort
proj
proj/.github
proj/.github/workflows
proj/docs
proj/src
proj/test
```

One command, five directories, including a nested `.github/workflows`. The `-p` matters twice here: it creates parent directories as needed (so `.github` gets made on the way to `workflows`), and it doesn't complain if something already exists.

**The habit that saves you:** the braces are pure text expansion, so `echo` shows you exactly what `mkdir` is about to receive — no directories created, no risk:

```console
$ echo proj/{src,test,docs,.github/workflows}
proj/src proj/test proj/docs proj/.github/workflows
```

`echo` first, `mkdir` second. That one reflex is what makes the rest of this hack safe to experiment with.

## The space that silently breaks it

Here is the footgun, and it is a good one because the command *looks* right and `mkdir` doesn't error. Put a single space after the comma — the way you'd naturally type a list — and the shell stops treating the braces as an expansion at all:

```console
$ mkdir -p proj/{src, test}
$ find . -type d | sort
.
./proj
./proj/{src,
./test}
```

Read that. You asked for `proj/src` and `proj/test`. You got a directory literally named `proj/{src,` and a *top-level* directory named `test}`. The space made the shell split the line into two ordinary words — `proj/{src,` and `test}` — and hand both to `mkdir` verbatim, braces and all. No expansion happened, no error printed, and now you have two junk directories in two different places.

Why? Brace expansion only fires when the braces contain no unquoted whitespace. The space breaks the pattern, the shell falls back to plain word-splitting, and `mkdir -p` cheerfully makes exactly what it was told. **You'll know you hit this** when `ls` shows a folder with a `{` or `}` in its name — that is always the tell.

The `echo`-first habit catches it before it happens:

```console
$ echo proj/{src, test}
proj/{src, test}
```

Unexpanded output — the braces are still there — means "this will not do what you want." Expanded output means you're clear.

## Ranges: {1..10} and {a..z}

Two dots instead of commas gives you a sequence — numbers or letters:

```console
$ echo part{1..5}
part1 part2 part3 part4 part5
$ echo host{a..e}
hosta hostb hostc hostd hoste
```

Bash 4+ adds zero-padding and a step. Pad by writing the first number with a leading zero; add a third `..N` for the stride:

```console
$ echo file{01..10}
file01 file02 file03 file04 file05 file06 file07 file08 file09 file10
$ echo even{0..10..2}
even0 even2 even4 even6 even8 even10
```

`file{01..10}` is the one that earns its keep: it gives you correctly zero-padded names that sort in the right order, which is a genuine chore to do by hand.

## The one-keystroke backup: cp file{,.bak}

An empty element in the list expands to nothing, which sets up the single most useful brace trick there is — copying a file to `file.bak` without retyping the name:

```console
$ echo hello > config.yml
$ echo cp config.yml{,.bak}
cp config.yml config.yml.bak
$ cp config.yml{,.bak}
$ ls -1
config.yml
config.yml.bak
```

`config.yml{,.bak}` expands to `config.yml` (empty element) followed by `config.yml.bak` (`.bak` element) — exactly the two arguments `cp` wants. Change the filename in one place and both arguments update. This is the brace expansion you'll reach for daily.

## The gotcha the internet gets wrong: variables and ranges

You will read that "brace expansion happens before variable expansion, so you can't use variables." That's half true, and the half that's wrong will bite you the other direction. A **comma list** with variables works fine, because the braces split into words first and *then* each `$var` expands:

```console
$ a=src; b=test
$ echo {$a,$b}
src test
```

But a **range** with a variable does not, because the range endpoints have to be literal integers at the moment the braces are read — before `$n` is anything:

```console
$ n=5
$ echo part{1..$n}
part{1..5}
```

The output is the literal, unexpanded string — the range quietly refused. When you need a variable upper bound, reach for `seq` (or a C-style `for`) instead of a brace range:

```console
$ n=5
$ for i in $(seq 1 "$n"); do printf 'part%s ' "$i"; done; echo
part1 part2 part3 part4 part5
```

So the honest rule is narrower than the folklore: variables are fine in a comma list, useless in a range.

## The safe pattern, tested

Here is the scaffold-in-one-shot move plus the space footgun, wired to prove itself. This block is opted into our test harness (`lh:run`) and runs on every build in a locked-down, no-network sandbox — so the version you're reading is the version that passed:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail

cd "$(mktemp -d)"

echo "==> one command builds the whole tree:"
mkdir -p myapp/{src/{api,web},tests,docs,.github/workflows}
find myapp -type d | sort

echo "==> count the directories we made in one shot:"
count=$(find myapp -mindepth 1 -type d | wc -l)
echo "made $count directories"
test "$count" -eq 7

echo "==> the space footgun: a stray space after the comma kills expansion"
mkdir -p demo/{a, b}
echo "we asked for demo/a and demo/b; we actually got:"
find . -type d \( -name '{a,' -o -name 'b}' \) | sort
test -d "demo/{a," && test -d "b}"
echo "  -> a literal folder named {a, plus a top-level b} — not what we meant"

echo "done"
```

Note the nested `{src/{api,web},...}` in that first line: braces nest, and they also form a Cartesian product when you place two groups side by side (`{src,test}/{unit,integration}` makes all four `src/unit … test/integration`). That's the same one command doing even more work.

## When this goes wrong

- **A folder with a `{` or `}` in its name.** You left a space inside the braces (or quoted them). `echo` the command first; unexpanded output is the warning. To delete the mess, quote the literal name: `rm -r 'proj/{src,' 'test}'`.
- **`{one}` with no comma does nothing.** A single element with no comma and no `..` isn't a brace expansion at all — it stays literal `{one}`. Brace expansion needs at least a comma or a range. (An *empty* second element, `{one,}`, does expand — to `one` and the empty string.)
- **The range came out literal, like `part{1..$n}`.** You used a variable as a range endpoint. Ranges need literal integers; use `seq` for a variable bound.
- **`mkdir` without `-p` on a nested path.** `mkdir proj/{src,test}` fails if `proj` doesn't exist yet, because plain `mkdir` won't create the parent. Add `-p` whenever the prefix directory might not be there.

Two dots for ranges, commas for lists, an empty element for the backup trick — and never, ever a space inside the braces. `echo` first and the shell will show you the tree before you build it.
