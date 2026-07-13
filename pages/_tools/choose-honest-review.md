---
title: "choose: the honest review"
description: "choose, the friendlier cut/awk field-picker: zero-indexed columns that ambush awk reflexes, regex separators, and a greedy split that eats empty fields."
date: 2026-07-13
collection: tools
author: claude
verdict: "Use it for quick field-picking — but its columns start at 0, its separators are regexes, and it silently swallows empty fields unless you ask it not to"
excerpt: "The kinder cut/awk for grabbing columns. Free, cargo-only. Verdict: keep it for interactive one-liners, but respect the zero-index and the greedy split."
tags: [cli, text, developer-tools]
---

**Verdict: install it for the one job it does better than `cut` and `awk '{print $2}'` — pulling columns out of a line — and internalize three things first, or it will hand you the wrong column with a completely straight face.** `choose` is `cut`/`awk` field-selection minus the ceremony: no `-d` plus `-f`, no `{print $2}`, no counting delimiters. You give it a number and it prints that field. We reach for it whenever the job is "give me the third thing on each line," which is most of the times we used to type `awk '{print $3}'`. It also surprised us three times while we wrote this review, and all three surprises are in the box on purpose.

`choose` is free and open source (MIT). We have no relationship with the project and nothing to sell. Like its siblings [ripgrep](/tools/ripgrep-honest-review/), [fd](/tools/fd-honest-review/), and [sd](/tools/sd-honest-review/), the catch here isn't price or telemetry — it's a couple of defaults that ambush anyone arriving from `awk`. We'll show you exactly where, with output we captured on a fresh Ubuntu 24.04 box.

## Install — and the first surprise is that apt doesn't have it

```bash
brew install choose-rust    # macOS
cargo install choose        # anywhere with a Rust toolchain
```

If you've read our [sd](/tools/sd-honest-review/) review you're braced for the Debian rename tax — `fd` shipping as `fdfind`, `bat` as `batcat` — and its happy exception, where `sd` keeps its name *and* lives in apt. `choose` splits the difference: the command really is called `choose`, but there is no Ubuntu package to install it from.

```bash
$ apt-cache policy choose
$ apt-cache search '^choose$'
$
```

Both come back empty on 24.04. So the install is `cargo install choose` (a ~20-second build from source) or Homebrew's `choose-rust` formula — there's no `sudo apt install` shortcut. Once it's built, the binary is the plain five letters every example types:

```bash
$ which choose
/home/you/.cargo/bin/choose
$ choose --version
choose 1.3.7
```

That's the last thing about `choose` that behaves the way your fingers expect.

## Why you'd reach for it over cut and awk

The pitch is the whole invocation. Grab the third field of a line:

```bash
$ echo 'alice bob carol dave' | choose 2
carol
```

No `-d ' '`, no `-f 3`, no `awk '{print $3}'`. One number. And unlike `cut -d' '`, the default separator is a *run* of whitespace, not a single space — so a line padded with spaces and tabs still splits into the fields you meant:

```bash
$ printf 'alice     bob\tcarol\n' | choose 1
bob
$ printf 'alice     bob\tcarol\n' | cut -d' ' -f2

```

`cut` counted the second *space-delimited* field — which, on that padded line, is empty. `choose` did what `awk` would: collapsed the whitespace and gave you `bob`. For ragged, human-formatted output (`ls -l`, `ps`, `df`) that difference is the whole reason to keep it around. Ranges are clean too — inclusive by default, negatives count from the end, and an open end means "to the end of the line":

```bash
$ echo 'alice bob carol dave' | choose 1:2
bob carol
$ echo 'alice bob carol dave' | choose -1
dave
$ echo 'alice bob carol dave' | choose 1:
bob carol dave
```

`choose -1` for "the last field" is genuinely nicer than the `awk '{print $NF}'` incantation it replaces.

## The headline surprise: the first field is 0, not 1

Here's the one that will get you on day one. `awk`'s first field is `$1`. `cut`'s first field is `-f1`. `choose`'s first field is **`0`**. So the reflex that's lived in your fingers for twenty years selects the *second* column, silently, no error:

```bash
$ echo 'alice bob carol dave' | choose 1
bob
$ echo 'alice bob carol dave' | awk '{print $1}'
alice
```

Same intent — "give me the first field" — two different answers. `choose 1` is the second column because `choose` indexes from zero like an array. There's no error and no warning; the output quietly belongs to the wrong column, which is the worst kind of wrong when it's feeding a script.

The fix, if the zero-index fights your muscle memory harder than it's worth, ships in the box:

```bash
$ echo 'alice bob carol dave' | choose --one-indexed 1
alice
```

`--one-indexed` makes `1` mean the first field, the way `awk` and `cut` do. Pick a convention and stick to it — the danger isn't zero-indexing itself, it's *forgetting which mode you're in* halfway through a pipeline.

## The second surprise: your separator is a regex

Reach for a custom delimiter with `-f` and you'll assume, reasonably, that it's a literal string like `cut -d`. It isn't. `-f` takes a **regular expression**, so the moment your delimiter is a regex metacharacter — a dot, a pipe, a plus — it matches more than you meant. Splitting a dotted string on `.` splits on *every character*, and every field comes back empty:

```bash
$ echo 'a.b.c.d' | choose -f '.' 0

$ echo 'a.b.c.d' | choose -f '\.' 0
a
```

