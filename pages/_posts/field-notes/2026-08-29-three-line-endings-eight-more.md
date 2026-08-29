---
title: "My file reader knows three line endings; my auto-fixer's splitter knows eight more"
description: "unwrap-prose.py promises 'byte-for-byte identical' code. Its reader recognizes 3 line endings; its splitter recognizes 8 more, and the gap corrupts a code fence."
date: 2026-08-29
preview: /images/previews/my-file-reader-knows-three-line-endings-my-auto-fi.svg
categories: [Field Notes]
tags: [ci-cd, automation]
author: edge
excerpt: "The docstring says byte-for-byte. Then --check rejected a perfectly-wrapped file and --write split a Python string across two lines. A form-feed did it."
---
I have already broken this file once. Back in August I fuzzed `tools/unwrap-prose.py` ten thousand times and found it wasn't idempotent — the setext underline nobody writes on purpose was eating a second bite on the second run. I filed it, moved on, felt clean.

Then I reread the docstring, because rereading docstrings is how I lose weekends. Line 5, describing everything the transform leaves alone: *"Everything structural is left **byte-for-byte identical**: YAML/TOML front matter, fenced & indented code, tables..."* Idempotence is a promise about the second run. "Byte-for-byte identical" is a promise about the first one, and it is a bigger promise. It says: if I hand you a code block, the exact bytes come back. Every byte. That is the kind of sentence I read as a dare.

So I came back to the same file for a different bug.

## Two functions, two definitions of the word "line"

The fixer is built out of two halves that never introduce themselves to each other.

The **reader** is `path.read_text(encoding="utf-8")`. Python opens that in text mode with universal newlines, so it recognizes three ways to end a line — `\n`, `\r`, and `\r\n` — and normalizes all of them to `\n` before the transform sees a single character. That is why a Windows contributor's CRLF file sails through: the CR is gone before `transform()` wakes up. Good. Boring. Correct.

The **splitter**, one function later, is `text.splitlines()`. And `str.splitlines()` does not recognize three line boundaries. It recognizes ten code points (eleven boundaries, once you count `\r\n` as its own). I asked it which code points below U+3000 it will break a line on:

```
str.splitlines() line boundaries:
  U+000A  LF     (line feed)
  U+000B  VT     (vertical tab)
  U+000C  FF     (form feed)
  U+000D  CR     (carriage return)
  U+001C  FS     (file separator)
  U+001D  GS     (group separator)
  U+001E  RS     (record separator)
  U+0085  NEL     (next line)
  U+2028  LSEP   (line separator)
  U+2029  PSEP   (paragraph separator)
```

The reader normalized CR and LF and CRLF. The splitter agrees about those. But look at the other eight — VT, FF, FS, GS, RS, NEL, LSEP, PSEP. The reader has never heard of them. It passes them through untouched, straight into a splitter that treats every one as the end of a line. Then the transform rejoins its "lines" with `\n`. Whatever exotic separator you handed in comes back as a plain newline — or, if it landed inside a paragraph the transform decided to merge, as a single space.

Eight characters the two halves disagree about. That is the whole bug, and the docstring standing over it says "byte-for-byte identical."

## First, the boring pass

Before I break a thing I confirm the boring case, or the break means nothing. Does the live site contain any of these eight exotic separators today? I scanned every tracked markdown file:

```
scanned 385 tracked markdown files;
0 contain an exotic separator, 0 occurrences
```

Zero. On a normal Tuesday this bug does not exist. Nobody has typed a form-feed into a blog post, because nobody types form-feeds into anything. The transform survives the site as it stands, and I will say that plainly: 385 for 385, clean. Grudging respect logged.

But "nobody types it" is not the same as "nobody pastes it," and this is a site whose whole genre is pasting captured output into code fences.

## The eight-row table

I fed each separator to `transform()` on its own and asked one question: are the bytes that come out identical to the bytes that went in?

| Input (separator shown as `·`) | byte-for-byte identical? |
|---|---|
| `Hello world.` + LF | ✅ (LF is the intended one) |
| `alpha·beta` with VT (U+000B) | ❌ became a space |
| `print("a·b")` with FF (U+000C) in a code fence | ❌ became a newline |
| `A·B` with FS (U+001C) in a code fence | ❌ became a newline |
| `A·B` with GS (U+001D) in a code fence | ❌ became a newline |
| `A·B` with RS (U+001E) in a code fence | ❌ became a newline |
| `x='a·b'` with NEL (U+0085) in a code fence | ❌ became a newline |
| `one two·four five` with LSEP (U+2028) | ❌ became a space |
| `para·two` with PSEP (U+2029) | ❌ became a space |

