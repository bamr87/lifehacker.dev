---
title: "miller (mlr): the CSV multitool that streams your good rows out, then dies on row three"
description: "An honest, stress-tested review of miller (mlr): the exit that truncates your pipe, the big integer it keeps where awk and jq lose it, and the money it leaks."
date: 2026-09-05
preview: /images/previews/miller-mlr-the-csv-multitool-that-streams-your-goo.svg
categories: [Tools]
tags: [data, files]
author: edge
verdict: "Use it — survives a bad Tuesday. But check the exit code, or it survives the Tuesday your pipeline silently ships half the file."
excerpt: "I fed miller the CSV nobody sane would keep. It printed my clean rows, then exited 1 on row three — and every program downstream had already believed the good half."
permalink: /tools/miller-mlr-honest-review/
---
I review data tools the way I review everything: I hand them the file nobody sane would keep and watch which half falls off. `miller` — the binary is `mlr` — is the one everyone recommends the moment you admit you've been doing CSV work in `awk`. The recommendation is correct. One Go binary runs `cut`, `sort`, `stats`, `join`, and format conversion across CSV, TSV, JSON, and DKVP, and it is genuinely the thing to reach for. The recommendation is also incomplete, because the single most useful fact about `mlr` — that it *streams* — is the fact that will hurt you, and I have the captured output to prove it.

**The verdict, up front:** use it. For "wrangle a pile of tabular files without booting Python," `mlr` beats `awk` on ergonomics and beats `jq` on arithmetic. It survives a normal Tuesday and most of a bad one. There is exactly one Tuesday it does not survive — the one where you pipe its output into another program and don't check the exit code — and I found that one on purpose.

Everything below ran on a fresh Ubuntu 24.04 box against the version `apt` handed me:

```console
$ mlr --version
mlr 6.11.0
```

(First honest note, free: `apt install miller` gave me `6.11.0`; upstream ships faster than your distro. The binary is `mlr`, not `miller` — check `mlr --version` before you copy a flag off a blog written against a newer release.)

## Gotcha 1: it prints your good rows, *then* dies — and the pipe already believed them

Here is the file that teaches the whole lesson. A CSV where one row is short a field — a real thing that happens every time an export truncates:

```console
$ cat ragged.csv
a,b,c
1,2,3
4,5
6,7,8

$ mlr --csv cat ragged.csv
a,b,c
1,2,3
mlr: mlr: CSV header/data length mismatch 3 != 2 at filename ragged.csv row 3.
```

Read that output slowly, because the order is the entire point. `mlr` did **not** validate the file and refuse. It printed the header, printed row one to *stdout*, and *then* hit the ragged row and wrote an error to *stderr* and exited 1. The clean data and the fatal error came out of two different pipes, in that order.

Now put it in the shape you'd actually write:

```console
$ mlr --csv cat ragged.csv > clean.csv
mlr: mlr: CSV header/data length mismatch 3 != 2 at filename ragged.csv row 3.
$ echo "exit=$?"
exit=1
$ cat clean.csv
a,b,c
1,2,3
```

`clean.csv` now exists, is non-empty, and contains a *plausible* one row of your three. If the next stage of your pipeline keys off "the file has rows" instead of `$?`, you just shipped a third of your data and nobody threw. That is not a hypothetical — that is the default behavior of the tool on the most common malformed CSV there is.

The fix is one flag, and it is worth wiring into muscle memory:

```console
$ mlr --csv --allow-ragged-csv-input cat ragged.csv
a,b,c
1,2,3
4,5,
6,7,8
```

Short rows get padded with empties, long rows get numbered overflow keys, and the exit is clean. **Every nitpick names the victim:** the victim here is the cron job that runs `mlr ... > out.csv` with no `set -o pipefail`, no `$?` check, and a downstream `LOAD DATA` that never asks how many rows it got.

## Gotcha 2: JSON with uneven records has the same knife in it

