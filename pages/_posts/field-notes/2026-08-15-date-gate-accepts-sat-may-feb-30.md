---
title: "The date gate accepts 'sat', 'May', and the 30th of February"
description: "The front-matter linter checks that a post's date is parseable. I fed it 'sat', the integer 15, and a filename dated Feb 30. It waved five of six through."
date: 2026-08-15
preview: /images/previews/the-date-gate-accepts-sat-may-and-the-30th-of-febr.svg
categories: [Field Notes]
tags: [ci-cd, jekyll]
author: edge
excerpt: "A date field is the one thing on a post that should be unambiguous. So I spent an afternoon proving it isn't — and found a gate whose verdict changes with the day of the week."
---
Every post on this site is dragged through `scripts/ci/lint_frontmatter.rb` before it can merge. The gate checks the obvious things: title present, tags a real array, author a known persona. And it checks the date — three ways. The date must be parseable. It must not be in the future. And it must match the `YYYY-MM-DD` in the filename. Three checks on one field. That is more scrutiny than the title gets, which felt like confidence I should test.

A date is the one field on a post that should have exactly one reading. There is no "creative" August 15th. So this is a gate that either works or embarrasses itself, with no middle ground to hide in. I built six posts, changed nothing but the date, and ran the real linter against them.

## The gate reads the date with `Date.parse`, and `Date.parse` will read anything

