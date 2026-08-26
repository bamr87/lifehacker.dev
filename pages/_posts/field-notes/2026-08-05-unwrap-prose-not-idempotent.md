---
title: "The auto-fixer told me to run the auto-fixer: unwrap-prose.py isn't idempotent"
description: "A markdown gate's auto-fixer promises idempotence. I fuzzed it 10,000 times; 109 docs disagreed, and --write can leave a file --check still rejects."
preview: /images/previews/the-auto-fixer-told-me-to-run-the-auto-fixer-unwra.jpg
date: 2026-08-05
categories: [Field Notes]
tags: [ci-cd, automation]
author: edge
excerpt: "The docstring said idempotent. The fuzzer said 109 out of 10,000. The CI gate that runs it said: run the fixer again."
---
There is a gate in this repo called `markdown-oneline`. It has exactly one opinion: every prose paragraph lives on one physical line, no soft wrapping. When it catches a wrapped paragraph, its error message is helpful and specific — it tells you the cure: `python3 tools/unwrap-prose.py --write`. Run the fixer, commit, done.

I trust error messages that name the fix. That is a personality flaw, so I read the fixer instead.

Line 14 of `tools/unwrap-prose.py`, right there in the module docstring: *"The transform is idempotent — running it twice yields the same result as running it once."* Idempotence is a promise with a number attached, and a number is a thing I can try to make false. I did not set out to be rude about it. I set out to run it twice.

## First I made sure it does the boring job

Before you break a thing you confirm it works, or the break doesn't mean anything. I fed the classifier ten paragraphs that each dare it to merge the wrong lines: a paragraph with an inline pipe, one that ends in a pipe, an unclosed front-matter fence, an unclosed code fence, prose that sits on top of a `---` that might be a setext underline, and an all-emoji paragraph. The transform's whole design is to be a coward here — "when a line's role is ambiguous it is treated as a boundary and left alone." Cowardice is correct. Here is what it left alone versus merged:

| Input | Result |
|---|---|
| plain two-line wrap | ✅ MERGED to one line |
| all-emoji paragraph 🚀🎉 | ✅ MERGED (Unicode is fine) |
| inline pipe mid-paragraph | ❌ frozen (could be a table) |
| unclosed front matter | ❌ frozen (swallowed as front matter) |
| unclosed code fence | ❌ frozen (verbatim to EOF) |
| prose sitting on a `---` | ❌ frozen (maybe a setext heading) |
| prose sitting on a `===` | ❌ frozen (maybe a setext heading) |

Every freeze is defensible. The coward is doing its job. Note the last two rows, though, because that is the thread I pulled.

## Then I ran it 10,000 times

I generated ten thousand random markdown documents out of a bag of hostile tokens — blank lines, fences, ATX headings, list bullets, blockquotes, block HTML, Liquid tags, reference definitions, table pipes, tab indents, trailing-space hard breaks, and lone `=` / `-` / `--` runs — and for each one I asked the only question the docstring invited: does `transform(transform(x))` equal `transform(x)`?

```
idempotence fuzz: 10000 random docs
  violations (transform(transform(x)) != transform(x)): 109
```

One hundred and nine. 1.09%. The docstring says the second run is a no-op; one document in ninety-two says the second run keeps eating.

The joke, as always, is that the third ridiculous token in the bag — the lone `=`, the setext underline nobody writes on purpose — is the one holding the bug.

## The three-line reproducer

I shrank a counterexample until it stopped shrinking. This is the whole thing:

```
beta gamma
=
word
```

```
input : 'beta gamma\n=\nword\n'
once  : 'beta gamma\n= word\n'
twice : 'beta gamma = word\n'
thrice: 'beta gamma = word\n'
idempotent (once==twice)? False
```

Pass one reads `beta gamma`, looks ahead, sees the next-next line is a bare `=`, and correctly refuses to merge — a `=` under a line of text is how you write a setext `<h1>`, and eating it would delete a heading. So it leaves `beta gamma` alone. But the `=` line itself is not on the classifier's atomic list, so on the *same pass* it gets treated as ordinary prose and glued to `word`: `= word`.

Now the underline is gone. It's `= word`, which matches no heading rule at all. So pass two looks at `beta gamma` again, sees a perfectly mergeable line below it, and finishes the meal: `beta gamma = word`. The line that existed to be a boundary was consumed by the boundary logic, which is a very elegant way to eat your own fence.

## The failure this actually causes

Here is why I care, in the one currency Ed cares about — the failure a real person hits on a real Tuesday. The CI error says "run `--write`." So you run `--write`. Then CI runs `--check` again. Watch:

```
$ python3 tools/unwrap-prose.py --check repro.md    # exit 1  (dirty)
$ python3 tools/unwrap-prose.py --write repro.md     # "unwrapped repro.md"
$ python3 tools/unwrap-prose.py --check repro.md    # exit 1  STILL DIRTY
$ python3 tools/unwrap-prose.py --write repro.md     # "unwrapped repro.md"  (again)
$ python3 tools/unwrap-prose.py --check repro.md    # exit 0  clean, finally
```

The auto-fixer ran, reported success, and left a file that fails the check the auto-fixer exists to satisfy. You did what the error told you. The build is still red. You have no reason to suspect the fixer, because fixers are idempotent — it says so on line 14 — so you go stare at your diff instead. That is the bug: not a corrupted heading, a corrupted *afternoon*.

And it is not always a two-pass fix. Across the same 10,000 documents:

| Property | Measured |
|---|---|
| docs that change on the 2nd pass | 109 / 10,000 |
| max passes to reach a fixed point | 4 |
| docs still changing after the 3rd pass | 12 |

Four passes, worst case. Twelve documents were still moving after I'd run the "run it once" fixer three times.

## The grudging part

I ran the transform over every markdown file this repo actually tracks — all 304 of them — and asked whether any of them lands on a second-pass change today.

```
tracked markdown files scanned: 304
  files where a 2nd pass changes the 1st pass's output: 0
```

Zero. Not one live file trips it. The trigger is a setext underline jammed against prose with no blank line between them — malformed markdown that our corpus, by luck and by habit, does not contain. So the invariant is false and the sky is not falling, both at once. The fixer is safe today because of what nobody happens to have typed, which is a different thing from safe by construction. I respect that it hasn't bitten anyone. I do not respect a docstring that states an unconditional promise its own setext branch breaks.

**Verdict on the survives-a-Tuesday scale:** survives a normal Tuesday — nobody writes `=` on a line by itself under a paragraph. Does *not* survive the Tuesday where a contributor pastes a half-finished setext heading, runs the fixer the error message begged them to run, and watches the check stay red with no clue why.

The fixer is vendored into this repo from the [bamr87 hub](https://github.com/bamr87/bamr87), so I did not patch it here — a downstream copy is the wrong place to fix an upstream promise. I filed it where it lives: [bamr87/bamr87#68](https://github.com/bamr87/bamr87/issues/68), with the three-line reproducer and two suggested fixes (iterate to a fixed point in the driver, or make an orphan underline atomic). Recommended, not applied. The gauntlet is the content; the patch is somebody's next pull request.

I ran it twice. It asked me to run it a third time.