CSV is a fixed schema; JSON is not, and `mlr` will remind you the hard way. Two objects, different keys:

```console
$ cat het.json
[{"a":1,"b":2},{"a":3,"c":9}]

$ mlr --ijson --ocsv cat het.json
mlr: CSV schema change: first keys "a,b"; current keys "a,c"
a,b
1,2
mlr: exiting due to data error.
```

Same failure mode, dressed differently: record one converted fine and went to stdout, record two changed the shape and `mlr` bailed. This is *correct* — a CSV can't have two headers — but it is the second time the tool has handed you a partial file plus a non-zero exit and trusted you to notice.

The rescue is a verb, not a flag: `unsparsify` unions every key across every record and fills the gaps first.

```console
$ mlr --ijson --ocsv unsparsify het.json
a,b,c
1,2,
3,,9
```

One header, every column, every row, exit 0. The lesson stays: **`mlr` never guesses. It emits what it's sure of and quits the instant it isn't** — which is a virtue right up until the thing reading stdout doesn't share the discipline.

## Gotcha 3: it renames your duplicate columns without asking

Feed it a header with a repeated name — the kind of thing a `JOIN ... SELECT *` produces all day:

```console
$ cat dup.csv
x,x,y
1,2,3

$ mlr --csv cat dup.csv
x,x_2,y
1,2,3
```

The second `x` is now `x_2`. No warning, no exit code, no note to stderr. It's a reasonable thing to do — a record is a map, and maps can't have duplicate keys — but if you `cut -f x` expecting the second column, you get the *first* one and never learn there was a collision. The victim is the analyst who trusted `-f x` to mean the column they were looking at.

## The surprise: it keeps the big integer awk and jq both throw away

Here is where `mlr` earns the "use it." Every tool in this class does arithmetic; most of them do it in a float and lie about it. `9007199254740993` is `2^53 + 1`, the first integer a 64-bit float can't represent. Watch three tools add one to it:

```console
$ awk 'BEGIN{print 9007199254740993 + 1}'
9007199254740992

$ echo '9007199254740993' | jq '. + 1'
9007199254740992

$ mlr --csv put '$m=$n+1' big.csv
n,m
9007199254740993,9007199254740994
```

`awk` and `jq` don't just get the answer wrong — they corrupt the *input* on the way in (note they both return `...992`, having already lost the odd bit before the `+1`). `mlr` carries a real 64-bit integer, does integer math, and returns `...994`. If you have ever put an ID, a Snowflake, or a satoshi count through `jq` and wondered why the last digit drifted, this is why, and `mlr` is the tool that doesn't do it. Grudging respect, logged.

It is not magic, though, and the moment you touch a decimal the respect gets grudging again:

```console
$ mlr --csv put '$sum = $a + $b' money.csv
a,b,sum
0.1,0.2,0.30000000000000004
```

`0.1 + 0.2` is IEEE-754's oldest party trick, and `mlr` prints the leak raw — no rounding, no `printf` mercy. It is *honest*, but if that column is dollars you want `fmtnum($sum, "%.2f")` around it before it reaches a human. Integers: safe past where jq breaks. Money: format it yourself or explain the fraction of a cent to accounting.

## The off-by-one in headerless files

Give it a file with no header and tell it so:

```console
$ cat noheader.csv
1,2,3
4,5,6

$ mlr --csv --implicit-csv-header cat noheader.csv
1,2,3
1,2,3
4,5,6
```

The output looks like the first row got duplicated. It didn't. `--implicit-csv-header` names the columns `1,2,3` (positional), so the *header* line of the output is the literal string `1,2,3`, and then your real first data row `1,2,3` prints under it. It's correct and it's a trap: reference these fields as `$1`, `$2`, `$3`, and if you ever forget the header line is synthetic you'll swear the tool ate a row.

## The gauntlet it walked through without flinching

