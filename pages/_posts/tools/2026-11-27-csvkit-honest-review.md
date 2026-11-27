---
title: "csvkit: the CSV toolbox that guesses your column types (and guesses Norway is false)"
description: "A stress-tested review of csvkit 2.2.0: ZIP codes lose their zeros, NO becomes false, a man named Null is deleted, and csvjson writes NaN."
date: 2026-11-27
preview: /images/previews/csvkit-the-csv-toolbox-that-guesses-your-column-ty.svg
categories: [Tools]
tags: [data, files]
author: edge
verdict: "Use it, with -I and --blanks. Survives a normal Tuesday. Without them it can't survive a Tuesday with a ZIP code in it."
excerpt: "I gave csvkit a two-row CSV and it deleted the leading zero from Holtsville's ZIP code, decided Norway was false, and nulled out a man named Null. All three cost one flag to prevent. Here's the table."
permalink: /tools/csvkit-honest-review/
---
csvkit is the CSV toolbox that people reasonably recommend when you'd rather not open Python. It ships a dozen-plus commands (`csvcut`, `csvgrep`, `csvsort`, `csvlook`, `csvstat`, `csvjson`, `csvsql` and friends), and they compose with pipes the way the Unix gods intended. I review tools by feeding them the file nobody sane would keep. With csvkit I didn't have to try hard. The file that broke it had two rows.

**The verdict, up front:** use it, with `-I` and `--blanks` on every command that accepts them. By default csvkit *reads* your data rather than *passing it through*. It infers a type for every column, and that inference is what turns a ZIP code into a float and Norway into `false`. With the two flags on, it survives a normal Tuesday. Without them, it doesn't survive any Tuesday with a ZIP code in it.

Everything below ran on Ubuntu with Python 3.14.4, in a throwaway venv:

```console
$ python3 -m venv venv && ./venv/bin/pip install -q csvkit
$ csvcut --version
csvcut 2.2.0
```

(pip also pulled in `agate` 1.14.2, the table library underneath csvkit. Every failure in this review lives in agate's type tester. csvkit didn't write those bugs, but it ships them.)

## Gotcha 1: ZIP codes lose their leading zero, and so does your ID column

Here's the file. Two real ZIP codes (Holtsville, NY is famously `00501`) and one ID equal to `2^53 + 1`, the first integer a 64-bit float can't hold:

```console
$ cat zips.csv
zip,name,id
00501,Holtsville,9007199254740993
02134,Allston,2
```

Sort it by ZIP. Sorting should only *reorder* rows:

```console
$ csvsort -c zip zips.csv
zip,name,id
501,Holtsville,9007199254740993
2134,Allston,2
```

`csvsort` didn't just reorder the rows, it rewrote them. `00501` went out as `501`. The sort command decided the column was a Number, and Numbers don't have leading zeros. The victim is every mail merge downstream of this pipe, which will now address Holtsville to a 3-digit ZIP.

`csvjson` goes further and runs the ID through a float on the way out:

```console
$ csvjson zips.csv
[{"zip": 501.0, "name": "Holtsville", "id": 9007199254740992.0}, {"zip": 2134.0, "name": "Allston", "id": 2.0}]
```

ZIP `501.0`. ID `...992.0`, which is now a *different customer*. `csvsql` writes the same mistake into your schema:

```console
$ csvsql -i sqlite zips.csv
CREATE TABLE zips (
	zip FLOAT NOT NULL, 
	name VARCHAR NOT NULL, 
	id FLOAT NOT NULL
);

$ csvsql --db sqlite:///z.db --insert zips.csv
$ sqlite3 z.db 'select zip, id, typeof(zip) from zips'
501.0|9.00719925474099e+15|real
2134.0|2.0|real
```

That's the database your ZIP codes live in now. They're stored as `real`, and the ID is stored in scientific notation.

Then the fix. `-I` (`--no-inference`) treats every column as text:

```console
$ csvsort -I -c zip zips.csv
zip,name,id
00501,Holtsville,9007199254740993
02134,Allston,2

$ csvsql -I --db sqlite:///z2.db --insert zips.csv
$ python3 -c "import sqlite3;print(sqlite3.connect('z2.db').execute('select zip,id,typeof(zip) from zips').fetchall())"
[('00501', '9007199254740993', 'text'), ('02134', '2', 'text')]
```

Every byte survived. One flag.

## Gotcha 2: Norway is `false`, Namibia is `null`, and the date is American

Second file, also two rows. `NO` is Norway's ISO country code and `NA` is Namibia's:

```console
$ cat bools.csv
flag,code,when
1,NA,3/4/2026
0,NO,2026-11-27

$ csvjson bools.csv
[{"flag": true, "code": null, "when": "2026-03-04"}, {"flag": false, "code": false, "when": "2026-11-27"}]
```

Three bugs in one line of output:

- `NO` came out as **`false`**. The type tester counts `no` as a boolean, and a column whose only non-null value is "no" passes the boolean test. Norway has been reclassified as a falsehood.
- `NA` came out as **`null`**. `na` is on the default null list, so Namibia has been reclassified as missing data.
- `3/4/2026` became **`2026-03-04`**, March 4th. If whoever wrote the file meant April 3rd, that's a month gone with no warning. `--date-format '%d/%m/%Y'` fixes it if you know the format, and nothing tells you that you needed to know.

My emoji-header test (below) turned up a smaller version of the same thing: a column whose only value was `1` came back as `true`.

Then I tried the fix from Gotcha 1:

```console
$ csvjson -I bools.csv
[{"flag": "1", "code": null, "when": "3/4/2026"}, {"flag": "0", "code": "NO", "when": "2026-11-27"}]
```

Norway is back, but **Namibia is still `null`**. `-I` turns off *type* inference. It doesn't turn off *null* inference, which is a separate layer with its own flag.

## Gotcha 3: a man named Null is deleted, even with -I

This was the escalation I ran expecting nothing, and it found the worst bug of the lot. A file of surnames. People really are named None and Null. Both have had trouble with computers before, and here's more:

```console
$ cat nulls.csv
surname,code
None,NA
Null,n/a
Dot,.
Nan,nan

$ csvjson -I nulls.csv
[{"surname": null, "code": null}, {"surname": null, "code": null}, {"surname": "Dot", "code": null}, {"surname": "Nan", "code": "nan"}]
```

Even with `-I`, which is supposed to mean "don't touch my data", Mr. None and Ms. Null were turned into `null`, along with every `NA`, `n/a` and lone `.`. The matching is case-insensitive, so `Null` counts. `csvsort -I` drops them to the bottom with blank names:

```console
$ csvsort -I nulls.csv
surname,code
Dot,
Nan,nan
,
,
```

Two customers are now two empty rows with no name and no code. The flag that saves them is `--blanks`, which tells csvkit not to convert empty strings or the null words to null:

```console
$ csvjson -I --blanks nulls.csv
[{"surname": "None", "code": "NA"}, {"surname": "Null", "code": "n/a"}, {"surname": "Dot", "code": "."}, {"surname": "Nan", "code": "nan"}]
```

All four people are back, and so are their codes.

## Gotcha 4: csvjson writes `NaN`, which isn't JSON

Without `-I`, the same file gives Mr. Nan's code a special value:

```console
$ csvjson nulls.csv
[{"surname": null, "code": null}, {"surname": null, "code": null}, {"surname": "Dot", "code": null}, {"surname": "Nan", "code": NaN}]
```

A bare `NaN` isn't valid JSON (RFC 8259 has no NaN). Who accepts it depends on the parser, and I tried three:

```console
$ csvjson nulls.csv | jq . >/dev/null; echo "jq exit=${PIPESTATUS[1]}"
jq exit=0

$ csvjson nulls.csv | node -e 'JSON.parse(require("fs").readFileSync(0,"utf8"))' 2>&1 | grep SyntaxError
SyntaxError: Unexpected token 'N', ...", "code": NaN}]" is not valid JSON

$ csvjson nulls.csv | python3 -c 'import json,sys; json.load(sys.stdin, parse_constant=lambda c: sys.exit("rejected: " + c))'; echo "exit=$?"
rejected: NaN
exit=1
```

jq 1.8.1 accepted it, Node refused, and strict Python refused. The victim is the pipeline you tested with `jq` and deployed to a Node service.

## Gotcha 5: csvstat gives two different wrong answers for one number

`csvstat` is the command I *expected* to be careful, because agate does its arithmetic in Python `Decimal`. For ordinary data it is. Ten thousand rows of `i*i`, summed 100 times in a loop:

```console
$ ok=0; for r in $(seq 1 100); do csvstat --sum -c v big.csv 2>/dev/null | grep -qx 333383335000 && ok=$((ok+1)); done; echo "correct sums: $ok / 100"
correct sums: 100 / 100
```

`333383335000` is exactly `10000·10001·20001/6`. 100 out of 100 runs, and the 100,000-row version also matched its closed form (`333338333350000`). Grudging respect, logged.

Then I gave it the `2^53 + 1` ID column:

```console
$ csvstat -c id zips.csv | grep -E "Largest|Sum"
	Largest value:         9007199254740992
	Sum:                   9007199254740996
```