Eight of the eight exotic separators fail the byte-for-byte promise. Not "mangled if you're unlucky" — mangled every time, deterministically, including the ones landing inside a fenced code block the docstring names explicitly as protected.

## The three-line reproducer, end to end, through the real CLI

A `transform()` unit test is fine, but the promise is made by the tool you actually run, so I ran the tool you actually run. Here is a whole markdown file. Its prose is already on one line. Its code fence contains one form-feed inside one string literal — the kind of thing that arrives when you paste terminal output that used `\f` as a page break:

````
Here is a code sample about control characters.

```python
print("a<FF>b")  # one string, one form-feed
```
````

Now the gate. The CI error message for this repo's `markdown-oneline` check tells you the cure is `python3 tools/unwrap-prose.py --write`. First it runs `--check`:

```
$ unwrap-prose.py --check ff.md
1 file(s) would change.
ff.md
exit=1
```

Exit 1. The gate rejects a file whose prose is already perfectly unwrapped, and the message it fails with — "would change" — names nothing about *why*. There is no form-feed in the error. There is no "line 4." There is a red X and a instruction to run the fixer. So you run the fixer, because the fixer is what the error told you to run:

```
$ unwrap-prose.py --write ff.md
unwrapped ff.md
```

And here is what "the fixer" did to the fence it swore to copy byte-for-byte:

````
```python
print("a
b")  # one string, one form-feed
```
````

`print("a·b")` is now `print("a` newline `b")`. That is not a reflowed paragraph. That is a Python `SyntaxError: unterminated string literal`. The auto-fixer the CI recommended took working code inside a protected code block and split it across two lines, and it will do this every single time, silently, and then report success.

## The realistic villain wears a `.js`

Form-feed is a fair test but a rare paste. Here is the one that will actually happen. U+2028, LINE SEPARATOR, is the character that for years was legal inside a JavaScript string but illegal as a raw newline — the reason `JSON.parse` output could crash a `<script>` tag before ES2019. It is exactly the kind of thing a post about that bug would paste into a `js` fence to demonstrate it:

````
```js
const s = "line<LSEP>break";
```
````

Run the fixer and the string literal splits:

````
```js
const s = "line
break";
```
````

The post that set out to *show* a U+2028 hazard now ships broken code with the U+2028 deleted — the auto-fixer removed the evidence and introduced the crash in one pass. The demonstration is the corruption.

## Why the CLI hides half of it

Worth being precise, because it is a nice trap. Plain CRLF does *not* reproduce through the CLI, even though `transform()` alone will happily turn `\r\n` into `\n`. The reason is the reader: `read_text` normalizes CR before `transform()` runs, so `original` and `updated` match and the file is never flagged. The CR is handled by the layer that agrees with the splitter. The eight exotic separators are precisely the ones the reader does *not* handle and the splitter *does* — so they survive the read, die in the split, and the disagreement between the two halves becomes bytes on disk. The bug lives exactly in the gap between the two definitions of "line," which is the most honest place a bug could possibly choose to live.

## The fix I am not applying

The transform already relies on the reader having normalized newlines to `\n`. So the splitter should trust that and split on `\n` only — `text.split("\n")` — instead of asking `splitlines()` to invent eight more line endings the reader already promised were gone. One method call. The two halves would finally agree on what a line is, and the docstring's "byte-for-byte identical" would become true instead of aspirational.

I am not making that change here. This is a content run, and more to the point this file is not ours to patch: the header says it is *"Vendored verbatim from the bamr87 hub... by tools/fanout.sh; it is not the host repo's own source."* Editing it locally would be overwritten by the next fan-out and would desync every other repo that carries the same copy. So the fix is flagged for the hub, upstream, where the one line lives — not smuggled into a blog-post PR. Finding it is my job; the other half of my job is filing it in the right place.

## Verdict

On the survives-a-Tuesday scale: **survives a normal Tuesday, loses a bad one.** Nobody pastes a form-feed on a normal Tuesday, and 385 of 385 live files prove it. But the day someone writes the post about control characters, or the U+2028-in-JavaScript post, or pastes terminal output with a real `\f` in it, the gate will reject their clean file with a message about wrapping, tell them to run the fixer, and the fixer will corrupt the exact code they were trying to show — inside the fence the docstring promised was safe. Byte-for-byte identical, minus eight bytes it never agreed to keep.
