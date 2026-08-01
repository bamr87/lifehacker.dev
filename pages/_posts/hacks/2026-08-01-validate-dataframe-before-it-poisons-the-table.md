---
title: "Validate the DataFrame before it poisons your table: a pandera schema and a quarantine bin"
description: "A DataFrame from upstream is untrusted input. A pandera schema with lazy=True, a quarantine bin instead of a silent drop, and the batch check rows miss."
date: 2026-08-01
categories: [Hacks]
tags: [data, security]
author: cass
excerpt: "That DataFrame came from somewhere you don't control. It is untrusted input, and you are about to write it straight into the table your dashboards trust. Let me threat-model that for you."
preview: /images/previews/validate-the-dataframe-before-it-poisons-your-tabl.svg
permalink: /hacks/validate-dataframe-before-it-poisons-the-table/
---
Somewhere right now, a scheduled job is reading a CSV a vendor emailed, loading it into a DataFrame, and writing it straight into the table your finance dashboard reads from. Nobody looked at it. Nobody will, until the number is wrong in a board deck. I threat-model this instead of sleeping.

Here is the scenario I lie awake on. The DataFrame is **untrusted input**. It crossed a trust boundary — the edge of a system you control — carrying whatever the upstream had that day: a null where a price should be, a negative amount from a refund coded wrong, the same order ID twice because their export ran during a retry, a country field that says `ZZ`. Your loader doesn't care. `df.to_sql(...)` is a firehose pointed at your warehouse, and it will happily pump all of it downstream, where it becomes six clean-looking rows that quietly move an average.

**SEVERITY:** the quarterly numbers. **ATTACK VECTOR:** a file you did not write, loaded by a script that trusts everyone.

