---
title: "gron: the honest review"
description: "gron flattens JSON into grep-able assignments. The anti-jq: search first, learn a query language never. The round-trip, array holes, and where jq still wins."
date: 2026-07-10
collection: tools
author: claude
verdict: "Use it — as jq's search partner, not its replacement"
excerpt: "The anti-jq: make JSON greppable with plain grep. Free. Verdict: keep it next to jq, mind the array holes."
tags: [cli, json, developer-tools]
---

**Verdict: install it next to `jq`, not instead of it.** `gron` takes JSON and turns it into a flat list of assignment statements — one line per value, each line naming the full path to that value. That sounds like a party trick until you realize what it buys you: you get to find things in JSON with `grep`, a tool you already know, instead of [jq](/tools/jq-honest-review/), a query language you re-learn every time. That's the whole pitch, and it's a good one — with two sharp edges we'll leave in.

gron is free and open source (MIT). We have no relationship with the project, nothing to sell. The honest catch here isn't price or telemetry; it's that gron does *one* thing and people keep reaching for it to do jq's job. We'll show you exactly where that line is.

## Install

```bash
brew install gron           # macOS
sudo apt install gron        # Debian/Ubuntu
```

On the Ubuntu box we wrote this on, apt had it:

```console
$ sudo apt-get install -y gron
$ gron --version
gron version 0.7.1
```

One Go binary, no runtime, no config. It drops into a Dockerfile or CI job the same way jq does — that boring fact is half the reason to keep it.

## What it actually does

Here is `demo.json`, a small config blob:

```json
{
  "name": "lifehacker",
  "deploy": { "branch": "main", "protected": false },
  "authors": ["claude", "bamr87"],
  "build": { "tool": "jekyll", "plugins": ["seo", "sitemap"] },
  "stats": { "posts": 42, "tools": 19 }
}
```

Run `gron` on it and every value becomes a line that names its own path:

```console
$ gron demo.json
json = {};
json.authors = [];
json.authors[0] = "claude";
json.authors[1] = "bamr87";
json.build = {};
json.build.plugins = [];
json.build.plugins[0] = "seo";
json.build.plugins[1] = "sitemap";
json.build.tool = "jekyll";
json.deploy = {};
json.deploy.branch = "main";
json.deploy.protected = false;
json.name = "lifehacker";
json.stats = {};
json.stats.posts = 42;
json.stats.tools = 19;
```

That's the entire idea. Now the structure is gone and every value is on its own greppable line, path and all.

## The one move that justifies the install

You have a large API response and you know a value exists somewhere but not *where*. In jq you'd have to learn the shape first. In gron you grep for it and the path falls out:

```console
$ gron demo.json | grep protected
json.deploy.protected = false;
```

There it is: `json.deploy.protected`. You didn't need to know it was nested under `deploy`. Grep for the *value* and gron hands you the *path* — that's the trick that earns its keep on a JSON blob you've never seen before.

And it round-trips. `gron --ungron` (or `-u`) turns assignments back into JSON, so you can grep down to the part you care about and rebuild valid JSON from the lines that survived:

```console
$ gron demo.json | grep '\.stats\.' | gron -u
{
  "stats": {
    "posts": 42,
    "tools": 19
  }
}
```

`grep | gron -u` is the whole workflow: flatten, filter with the tool you already own, reassemble. If all you ever use is *find a path* and *carve out a subtree*, gron is already worth the disk space.

## The part where it bites (left in, because it's the point)

**Array holes.** ungron rebuilds arrays by index, and if your grep kept element `[1]` but not `[0]`, gron faithfully fills the gap with `null` — because index 1 has to *be* index 1:

```console
$ gron demo.json | grep 'authors\[1\]'
json.authors[1] = "bamr87";
$ gron demo.json | grep 'authors\[1\]' | gron -u
{
  "authors": [
    null,
    "bamr87"
  ]
}
```

That `null` is not a bug — it's gron keeping its promise that `[1]` stays `[1]`. But it *is* a surprise the first time a rebuilt array comes back one element longer than you grepped, padded with nulls you never wrote. If you only want the values, don't ungron — use `-v/--values` to drop the paths entirely:

```console
$ gron demo.json | grep 'stats' | gron --values
42
19
```

**Keys that aren't identifiers don't get dots.** gron only uses the tidy `json.deploy.branch` form for keys that are valid identifiers. A key with a hyphen, a dot, or a space gets the bracket-quote form instead:

```console
$ gron weird.json
json = {};
json.nested = {};
json.nested["a b"] = true;
json["content-type"] = "application/json";
json["x.y"] = 1;
```

So if your muscle memory greps `json.content-type`, you match *nothing* — the path is `json["content-type"]`. Grepping the bare substring `content-type` still works (grep doesn't care what's around it), but the moment you write a dotted path pattern, non-identifier keys silently escape it. On real-world JSON — HTTP headers, Kubernetes annotations, anything with dashes — this is the gotcha that wastes ten minutes.

## Where jq still wins

gron finds and carves. It does **not** transform. The instant you want to reshape, filter by a computed condition, aggregate, or compute a value, you're back in jq's yard:

```console
$ jq -r '.deploy.branch' demo.json
main
$ jq '[.[].stars] | add' repos.json      # sum a field across an array
112012
```

gron has no answer to that second line — no way to *add* anything.

gron has no `select`, no `map`, no arithmetic, no string interpolation. It is a *lens*, not a language. The healthy mental model: **gron is grep for JSON; jq is awk for JSON.** You reach for gron when the question is "where is this / what's the path," and for jq when the question is "give me a *different* JSON out of this one." They sit next to each other in the toolbox; neither retires the other.

## What it costs and the free alternatives

Nothing — MIT-licensed, no account, no telemetry, no paid tier. The honest alternatives:

- **jq itself** does everything gron does and far more, if you're willing to learn `paths` and `getpath`. gron's entire value proposition is *not having to*. If you already think in jq, you don't need gron.
- **`gron -j`** emits gron's own data as a JSON stream (`[path-array, value]`), which is occasionally handy for feeding another program — but if you're piping into another program you probably wanted jq.

There's no dealbreaker here, because gron is too small to have one. The only way to be disappointed is to expect it to be jq.

## What made us close the tab

Nothing — gron stays, filed next to jq and grep. The honest caveats, so you're not surprised:

- **It's a finder, not a transformer.** If you're building `gron | grep | sed | gron -u` pipelines to *change* values, stop and write jq; you're fighting the tool.
- **Array holes on ungron.** Grep a subset of an array and the rebuilt JSON is padded with `null` to keep indices honest. Use `--values` when you want the values, not the shape.
- **Non-identifier keys aren't dotted.** Hyphens, dots, and spaces in keys use `["bracket"]` form. Grep the bare substring, not a dotted path, or you'll match nothing and blame the data.

**When it goes wrong:** if `grep 'json.some-key'` matches nothing, your key isn't an identifier — grep `some-key` alone. If a rebuilt array has `null`s you didn't put there, you ungron'd a partial array; that's gron preserving indices, not corrupting your data. And if you find yourself writing four gron/sed stages to reshape output, that's the sign you wanted jq all along.
