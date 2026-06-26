---
title: "Stop fighting Excel: grep, awk, and a month-end close for million-row CSVs"
description: "Excel quits at 1,048,576 rows. grep filters and awk totals a ledger of any size in one second — plus the header row that silently made my first total wrong."
date: 2026-02-23
preview: /assets/images/ai-erp-control.png
collection: hacks
author: amr
excerpt: "Excel truncates at a million rows. grep and awk don't care how big the file is — here's the month-end close that fits on one screen."
tags: [bash, awk, grep, csv, finance]
---

![A retro AI control room standing in for an ERP/accounting back office](/assets/images/ai-erp-control.png)

It is 11:47 PM on the last day of the month and the controller has sent you a 2 GB CSV with the subject line "URGENT." You double-click it. Excel opens. The cursor turns into a beach ball. The fan spins up. Then Excel renders the first 1,048,576 rows and quietly tells you it dropped the remaining 340,000, because a million rows is its ceiling and your ledger went past it.

The numbers you are about to reconcile are wrong before you have typed a single formula. That is the problem.

There is a tool that does not load the whole file into memory, does not have a row limit, and is already installed: the shell. Two commands cover most of a month-end close — `grep` to filter, `awk` to add things up. This is the part that replaces the spreadsheet, not the part where you learn to program.

## The two commands, in one sentence each

`grep` keeps the lines that match a pattern and throws the rest away. `awk` reads a file line by line, splits each line into columns, and lets you do math on a column. That is enough to filter a ledger and total it. Everything below is those two ideas.

## Run it yourself

Here is a self-contained version. It builds a tiny sample ledger inline so there is nothing to download, then runs the same filter-and-total you would run on the real 2 GB file. The shape of the commands does not change with the file size — only the runtime does.

```bash
cd "$(mktemp -d)"
# Build a tiny sample ledger inline — no network, no extra files needed.
cat > ledger.csv <<'CSV'
date,vendor,reference,category,amount
2026-02-03,Acme Office,INV-1001,Office Supplies,128.40
2026-02-07,CloudHost,INV-1002,Software,499.00
2026-02-11,Acme Office,INV-1003,Office Supplies,76.10
2026-02-14,Skyline Travel,INV-1004,Travel,1820.55
2026-02-19,CloudHost,INV-1005,Software,499.00
2026-02-22,Acme Office,INV-1003,Office Supplies,76.10
2026-03-02,CloudHost,INV-1006,Software,499.00
CSV

# 1) grep: pull only February's Office Supplies rows.
echo "== Office Supplies in Feb =="
grep '^2026-02' ledger.csv | grep 'Office Supplies'

# 2) awk: total the amount column (5) for February only.
echo
echo "== February total (all categories) =="
awk -F',' '$1 ~ /^2026-02/ {sum += $5} END {printf "$%.2f\n", sum}' ledger.csv

# 3) awk: subtotal by category for February.
echo
echo "== February subtotals by category =="
awk -F',' '$1 ~ /^2026-02/ {cat[$4] += $5} END {for (c in cat) printf "%-16s $%.2f\n", c, cat[c]}' ledger.csv | sort

# 4) duplicate reference check (column 3).
echo
echo "== Duplicate reference numbers =="
awk -F',' 'NR>1 {print $3}' ledger.csv | sort | uniq -d
```

We ran that block. Here is the real output:

```
== Office Supplies in Feb ==
2026-02-03,Acme Office,INV-1001,Office Supplies,128.40
2026-02-11,Acme Office,INV-1003,Office Supplies,76.10
2026-02-22,Acme Office,INV-1003,Office Supplies,76.10

== February total (all categories) ==
$3099.15

== February subtotals by category ==
Office Supplies  $280.60
Software         $998.00
Travel           $1820.55

== Duplicate reference numbers ==
INV-1003
```

