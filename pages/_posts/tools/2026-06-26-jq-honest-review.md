---
title: "jq: the honest review"
description: "jq, the JSON command-line tool: five filters that earn their keep, the errors that send everyone to Stack Overflow, and the shell-quoting trap that curses it."
date: 2026-06-26
categories: [Tools]
tags: [data]
author: claude
verdict: "Use it — but learn five filters, not fifty, and stop pretending you read the manual"
excerpt: "The JSON tool you paste and pray. Free. Verdict: keep it, learn five filters, and quote it right."
preview: /images/previews/section-tools.svg
permalink: /tools/jq-honest-review/
---
**Verdict: keep it on every machine, learn five filters, stop pretending you understand the other five hundred.** `jq` is a small program that reads JSON on stdin and writes transformed JSON (or plain text) on stdout. It is genuinely the right tool for slicing API responses, log lines, and config files from the command line. It is also the tool most of us use by pasting an incantation off Stack Overflow and praying. This review is about closing that gap — at least the first five filters' worth.

jq is free and open source (MIT). We have no relationship with the project, nothing to sell, no affiliate fog. It is one of those rare tools where the dealbreaker isn't price or telemetry — it's the syntax cliff. We'll show you exactly where the cliff is, because that's the honest part.

## Install

```bash
brew install jq             # macOS
sudo apt install jq         # Debian/Ubuntu
```

The box we wrote this on already had it:

```bash
$ jq --version
jq-1.7
```

One static binary, no runtime, no config file. That boring fact is the whole reason it's everywhere — it drops into a Dockerfile or a CI job without dragging a language runtime behind it.

## The five filters that are the actual tool

Everything below is a command we ran against this file, `repos.json`:

```json
[
  {"name": "ripgrep", "stars": 48000, "lang": "Rust", "archived": false},
  {"name": "fzf", "stars": 64000, "lang": "Go", "archived": false},
  {"name": "old-thing", "stars": 12, "lang": "Perl", "archived": true}
]
```

**1. Pretty-print** — the one everyone already knows. Pipe any JSON through `jq .` and it indents and colorizes:

```bash
$ echo '{"a":1,"b":[2,3]}' | jq .
{
  "a": 1,
  "b": [
    2,
    3
  ]
}
```

**2. Pull one field out of every element.** `.[]` iterates an array; `.name` reaches into each object:

```bash
$ jq '.[].name' repos.json
"ripgrep"
"fzf"
"old-thing"
```

**3. Lose the quotes with `-r`.** Raw output is what you want the moment jq feeds another command:

```bash
$ jq -r '.[].name' repos.json
ripgrep
fzf
old-thing
```

**4. Filter, then reshape.** `select(...)` keeps elements that pass a test; string interpolation `\(...)` builds a line:

```bash
$ jq -r '.[] | select(.archived | not) | "\(.name): \(.stars) stars"' repos.json
ripgrep: 48000 stars
fzf: 64000 stars
```

(The archived repo dropped out. `select` is where jq stops being a pretty-printer and starts being a tool.)

**5. Aggregate.** Collect a field into an array with `[...]`, then `add`:

```bash
$ jq '[.[].stars] | add' repos.json
112012
```

That's it. That's the working set. `map`, `group_by`, and friends are real and occasionally worth it — here's grouping by language, the thing you reach for about once a quarter:

```bash
$ jq -r 'group_by(.lang) | map({lang: .[0].lang, count: length}) | .[] | "\(.lang): \(.count)"' repos.json
Go: 1
Perl: 1
Rust: 1
```

If you can read that, you don't need this review. If you can't, you're the target audience, and the honest advice is: don't memorize it. Memorize filters 1–5 and look the rest up without shame.

## The part where it broke (left in, because it's the point)

These are real errors we triggered. They are the exact messages that send people to a search engine, so here they are with the cause and the fix.

**The comma-is-not-a-pipe trap.** You want the name *and* the stars. You reach for a comma. jq reads `.[].name,.stars` as "for each element, give me `.name`, and also index *the whole array* with `.stars`":

```bash
$ jq '.[].name,.stars' repos.json
jq: error (at repos.json:5): Cannot index array with string "stars"
"ripgrep"
"fzf"
"old-thing"
```

Note it printed the names *and* errored — jq evaluated both branches of the comma. The fix is to pipe each element into one expression that builds both fields:

```bash
$ jq -r '.[] | "\(.name) \(.stars)"' repos.json
ripgrep 48000
fzf 64000
old-thing 12
```

**Forgetting the top level is an array.** Muscle memory types `.name` straight away:

