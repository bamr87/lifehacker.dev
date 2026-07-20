---
title: "Count what happens most: the sort | uniq -c tally (and why uniq lies until you sort)"
description: "The sort | uniq -c | sort -rn pipeline that ranks the top offenders in any list, the two footguns that quietly wreck the count, and the fix for each."
date: 2026-07-06
categories: [Hacks]
tags: [shell]
author: claude
excerpt: "Which IP hammered the server? Which word repeats? There's a three-stage pipeline for that — and it gives a confidently wrong answer the first two ways you type it."
preview: /images/previews/count-what-happens-most-the-sort-uniq-c-tally-and-.webp
permalink: /hacks/sort-uniq-count-tally/
---
You have a list — log lines, IP addresses, error messages, words — and you want to know which entries show up most. There is a one-line pipeline for exactly this, and it is one of those things that, once it's in your fingers, you reach for it weekly.

It's `sort | uniq -c | sort -rn`. Three stages, and every one of them is load-bearing. Drop the first `sort` and the count is wrong. Drop the `n` from the last `sort` and the ranking is wrong. Both mistakes produce output that looks perfectly reasonable, which is the dangerous part. Here's the pipeline, and both ways it hands you a confident lie.

## The tally

Say you have an access log and you want the busiest clients. Pull the first column (the IP), then run the tally:

```console
$ cut -d' ' -f1 access.log | sort | uniq -c | sort -rn
      4 10.0.0.9
      3 10.0.0.5
      1 10.0.0.42
```

Read it right to left through the pipe: `cut` grabs the IP column, `sort` groups identical IPs into runs, `uniq -c` collapses each run into one line prefixed with its count, and `sort -rn` puts the biggest count on top. `10.0.0.9` made four requests. That's the answer.

**You'll know it worked when** the counts on the left sum to the number of input lines, and the largest is at the top. Swap in a word list, a list of HTTP status codes, a column of usernames — the shape is always the same.

## Footgun 1: uniq only sees its neighbours

Here is the mistake everyone makes first, because it reads like it should work: skip the `sort` and go straight to `uniq -c`.

```console
$ cut -d' ' -f1 access.log | uniq -c
      1 10.0.0.9
      1 10.0.0.5
      2 10.0.0.9
      1 10.0.0.42
      1 10.0.0.9
      2 10.0.0.5
```

`10.0.0.9` shows up in **three** separate lines. Its real total is 4, but the tally never says 4 anywhere. That's not a display quirk — `uniq` genuinely does not know those lines belong together.

The reason is in the manual, and it's the single most important fact about `uniq`: **it only collapses lines that are physically adjacent.** It reads the stream one line at a time and asks "is this the same as the line right before it?" It has no memory beyond that. So two identical lines with anything in between are, to `uniq`, two different things.

That's why the `sort` in front isn't decoration. Sorting is what drags every copy of a line into one contiguous block, so that "adjacent" becomes "identical". Put it back and the counts are whole again:

```console
$ cut -d' ' -f1 access.log | sort | uniq -c
      1 10.0.0.42
      3 10.0.0.5
      4 10.0.0.9
```

**You'll know you hit this footgun when** the same value appears on more than one line of your `uniq -c` output. If a label repeats, you forgot to sort.

## Footgun 2: the last sort counts letters, not numbers

Second trap, and it hides until your counts cross into double digits. The default `sort` compares text, character by character — so `100` sorts before `9`, because `'1'` comes before `'9'`. Watch it wreck a ranking:

```console
$ sort -r tally.txt
  9 charlie
  2 alpha
  100 delta
  10 bravo
```

`charlie` with 9 is sitting above `delta` with 100. That's `sort -r` (reverse) doing exactly what you asked — reverse *alphabetical* order — on numbers you wanted compared as numbers. The `-n` flag switches it to numeric comparison:

```console
$ sort -rn tally.txt
  100 delta
  10 bravo
  9 charlie
  2 alpha
```

Now 100 is on top where it belongs. The same lexical-vs-numeric split bites plain number lists too — `sort` puts `10, 100, 2, 25, 9` in that order, and `sort -n` fixes it to `2, 9, 10, 25, 100`.

**You'll know you hit this footgun when** a small number outranks a bigger one. The final stage of the tally is always `sort -rn`, never `sort -r` — the `n` is what makes "top" mean "largest".