Now let me walk that back to the boring true version, because the boring true version is the one that pages you. There is no attacker here — that's the point, and it's worse. Bad data doesn't need a motive. It just needs a pipeline with no gate at the front door, and most pipelines have exactly that. (The idea came off it-journey.dev's [Data Quality Engineering](https://it-journey.dev/quests/1100/data-quality/) quest; this is the paranoid director's cut.)

A validation library is a firewall for rows. I used [pandera](https://pandera.readthedocs.io/) because it treats the schema as a first-class object you can test, version, and point at every frame that tries to get in. Everything below I ran on a throwaway frame with `pandas 3.0` and `pandera 0.32`, so you can watch it work somewhere that doesn't matter.

```console
$ pip install pandas pandera
$ python3 -c "import pandera; print(pandera.__version__)"
0.32.1
```

Here is the payload up front, because the paranoia is the bit and the mitigations are the point. **Three gates, ranked by how much of the incident they stop.**

## Gate 1: a schema at the front door, in one pass

Write down what a valid row *is* — not in a comment, in code the machine enforces. A `DataFrameSchema` is a per-column contract: type, nullability, ranges, uniqueness, regex format.

```python
import pandera.pandas as pa
from pandera import Column, Check

schema = pa.DataFrameSchema({
    "order_id": Column(int,   Check.gt(0), unique=True),
    "email":    Column(str,   Check.str_matches(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")),
    "amount":   Column(float, Check.in_range(0, 10_000), nullable=False),
    "country":  Column(str,   Check.isin(["US", "CA", "GB", "DE"])),
})
```

Now the part everyone gets wrong. If you call `schema.validate(df)` the default way, it is a fail-*fast* validator: it dies on the first bad column and tells you nothing about the other five. You fix that one, rerun, discover the next. That's a denial-of-service you inflict on yourself — an afternoon spent playing whack-a-mole with a file that was fully broken on line one.

The flag that fixes it is `lazy=True`: run every check, collect every failure, raise once. I fed it a frame rigged with a duplicate ID, a malformed email, an out-of-range amount, a negative amount, and an illegal country — and asked for the whole rap sheet:

```python
try:
    schema.validate(df, lazy=True)
    print("all rows passed")
except pa.errors.SchemaErrors as exc:
    print(exc.failure_cases[
        ["schema_context", "column", "check", "failure_case", "index"]
    ].to_string(index=False))
```

```console
schema_context   column                                     check failure_case  index
        Column order_id                          field_uniqueness            2      1
        Column order_id                          field_uniqueness            2      2
        Column    email str_matches('^[^@\s]+@[^@\s]+\.[^@\s]+$')         nope      1
        Column   amount                        in_range(0, 10000)         -3.0      2
        Column   amount                        in_range(0, 10000)      99999.0      3
        Column  country            isin(['US', 'CA', 'GB', 'DE'])           ZZ      3
```

**You'll know it worked when** one run hands you every bad cell with its column, the rule it broke, the offending value, and the row `index`. That last column is not decoration — it's the whole reason Gate 2 is possible.

## Gate 2: quarantine, never `/dev/null`

Here is the mitigation that everyone skips because it feels productive to skip it. When you catch bad rows, the tempting move is `df.dropna()` or a filter that throws them away, and the pipeline is green again, and you feel efficient.

You have just built the bug you cannot debug. Three days later someone asks *where did order 40 go*, and the honest answer is "a script deleted it and told no one." A silent drop is data loss with a clean conscience. It is the deleted-logs of data engineering: the incident is invisible precisely because the evidence was the thing you destroyed.

So don't drop. **Route.** The failing rows go to a quarantine table — a holding cell you can query — and only the clean rows proceed. The `index` column from Gate 1 tells you exactly which is which:

```python
try:
    clean = schema.validate(df, lazy=True)
    quarantine = df.iloc[0:0]           # empty; nothing failed
except pa.errors.SchemaErrors as exc:
    bad_index = exc.failure_cases["index"].dropna().unique()
    quarantine = df.loc[bad_index].copy()
    clean = df.drop(index=bad_index)
```

```console
CLEAN (goes to the table):
   order_id    email  amount country
0         1  a@x.com    12.5      US

QUARANTINE (goes to the sin bin, not /dev/null):
   order_id    email   amount country
1         2     nope     40.0      CA
2         2  c@x.com     -3.0      GB
3         4  d@x.com  99999.0      ZZ

kept 1  quarantined 3  of 4
```

**You'll know it worked when** the rows you rejected still exist somewhere you can `SELECT` them — with a timestamp and the reason attached, in production. A quarantine table you never read is just a slower `/dev/null`, so wire an alert to its row count. Three of four quarantined is not "the pipeline ran clean." It's a page.

## Gate 3: guard the batch, not just the row

Now the failure that stays in, because it's the one that got past me the first time I trusted a schema. Every check in Gate 1 is a *row-level* rule: it looks at one cell at a time. So a batch where every individual row is spotless can still be catastrophically wrong — and the schema will wave it straight through, smiling.

Watch. Same schema, a frame where every row is valid, but there are three of them instead of yesterday's thousand:

```python
today = pd.DataFrame({"order_id": [1, 2, 3], "amount": [10.0, 20.0, 30.0]})
schema.validate(today, lazy=True)          # no exception
print("schema.validate: PASSED — every row is valid")

expected, got = 1000, len(today)
drop = 1 - got / expected
print(f"row-count check: expected ~{expected}, got {got}  -> {drop:.0%} drop")
if drop > 0.5:
    print("BATCH REJECTED: the rows are fine, the batch is not")
```

```console
schema.validate: PASSED — every row is valid
row-count check: expected ~1000, got 3  -> 100% drop
BATCH REJECTED: the rows are fine, the batch is not
```

The schema is delighted. Your dashboard is about to flatline, because the upstream export half-failed and handed you 0.3% of the day's orders, each one immaculate. Row validation is necessary and it is not sufficient. You also need a check on the *shape of the batch* — row count against a rolling baseline, a null-rate that shouldn't triple overnight, a sum that shouldn't halve — the aggregate tells you the individual rows never can.

**You'll know it worked when** a batch that's 3 rows instead of 1,000 gets held for a human even though not one row broke a single rule.

## When this goes wrong

- **Trusting the schema to catch a batch problem.** It won't. That's Gate 3, and Gate 3 is a different check with a different shape. Ship both.
- **`lazy=True` on a genuinely enormous frame.** Collecting every failure costs memory; on a frame that's mostly bad, you're materializing a large failure report. Validate a sampled slice for the shape, or accept the cost knowingly — but do not silently switch back to fail-fast to save RAM and lose the report.
- **A quarantine table nobody watches.** Same failure mode as logging to a file you never open. The rejected rows are only a mitigation if their count is on a dashboard with an alert. Otherwise you've automated the shrug.
- **Assuming this is only about typos.** Input validation is the oldest security control there is, and "it's internal data from a trusted vendor" is the exact sentence that precedes every bad load. The DataFrame doesn't know it's trusted. Neither should your loader.

I distrust convenience features on principle, and `df.to_sql(df_that_came_from_outside)` with no gate in between is the most convenient one in the building. Put the firewall at the front door. Keep the rows you turn away. And remember that a schema that passes every row can still be lying to you about the batch — which, if you've read this far, you already suspected, because you're finally as paranoid as the data deserves.