You'll know it worked when the category subtotals add up to the grand total: `280.60 + 998.00 + 1820.55 = 3099.15`. They do. And `uniq -d` found that `INV-1003` was entered twice — the kind of thing that hides in row 40,118 of a real file and quietly inflates your numbers.

Read the pieces back:

- `-F','` tells `awk` the columns are separated by commas.
- `$1`, `$4`, `$5` are the first, fourth, and fifth columns — date, category, amount.
- `$1 ~ /^2026-02/` is the filter: only act on rows whose date starts with `2026-02`. That is what keeps March out of the February total.
- `{sum += $5}` runs on every matching row; `END {...}` runs once, after the last line, to print the result.

## The part where it broke

My first total was wrong, and it was wrong in the most boring way possible.

The original total command had no date filter — it was plain `awk -F',' '{sum += $5} END {...}'`. Two problems hit at once.

First, it summed *every* row, including the `2026-03-02` line, so February's "total" quietly included a March software charge. The number looked plausible. That is the dangerous part — a wrong total that looks right does not announce itself.

Second, and this is the one that actually bites the first time: `awk` tried to add the header. Row one is `date,vendor,reference,category,amount`. Column 5 of that row is the text `amount`, and `awk` reads non-numeric text as `0` when you do math on it — so it does not crash, it silently treats the header as a zero-dollar transaction. You get no error. You get a total that is off by exactly the header, which is usually nothing, until the day someone's amount column has a stray label in it and the discrepancy is real money.

The fix is the same `$1 ~ /^2026-02/` filter that scopes the month: a date-pattern match never matches the header line (the header's first column is the word `date`, not a `2026-02` date), so it excludes both March *and* the header in one move. For the duplicate check I used `NR>1` instead — `NR` is the row number, so `NR>1` means "skip the header." Two different ways to dodge the same row-one trap; pick whichever reads clearly.

The lesson that survives past this example: in `awk`, a row that does not parse the way you expect does not error out. It contributes a zero and moves on. Always scope what you are summing, and always sanity-check the total against subtotals that have to add up.

## When this goes wrong elsewhere

- **Commas inside quoted fields.** A vendor named `"Smith, Jones LLC"` has a comma *inside* a field, and `-F','` will split it into two columns, shifting every column after it. Plain `awk` does not understand CSV quoting. If your data has quoted commas, that is the moment to reach for a real CSV parser, not a bigger `awk` one-liner.
- **Numbers with `$` or thousands separators.** `awk` reads `1,820.55` as `1` (it stops at the comma) and `$1820.55` as `0`. Strip currency symbols and separators before you total, or your sum will be confidently wrong.
- **Windows line endings.** A file saved on Windows ends each line with `\r\n`. The trailing `\r` rides along on the last column and can wreck a numeric compare. `sed 's/\r$//'` first if your totals look haunted.

## The honest accounting

This does not make you a programmer and it does not replace your ERP. What it does is give you a total that is actually computed over every row instead of the first million Excel was willing to load — and a one-line duplicate check that runs in the time it takes Excel to show the splash screen.

The real win is not speed. It is that the steps are written down. When an auditor asks how you got the number, "here is the four-line command I ran, against this exact file" is a better answer than "I applied some filters and I think I used a VLOOKUP."

## Level up

The deeper, gamified versions of this live on the sister site, [it-journey.dev](https://it-journey.dev), as quests:

- [Terminal Fundamentals](https://it-journey.dev/quests/0000/terminal-fundamentals/) — moving around the file system, pipes, and redirection (the `|` and `>` that chain these commands together).
- [Bashcrawl](https://it-journey.dev/quests/0000/bashcrawl/) — learn `cd`, `ls`, `cat`, and `grep` by playing a dungeon crawler in your terminal.
- [bashrun and Beyond](https://it-journey.dev/quests/0000/side-quests/bash-run/) — variables, loops, and conditionals, for when the one-liner grows into a real month-end script.

Open a terminal, paste the block above, and watch the subtotals add up. That is the whole trick.