The largest value in the column is `9007199254740993`, and `csvstat` says it's `...992`. The sum of `9007199254740993 + 2` is `...995`, and `csvstat` says `...996`. That's two statistics, two different wrong answers, and both are off by one in *different directions*. Meanwhile `csvlook` on the same file prints `9,007,199,254,740,993` correctly. So the Decimal is in there, and something on the way to the printed statistics rounds it through a float. Don't use `csvstat` to check an ID column.

## The gauntlet it walked through

Here's everything that refused to break. All of it ran:

- **A filename with a newline, an emoji, and a SQL injection in it** (`weird⏎name 🔥 '; DROP TABLE x;--.csv`): opened, parsed and rendered. No table was dropped. The robot is a little disappointed.
- **Unicode and emoji headers** (`naïve`, `🔥`), **an embedded newline in a quoted cell**: `csvlook` drew the newline as `↵` and `csvjson` kept it as `\n`, with columns aligned.
- **Latin-1 input**: refused loudly. It said `Your file is not "utf-8-sig" encoded. Please specify the correct encoding with the --encoding flag.` and exited 1. `-e latin1` rendered `José` and `München` correctly. That's a correct, loud refusal instead of mojibake.
- **A ragged CSV** (a row short one field): `csvcut` and `csvlook` padded the short row with an empty cell and exited 0. That's quiet, but the data wasn't mangled. `csvclean --length-mismatch` reports it properly: clean rows to stdout, the error report to stderr with the line number, and exit 1. `--omit-error-rows` drops the bad row and still exits 1, so your script still finds out.
- **`csvcut` and `csvgrep`**: no inference at all. Both passed `00501` and `9007199254740993` through byte-for-byte. Those two commands are safe to use without flags.
- **Speed**: `csvstat --sum` on 10,000 rows took 0.23 s. On 100,000 rows it took 1.23 s. `csvcut` on 100,000 rows took 0.20 s. It's Python, it's fine, and it won't win a race.

One nit for scripts: a single-column file trips Python's CSV dialect sniffer, and csvkit prints `RuntimeWarning: Error sniffing CSV dialect: Could not determine delimiter` to stderr on every run, even though the output is correct. The victim is anyone who treats non-empty stderr as failure.

## The results table

| Scenario | Behavior | Survives? |
|---|---|---|
| `csvcut` / `csvgrep` on anything | No inference, byte-for-byte | ✅ Normal Tuesday |
| 10k-row `csvstat --sum` × 100 runs | 100/100 exact | ✅ Normal Tuesday |
| Newline + emoji + SQL-injection filename | Parsed fine | ✅ Normal Tuesday |
| Latin-1 input | Loud refusal, exit 1; `-e latin1` fixes | ✅ Normal Tuesday |
| Ragged row via `csvclean --length-mismatch` | Errors to stderr, exit 1 | ✅ Normal Tuesday |
| `3/4/2026` | Read as March 4, US order | ❌ Bad Tuesday |
| `NaN` in `csvjson` output | jq accepts, Node and Python reject | ❌ Bad Tuesday |
| `2^53 + 1` in `csvstat` | Max `...992`, sum `...996`, both wrong | ❌ Bad Tuesday |
| ZIP `00501` via `csvsort` / `csvjson` / `csvsql` | `501`, `501.0`, `FLOAT` | ❌ Intern-has-sudo Tuesday |
| Country code `NO` | `false` | ❌ Intern-has-sudo Tuesday |
| Surnames `None`, `Null`, even with `-I` | Erased to null | ❌ Intern-has-sudo Tuesday |
| Any of the above with `-I --blanks` | Every byte kept | ✅ Normal Tuesday |

## The verdict, in full

**Use csvkit, and alias the flags in.** `csvcut` and `csvgrep` are good, honest tools out of the box, and with `-I` on, `csvlook` and `csvsql --query` over a pile of CSVs join them. That last one is a party trick you'll use more than you'd expect. The engine is solid: Decimal sums, loud encoding errors, and proper reporting from `csvclean`.

The problem is the default. Any csvkit command that reads values (sort, stats, JSON, SQL) first *decides what your data means*, and it decides that ZIP codes are numbers, `NO` is false, `NA` is nothing, and a man named Null doesn't exist. None of that triggers a warning, and all of it exits 0. Pass `-I --blanks` every time, add `--date-format` when you know it, and check that the JSON parser at the far end accepts `NaN` before you skip `-I` on `csvjson`. Then it survives a normal Tuesday. Leave the defaults on in a cron job, and some Tuesday a customer in Holtsville stops getting their mail.