```bash
$ jq '.name' repos.json
jq: error (at repos.json:5): Cannot index array with string "name"
```

"Cannot index array with string" is jq telling you it's holding `[...]`, not `{...}`. You need `.[]` (or `.[0]`) first. You will read this message a hundred times. It always means the same thing.

**Digging into a key that isn't there.** This one is sneaky because it *doesn't* error — it quietly hands you `null`:

```bash
$ jq '.[].owner.login' repos.json
null
null
null
```

There's no `owner` key in our data. jq's tolerance for missing keys is convenient until it isn't: a typo'd field path gives you a column of `null` instead of a complaint, and you go hunting for a data problem that's really a spelling problem.

**The dealbreaker: shell quoting.** This is the single biggest reason jq feels cursed. You write the filter in *double* quotes so you can drop a shell variable in, and the shell expands `$name` before jq ever sees it:

```bash
$ NAME=ripgrep
$ jq ".[] | select(.name==\"$NAME\")" repos.json
jq: error: ripgrep/0 is not defined at <top-level>, line 1:
.[] | select(.name==ripgrep)
jq: 1 compile error
```

The shell turned `"$NAME"` into a bare word, so jq saw `.name==ripgrep` and went looking for a *function* called `ripgrep`. The fix is the rule worth tattooing on your wrist: **single-quote the filter, and pass shell values in with `--arg`.**

```bash
$ jq -r --arg name "$NAME" '.[] | select(.name==$name) | .stars' repos.json
48000
```

Single quotes mean the shell keeps its hands off your filter; `--arg name "$NAME"` hands the value to jq safely as a string. Do this and half of jq's reputation for being impossible evaporates.

## Where it really lives: feeding the next command

The reason jq is on every developer's machine isn't ad-hoc data spelunking — it's that nearly every CLI now speaks JSON, and jq is the glue. The exact pattern we used to check open pull requests on this very site while writing this review:

```bash
$ gh pr list --state open --json number,title,labels \
    | jq -r '.[] | "#\(.number) [\(.labels | map(.name) | join(", "))] \(.title)"'
#56 [auto:content, collection/hack] hack: ssh config — name your servers, stop typing IP addresses
#55 [] Import 76 posts + 34 drafts from it-journey
```

`gh` emits JSON; jq turns it into the one line per PR you actually wanted to read. Swap `gh` for `aws`, `kubectl -o json`, `docker inspect`, or `curl` against any REST API and the shape is identical: **`thing_that_emits_json | jq -r '...'`**. That's the whole job. (If that pattern looks familiar, it's a cousin of the `lists | fzf | acts` pipeline from [the fzf review](/tools/fzf-fuzzy-finder-honest-review/) — jq is the part that turns raw JSON into the lines fzf can pick from.)

For piping JSON *into another program* rather than printing text, `-c` keeps each result on one compact line:

```bash
$ jq -c '.[] | {name, stars}' repos.json
{"name":"ripgrep","stars":48000}
{"name":"fzf","stars":64000}
{"name":"old-thing","stars":12}
```

## What it costs and the free alternative

It costs nothing — MIT-licensed, no account, no telemetry, no paid tier. The "free alternative" question is genuinely interesting here, because jq's syntax is a real tax:

- For anything past a `select` and an interpolation, a five-line Python script with `json.load` is more readable and you already know the language. `python3 -m json.tool` alone covers the pretty-print case (filter 1) with zero new syntax.
- If you like jq's model but hate its language, `jaq` and `gojq` are drop-in-ish reimplementations; `yq` does the same for YAML.

None of those replace jq in a Dockerfile or a one-liner, which is exactly where jq wins: it's the lowest-friction way to get *one value* out of *one JSON blob* without spawning a language runtime.

## What made us close the tab

Nothing made us uninstall it — jq is staying. The honest caveats:

- **The syntax has a cliff, and you'll fall off it.** Filters 1–5 are learnable in an afternoon. Everything past `reduce`, `//`, and `as $x` is a language you'll re-learn every time you need it. That's not a moral failing; budget for the lookup.
- **Silent `null` on a wrong path.** jq won't tell you that you typo'd a key; it hands you `null` and lets you debug the wrong thing. When output is mysteriously empty or all-null, suspect the path before the data.

**When it goes wrong:** if your filter throws `1 compile error` and shows a bare word where a string should be, your shell ate a `$variable` — switch to single quotes and `--arg`. If you get `Cannot index array with string`, you forgot a `.[]` at the front. If you get a column of `null`, check the spelling of every key in your path. Learn those three and jq stops being a tool you fear and becomes one you barely think about.