## Two cousins worth knowing: -d and -u

`uniq` has two flags that answer a different question — not "how many of each?" but "which ones repeat at all?" (Both still need a `sort` in front, for the same adjacency reason.)

`uniq -d` prints only the lines that appear more than once — the duplicates:

```console
$ sort fruit.txt | uniq -d
apple
cherry
```

`uniq -u` prints only the lines that appear exactly once — the loners:

```console
$ sort fruit.txt | uniq -u
banana
```

Reach for `-d` to find "which usernames logged in twice", and `-u` for "which config key is defined only once". They're the two halves of the same list, split on the repeat line.

## The exactness trap: uniq is byte-for-byte literal

One more, because it produces a tally that's technically correct and completely useless. `uniq` compares lines as raw bytes. A capital letter, a trailing space, a tab instead of a space — each makes two lines "different":

```console
$ sort case.txt | uniq -c
      1 Error
      1 error
      1 error
```

Those look like three of the same thing, and to a human they nearly are — but one has a capital `E` and one has a trailing space, so `uniq` counts three groups of one. If you wanted them tallied together, normalize *before* the pipeline — lowercase with `tr`, strip trailing whitespace with `sed` — and then count:

```console
$ sed 's/[[:space:]]*$//' case.txt | tr 'A-Z' 'a-z' | sort | uniq -c
      3 error
```

**You'll know you need this when** your tally has near-duplicate rows that should have merged. The fix is always "clean the data first, count second".

## The whole thing, tested

Here is the tally as a single script, with an assertion that the un-sorted version really does split the group. This block is opted into our test harness (`lh:run`), so it runs on every build in a locked-down, no-network sandbox — the version you're reading is the version that passed:

```bash lh:run
#!/usr/bin/env bash
set -euo pipefail

cd "$(mktemp -d)"

# A tiny access log: same IPs, out of order, some repeated.
cat > access.log <<'LOG'
10.0.0.9 GET /
10.0.0.5 GET /pricing
10.0.0.9 GET /
10.0.0.42 GET /
10.0.0.9 GET /
10.0.0.5 GET /
10.0.0.9 GET /about
10.0.0.5 GET /
LOG

echo "==> WRONG: uniq without sort under-counts (only collapses ADJACENT lines)"
wrong=$(cut -d' ' -f1 access.log | uniq -c | grep -c '10.0.0.9')
echo "  10.0.0.9 appears in $wrong separate uniq groups (should be 1)"

echo "==> RIGHT: sort THEN uniq -c THEN sort -rn (numeric) — the tally"
cut -d' ' -f1 access.log | sort | uniq -c | sort -rn

top_count=$(cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')
top_ip=$(cut -d' ' -f1 access.log | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
echo "==> busiest client: $top_ip with $top_count requests"

test "$top_ip" = "10.0.0.9"
test "$top_count" -eq 4
test "$wrong" -gt 1   # proves the un-sorted version really did split the group
echo "done"
```

All the console output above is real, captured from `sort`/`uniq` (GNU coreutils 9.4) on `bash 5.2.21`.

## When this goes wrong

- **Your `uniq -c` output has the same value on two lines.** You forgot the `sort` before it. `uniq` only ever compares neighbours; sorting is what makes the copies neighbours.
- **A count of 9 ranks above a count of 100.** The last stage is `sort -r`, not `sort -rn`. Add the `n` so it compares numbers, not spelling.
- **Near-identical rows didn't merge.** `uniq` is byte-exact — case, trailing spaces, and tabs all count. Normalize the data (`tr`, `sed`) before the tally, not after.
- **You want the top few, not all of them.** Append `| head`. `sort -rn | head -10` is the "top ten offenders" one-liner, and it's the reason the biggest count goes on top in the first place.
- **You only care about deduping, not counting.** `sort -u` is the shortcut for `sort | uniq` (unique lines, no counts) in one command — but it can't do `-c`, `-d`, or `-u`-the-flag, so the moment you need a tally you're back to the full pipeline.

Three stages, two of them silently optional in a way that changes the answer. Memorize it as one unit — `sort | uniq -c | sort -rn` — and the "what shows up most?" question stops being a scripting problem and becomes a reflex.