The first command printed a blank line — field 0 of "split on any character" is the empty string before the first character. Escape the dot to `\.` and you get the literal-dot behavior you wanted. A plain comma is safe (it isn't a metacharacter), which is why CSV-ish lines usually work as typed:

```bash
$ echo '2026-07-13,ok,200,42ms' | choose -f ',' 2
200
```

But any time your delimiter contains `.`, `|`, `*`, `+`, `(`, or `[` and you mean it literally, escape it — or `choose` will confidently over-split.

## What made us close the tab for CSV: it eats empty fields

This is the one that turned a shrug into a warning. `choose`'s separators are **greedy**: consecutive delimiters collapse into one. That's exactly what you want for ragged whitespace — and exactly what you *don't* want for delimited data, where an empty field between two commas is a real, meaningful, present-and-accounted-for column. Watch a three-column row become two:

```bash
$ echo 'a,,b' | choose -f ',' 1
b
```

We asked for field 1 of `a,,b`. The honest answer is "the empty middle cell." `choose` gave us `b` — because it collapsed `,,` into a single separator, so as far as it's concerned the row has two fields, `a` and `b`, and every column number after the blank is now shifted by one. In a CSV with an empty cell, that silently misaligns the entire rest of the row.

The fix is `-n` / `--non-greedy`, which stops collapsing and preserves the empty field:

```bash
$ echo 'a,,b' | choose -f ',' -n 1
$ echo 'a,,b' | choose -f ',' -n 2
b
```

Now field 1 is the empty cell (a blank line) and `b` correctly sits at field 2. So the rule is: **greedy default for whitespace you're eyeballing, `-n` the moment the delimiter is structural** (CSV, TSV, `/etc/passwd`-style `:`). Forget it on real CSV and `choose` won't error — it'll quietly hand every downstream column the wrong data. And to be blunt: for anything that's genuinely CSV with quoting and embedded commas, neither `choose` nor `cut` is the right tool; that's a job for a real CSV parser. `choose` is for "loosely delimited lines," and it's honest about that if you read `-n` as required, not optional.

## The nice corners worth knowing

A few things `choose` does that are quietly pleasant. Multiple selections in one call, in the order you list them:

```bash
$ echo 'alice bob carol dave' | choose 0 3
alice dave
```

An output separator, so you can re-join with something else in the same breath:

```bash
$ echo 'alice bob carol' | choose -o ',' 0:2
alice,bob,carol
```

Both exclusive-range dialects, if you think in array slices — `-x` flips `:` to exclusive, and Rust's `a..b` / `a..=b` work verbatim:

```bash
$ echo '0 1 2 3 4' | choose -x 1:3
1 2
$ echo '0 1 2 3 4' | choose 1..3
1 2
$ echo '0 1 2 3 4' | choose 1..=3
1 2 3
```

And character-wise slicing with `-c`, for fixed-width lines where the columns are positions, not fields:

```bash
$ echo '2026-07-13' | choose -c 0:3
2026
```

That last one is a small `cut -c1-4` with saner ergonomics.

## Where plain awk and cut still win

`choose` selects fields and stops there — on purpose. `awk` is a whole language: the moment your job grows a condition (`$3 > 200`), a computation (sum column 4), or multi-field logic, you want `awk` back, and `choose` will never grow into it. `cut` is on every POSIX box by default; `choose` is one you have to build and carry. And `choose` gives you no exit-code signal for "found nothing" — an out-of-range field is a silent empty line, exit `0`:

```bash
$ echo 'a b c' | choose 9; echo "exit=$?"

exit=0
```

If you were leaning on a nonzero exit to gate a script, `choose` won't provide it. It's a field-picker, not a matcher or a filter.

## What it costs and the free alternative

It costs nothing — MIT-licensed, no account, no telemetry, no paid tier. The free alternative is already on your machine and it's `cut` and `awk`. The honest trade is ergonomics versus reach and ubiquity: `choose` wins on the common "grab column N" one-liner — cleaner syntax, whitespace-run splitting, negative indices, `-o` re-joining — and `awk`/`cut` win on portability and on anything past pure selection. If you pull a column twice a month, `choose` is a nicety, not a necessity. If you're typing `awk '{print $2}'` a dozen times a day interactively, the shorter form pays for itself by lunch — as long as you never let it near a script without remembering the zero-index.

## What made us close the tab

Not quite closed — `choose` earned a spot next to [fd](/tools/fd-honest-review/), [rg](/tools/ripgrep-honest-review/), and [sd](/tools/sd-honest-review/) for interactive use. But it stays *out* of our scripts, and here are the three caveats in the order they'll bite you:

- **Fields are zero-indexed.** `choose 1` is the *second* column, not the first. The `awk`/`cut` reflex silently picks the wrong field. Use `--one-indexed` if you want familiar numbering, and never mix modes.
- **Your separator is a regex.** `-f '.'` splits on every character. Escape metacharacters (`\.`, `\|`) when you mean them literally.
- **Greedy split eats empty fields.** `a,,b` looks like two fields, not three, so an empty CSV cell shifts every column after it. Add `-n`/`--non-greedy` for any structurally-delimited data.

**When it goes wrong:** if `choose` handed you a column you didn't expect, the culprit is almost always one of those three. Re-run with an explicit field count in your head, remember `0` is the first field, add `-n` if the data is comma- or colon-delimited, and escape the separator if it's a regex metacharacter. None of that is `choose` being hostile — it's `choose` doing exactly what its flags told you it would, quietly, on the wrong column, because you didn't ask for the other behavior.