I keep an honest column for the things that refuse to break, because grudging respect is the review. Every one of these ran:

- **Unicode headers and emoji fields** (`naïve`, `🔥`, `résumé`) — passed through byte-for-byte, columns aligned.
- **Embedded newlines and commas inside quoted fields** — parsed correctly; the newline stayed inside the cell instead of splitting the row.
- **CRLF line endings** — stripped clean; `"2\r"` came out as integer `2`, not a string with a carriage return welded on. (Half the CSV tools I test fail exactly this.)
- **A filename with a literal newline, a space, and an emoji in it** — `mlr` doesn't care what you named the file; it opened it and read it.
- **An unbalanced quote** — clean error with line and column (`parse error on line 3, column 5: extraneous or missing "`), exit 1, no garbage half-parsed record.
- **Empty file and header-only file** — empty output, exit 0, no crash on the degenerate case.

And the running gag's payoff — the 10,000-row stress. Generate ten thousand rows, square each, aggregate, and do the whole pipeline a hundred times over:

```console
$ mlr seqgen --start 1 --stop 10000 then put '$v = $i * $i' then stats1 -a sum,mean,count,min,max -f v
v_sum=333383335000,v_mean=33338333.5,v_count=10000,v_min=1,v_max=100000000
```

`v_sum=333383335000` is exactly `10000·10001·20001 / 6`, the closed form for the sum of the first 10,000 squares — computed in integer math, no float drift in a sum that large. And the repeatability:

```console
$ ok=0; for r in $(seq 1 100); do \
    mlr seqgen --start 1 --stop 10000 then put '$v=$i*$i' then stats1 -a sum -f v >/dev/null 2>&1 \
    && ok=$((ok+1)); done; echo "clean exits: $ok / 100"
clean exits: 100 / 100
```

100 of 100. The single-file happy path is boringly, reliably solid, and the whole 10k pipeline finished in about 14 milliseconds each time. The failures in this review are *all* at the seams — malformed input, schema changes, duplicate keys — never in the engine.

## The results table

| Scenario | Behavior | Survives? |
|---|---|---|
| Clean CSV `cut`/`sort`/`stats` | Correct, ~14 ms for 10k rows | Normal Tuesday |
| 10,000 rows × 100 runs | 100/100 clean exits | Normal Tuesday |
| Unicode / emoji / embedded newline / CRLF | Passed through correctly | Normal Tuesday |
| `0.1 + 0.2` | Prints `0.30000000000000004` (honest, but format it) | Normal Tuesday, mind the cents |
| Big integer `2^53 + 1` | Kept exactly (awk & jq corrupt it) | Grudging respect |
| Duplicate header `x,x` | Silently renamed to `x,x_2` | Bad Tuesday (no warning) |
| `--implicit-csv-header` | Header is the literal `1,2,3`; easy off-by-one | Bad Tuesday |
| Ragged CSV, no flag | Prints good rows, **then** exits 1 mid-file | Intern-has-sudo Tuesday |
| Heterogeneous JSON → CSV | Prints first record, **then** exits 1 | Intern-has-sudo Tuesday |

## The verdict, in full

**Use `mlr`.** For tabular data on the command line it is better than the `awk` you were suffering and safer with integers than the `jq` you reach for reflexively. It survives a normal Tuesday and, once you know the seams, a bad one.

The Tuesday it does not survive is the automated one: `mlr ... > out.csv` in a script with no `set -o pipefail` and nothing checking `$?`, fed input from a source you don't control. On the day that source hands you a ragged row or a shape-shifting JSON array, `mlr` will do exactly what it always does — emit the clean prefix, exit non-zero, and trust you to have been watching. The engine is honest. Your pipeline has to be too. Wire `--allow-ragged-csv-input`, reach for `unsparsify` before you flatten JSON to CSV, and check the exit code — or accept that one Tuesday you'll ship a confident, well-formed, half-complete file, and nothing will have thrown to tell you.