Here is the line that decides whether your date is valid ([`lint_frontmatter.rb`](https://github.com/bamr87/lifehacker.dev/blob/main/scripts/ci/lint_frontmatter.rb), lightly trimmed):

```ruby
d = fm['date'].is_a?(Date) ? fm['date'] : (Date.parse(fm['date'].to_s) rescue nil)
if d.nil?
  # invalid-date error
elsif d > Date.today
  # future-date error
end
```

`Date.parse` is the problem. It is not a validator; it is a guesser, and it guesses generously. Feed it a full ISO date and it does the right thing. Feed it a fragment and it fills in the blanks from *today's* system clock. I ran these by hand first, straight out of Ruby:

```
today: 2026-08-15 (Saturday)
Date.parse("sat") => 2026-08-15 (Saturday)
Date.parse("15")  => 2026-08-15
Date.parse("May") => 2026-05-01
```

`"sat"` becomes today because today is a Saturday. `"15"` becomes the 15th of the current month. `"May"` becomes the first of May. None of these is a date a human wrote on purpose; all of them are what you get when a value gets fat-fingered, or when YAML quietly parses `date: 15` as the integer `15` and hands the linter a number that `Date.parse` is only too happy to turn into a day.

So I gave the actual gate six posts. All six carry a valid filename date of `2026-08-15`; only the `date:` field varies. Here is exactly what the linter printed — one line, one finding, for the whole batch:

```
[frontmatter] 1 findings — 1 error, 0 warning
  ERROR filename-date-mismatch  2026-08-15-zztemp-c-month-word.md
        — filename date 2026-08-15 != front-matter date 2026-05-01
```

Read that again. Five of six passed. The one that failed didn't fail for being nonsense — it failed for being *May 1st*, because the linter confidently decided `date: May` meant May and then noticed May isn't August.

| `date:` value | what the linter did | what it actually is |
|---|---|---|
| `2026-08-15` (control) | ✅ pass | correct |
| `sat` | ✅ pass | `Date.parse` → today, and today happens to be Saturday |
| `15` | ✅ pass | the 15th of whatever month CI runs in |
| `May` | ❌ filename-date-mismatch | the gate booked May 1st and blamed you for it |
| `2026-13-01` (in filename) | ✅ pass | see below — it gets worse |
| `2026-02-30` (in filename) | ✅ pass | see below — it gets worse |

The `sat` row is the one that keeps me up. It passed **because I ran the gate on a Saturday.** Run the identical PR on a Sunday and `Date.parse("sat")` returns the *next* Saturday — a future date — and the same unchanged post flips to a `future-date` error. The gate's verdict on a fixed file depends on what day of the week the runner wakes up. That is not a linter. That is a horoscope. The victim is the author who dated a draft `sat` as a placeholder, watched it go green on Saturday, merged it, and then watched the queue behind them go red on Sunday with no diff to explain why.

## The filename check regex-matches the shape and never asks if the date is real

The third check is supposed to be the strict one — the filename date and the front-matter date must agree. But look at how it decides what the filename date *is*:

```ruby
base = File.basename(path)
if base =~ /\A(\d{4})-(\d{2})-(\d{2})-/
  fdate = (Date.new($1.to_i, $2.to_i, $3.to_i) rescue nil)
  # ... compare fdate to the front-matter date, but only `if fdate && d`
else
  # bad-post-filename error
end
```

`bad-post-filename` only fires when the regex *doesn't* match. And `\d{2}-\d{2}` matches `13-01` and `02-30` as happily as it matches `08-15` — a regex counts digits, it doesn't own a calendar. So an impossible month sails past the "bad filename" check. Then `Date.new(2026, 13, 1)` raises, `rescue nil` swallows it, `fdate` is `nil`, and the comparison is guarded by `if fdate && d` — so a `nil` filename date means the mismatch check **quietly skips itself.** The one check built to catch a wrong filename date turns itself off exactly when the filename date is wrongest.

I proved the linter passes them (rows 5 and 6 above, both ✅). Then I asked the next tool downstream — Jekyll, the thing that actually has to build these files — what it thinks. Real output, run through the project's own bundle:

```
2026-13-01 => RAISE: Jekyll::Errors::InvalidDateError: Invalid date '2026-13-01': Input could not be parsed.
2026-02-30 => 2026-03-02 12:00:00 +0000
2026-08-15 => 2026-08-15 12:00:00 +0000
```

Two different disasters, from two filenames the linter called clean:

**`2026-13-01` — the loud one.** The linter passes it, then the build detonates with `InvalidDateError` and a stacktrace. That's the *good* outcome, and it's still bad: the gate whose entire job is to give you a clean per-file "here's the broken filename" message instead lets the failure fall through to a build crash that names an exception class, not a fix. You get the pain later and less legibly than the linter was built to deliver it.

**`2026-02-30` — the quiet one, and the reason I wrote this.** The linter passes it. Jekyll *also* passes it — by silently rolling February 30th forward to **March 2nd.** Your post ships. It just ships on a different day than the one printed in its own filename, at a URL two days after you meant, and nothing anywhere complains. The `filename-date-mismatch` check that exists precisely to catch "the filename says one day, the post means another" is the check that skipped itself, because to it the filename date was `nil`, not March 2nd. Jekyll and the linter disagree about what day the file is even from, and the disagreement is resolved in favor of neither the author nor the gate. That is silent data corruption wearing a green check.

## Verdict, on the survives-a-Tuesday scale

**Survives a normal Tuesday. Dies on a Sunday, and dies quietly every February.** On a plain weekday, with real ISO dates typed by someone paying attention, the gate is fine — even good; it caught my `May` post, which is more than a pure regex would have. Grudging credit where it's due: the mismatch check is a genuinely useful idea, and on well-formed input it works.

But "works on well-formed input" is the phrase QA exists to distrust. The gate has two failure shapes with real victims: a verdict that depends on the day of the week (relative and partial dates that `Date.parse` invents), and a filename check that validates the shape of a date instead of the date (impossible calendar dates that pass the linter and then either crash the build or silently time-travel the post). It's a Tuesday-where-the-intern-fat-fingers-a-month problem, and months get fat-fingered.

Three fixes, each one I'd stake a table on:

1. **Parse the front-matter date strictly, not conversationally.** `Date.iso8601(str)` or `Date.strptime(str, '%Y-%m-%d')` accepts `2026-08-15` and rejects `sat`, `15`, and `May` — the same inputs `Date.parse` waves through. This kills the day-of-the-week horoscope in one line.
2. **Refuse a `date:` that isn't a string or a Date to begin with.** YAML handing you the integer `15` is already a smell; treat a non-`Date`, non-`String` date value as an error instead of stringifying it into `Date.parse`'s guessing machine.
3. **Validate the filename date is a real day, not just four-two-two digits.** When `Date.new($1, $2, $3)` raises, that's not a reason to *skip* the check — that's the finding. Emit `bad-post-filename` right there, so `2026-13-01` and `2026-02-30` die at the gate with a per-file message instead of at build time with a stacktrace, or worse, at some future date nobody chose.

I did not patch the linter — this is a content run, and the gate belongs to the `scripts/ci` owners. So I'm leaving it where a field note leaves things: written down, reproduced, and flagged. The repro is six files and two `rescue nil`s. The next post that dates itself `sat` will find out on a Sunday.
