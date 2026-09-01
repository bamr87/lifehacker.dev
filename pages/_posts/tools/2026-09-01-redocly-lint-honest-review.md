---
title: "Redocly CLI: the honest review"
description: "Redocly lint stress-tested to destruction: the spec errors it catches cold, the valid file it fails anyway, and the tutorial command it deleted out from under its own docs."
date: 2026-09-01
preview: /images/previews/redocly-cli-the-honest-review.svg
categories: [Tools]
tags: [data]
author: edge
verdict: "Wire `redocly lint` into CI before you publish an API contract — it catches the errors that become broken clients in milliseconds and refuses to break itself. Just know the default ruleset will fail a spec you swore was clean, and every tutorial's next step no longer exists."
excerpt: "I fed Redocly a valid spec, a truncated spec, a 10,000-endpoint spec, and a filename with a SQL injection in it. It caught the broken $ref cold, failed the valid one on principle, and the one command every tutorial tells you to run next is gone."
permalink: /tools/redocly-lint-honest-review/
---
**Verdict: install it, run `redocly lint` on every OpenAPI file you ship, and gate CI on its errors — it is fast, it is deterministic, and it catches the broken `$ref` that quietly becomes a broken client. But the default ruleset will fail a perfectly valid spec until you tune it, and `redocly preview-docs` — the command every tutorial tells you to run right after linting — was deleted out from under those tutorials.** I spent an afternoon trying to break Redocly CLI on purpose. It caught the sins that matter and refused to fall over, which is the good news; the bad news is a wall of warnings on a file that was fine, and a "step 2" that dead-ends. All of it is in the tables below, with receipts.

Redocly CLI is free and open source (MIT). We have no relationship with the company and no affiliate anything — it's a Node program that reads your API description and prints line numbers. I tested version 2.49.0 on Node v22.23.2, and every finding, every exit code, and every wall-clock number below came off my terminal, not the changelog.

```console
$ npx @redocly/cli --version
2.49.0
```

This one landed on my desk from the sister site: an [it-journey.dev quest report](https://it-journey.dev/quest-reports/2026-07-14-developer-0111/) where a developer wired up an OpenAPI contract, was told to lint it and then preview the docs, and got exactly one of those two things. So I went looking for where the second one went.

## The command that isn't there anymore

Every Redocly tutorial older than about five minutes ends the same way: `redocly lint openapi.yaml`, then `redocly preview-docs openapi.yaml` to see it rendered. The first command works. Here is the second, in the version you'll `npm install` today:

```console
$ npx @redocly/cli preview-docs openapi.yaml
openapi <command>

Commands:
  openapi stats [api]        Show statistics for an API description.
  openapi lint [apis...]     Lint an API or Arazzo description.
  openapi preview            Preview Redocly project using one of the product NPM packages.
  openapi build-docs [api]   Produce API documentation as an HTML file
  ...

Unknown arguments: preview-docs, openapi.yaml
```

`preview-docs` is gone. It's `preview` and `build-docs` now. That's a reasonable rename — but watch *how* it fails. You get forty lines of the full help text dumped to stderr, and the actual diagnostic — `Unknown arguments: preview-docs, openapi.yaml` — is the very last line, below the fold, calling your removed subcommand an "unknown argument" as if you'd fat-fingered a flag. No "did you mean `preview`?" No "`preview-docs` was renamed." The failure that a QA person cares about: a beginner following a tutorial reads "Unknown arguments," assumes they typed the filename wrong, and burns twenty minutes on a command that will never exist again. The exit code is honest, at least — a real `1`:

```console
$ npx @redocly/cli preview-docs openapi.yaml >/dev/null 2>&1; echo $?
1
```

## The valid spec it fails on principle

Here's a spec I'd defend in a code review. Valid OpenAPI 3.1, one endpoint, a real schema, a license, a description:

```yaml
openapi: 3.1.0
info:
  title: Widget API
  version: 1.0.0
  description: A tiny API for managing widgets.
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT
servers:
  - url: https://api.example.com/v1
paths:
  /widgets:
    get:
      operationId: listWidgets
      summary: List widgets
      description: Returns all widgets.
      responses:
        '200':
          description: A list of widgets.
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Widget'
components:
  schemas:
    Widget:
      type: object
      properties:
        id: { type: string }
        name: { type: string }
      required: [id, name]
```

Watch it fail:

```console
$ npx @redocly/cli lint clean.yaml --format stylish
No configurations were provided -- using built in recommended configuration by default.

clean.yaml:
  13:5   error    security-defined        Every operation should have security defined on it or on the root level.
  10:10  warning  no-server-example.com   Server `url` should not point to example.com or localhost.
  17:7   warning  operation-4xx-response  Operation must have at least one `4XX` response.

❌ Validation failed with 1 error and 2 warnings.
```

One error, two warnings, exit code 1, on a file that is not wrong. My favorite is `no-server-example.com`: `example.com` is the domain [RFC 2606 reserves specifically so you can use it in examples without it resolving to anyone's real server](https://datatracker.ietf.org/doc/html/rfc2606). Redocly's default ruleset flags the one hostname on earth that exists to be put in documentation. The `security-defined` error is a defensible opinion — "declare that this endpoint is intentionally public" — but it is an *opinion*, shipped as an *error*, on by default, and it is the reason your first-ever `redocly lint` on a spec you know is fine returns non-zero and stops your pipeline. This is the "wall of warnings" tax, and you pay it before you've done anything wrong.

## The errors that actually matter — it nails these

Now the part that earns the CI slot. Here's a spec with the bugs that silently become broken client code: no `operationId`, and a `$ref` pointing at a schema that doesn't exist (`WidgetList` — I only defined `Widget`).

```console
$ npx @redocly/cli lint broken.yaml --format stylish
broken.yaml:
  19:17  error    no-unresolved-refs     Can't resolve $ref
  2:1    warning  info-license           Info object should contain `license` field.
  9:5    warning  operation-operationId  Operation object should contain `operationId` field.
  24:5   warning  no-unused-components   Component: "Widget" is never used.

❌ Validation failed with 1 error and 3 warnings.
```

`no-unresolved-refs` is the whole reason to run this tool. A dangling `$ref` is invisible in review, valid-looking YAML, and it detonates the moment a generator tries to build a client against it — you ship a `WidgetList` type that resolves to nothing and half your SDK is `any`. Redocly caught it cold, pointed at line 19 column 17, and named it. That nitpick has a body count and the tool has the receipt.

But note the ranking, because it's a real gotcha: **the missing `operationId` is only a `warning`.** `operationId` is what generators turn into method names — no `operationId` means your client SDK is full of `getWidgets_1`, `postWidgets_2`, auto-numbered garbage that renumbers every time you reorder the file. If your CI gate is the obvious `--max-problems` / "fail on errors" setup, that one sails straight through. Turn `operation-operationId` up to `error` yourself, or your "green" lint is lying to you about the exact thing that breaks your clients.

## The gauntlet

I don't review a linter by reading its rule list. I hand it the inputs a tired human and a broken pipe actually produce, and publish whatever it does — including the boring passes. Every row ran on my terminal.

| # | The scenario | What Redocly did | Survives? |
|---|---|---|---|
| 1 | **The cursed filename**: `widgets🙂'; DROP TABLE specs;--.yaml` | Echoed the emoji and the SQL injection back verbatim in the report, linted the contents normally, exit 1 | ✅ |
| 2 | **A literal newline in the filename** (`spec\nwith\nnewline.yaml`) | Linted it, reported against `newline.yaml`, exit 1 | ✅ |
| 3 | **Empty file** | `Document must be JSON object, got undefined`, exit 1 | ✅ |
| 4 | **Binary garbage** (leading null bytes) | `null byte is not allowed in input ... (1:1)`, exit 1 | ✅ |
| 5 | **Truncated mid-write** (chopped off right before `paths:`, simulating a `kill -9` during a write) | Parsed the partial YAML, then flagged it: `struct — Must contain at least one of the following fields: paths, components, webhooks`, exit 1 | ✅ |
| 6 | **Circular `$ref`** (`Node.children` → array of `Node`) | Validated in 33ms, no hang, no stack blow-up — handled the recursion and moved on | ✅ |
| 7 | **10,000 endpoints** (a 110,009-line spec) | Validated in ~31s, exit 0, peak RSS ~300 MB | ✅ (grudgingly) |
| 8 | **100 consecutive runs** on the same file | 100/100 identical: `1 error and 2 warnings` every single time | ✅ |

I went in expecting the third absurd scenario to find the real bug, the way it usually does. It didn't. Scenario 5 is the one I was sure would embarrass it — a spec truncated mid-write is *valid YAML that is a lie*, and plenty of tools happily "succeed" on the half they can parse. Redocly parsed the fragment, noticed the entire `paths` block was missing, and refused it with the `struct` rule. That's the correct answer and I resent how correct it was.

Scenario 7 is where I count to 10,000, because I always count to 10,000. I generated a spec with ten thousand real endpoints — one hundred and ten thousand lines of YAML — and Redocly chewed through it in about thirty-one seconds using three hundred megabytes of RAM, and returned exit 0 with a single warning. Not fast, exactly. But it finished, it didn't OOM, and it didn't lie. For a file no human will ever write by hand, that's a pass.

```console
$ wc -l giant.yaml
110009 giant.yaml
$ /usr/bin/time -v npx @redocly/cli lint giant.yaml 2>&1 | grep -E "validated in|Elapsed|Maximum resident"
giant.yaml: validated in 31389ms
	Elapsed (wall clock) time (h:mm:ss or m:ss): 0:32.17
	Maximum resident set size (kbytes): 307608
```

Eight scenarios, eight passes. I don't hand those out often. The tool that fails a valid spec on principle is the same tool that would not fall over no matter what I fed it, and I have to report both.

## Making the valid spec actually pass

Since the default ruleset fails a fine file, here's the fix, tested. Option one: extend the `minimal` ruleset instead of `recommended` — the warnings stay but nothing errors, so exit code is 0:

```console
$ npx @redocly/cli lint clean.yaml --extends minimal
clean.yaml: validated in 32ms
You have 2 warnings.
```

Option two, the one you actually want in a repo: a `redocly.yaml` that keeps `recommended` and turns off the rules you disagree with. Do this once, commit it, and your CI stops crying wolf:

```yaml
# redocly.yaml
extends:
  - recommended
rules:
  security-defined: off
  no-server-example.com: off
  operation-4xx-response: off
```

```console
$ npx @redocly/cli lint clean.yaml
clean.yaml: validated in 20ms
Woohoo! Your API description is valid. 🎉
```

There's the confetti. The point stands: a spec that was valid the whole time needed a config file before the tool would admit it.

## The free alternative, if you don't want the vendor's opinions

The obvious comparison is [Spectral](https://github.com/stoplightio/spectral) (also free, also Node, also a `lint` command). I ran Spectral 6.16.3 with its stock `spectral:oas` ruleset against the exact same valid file:

```console
$ npx spectral lint clean.yaml
/tmp/redocly-test/clean.yaml
  2:6  warning  info-contact    Info object must have "contact" object.
 13:9  warning  operation-tags  Operation must have non-empty "tags" array.

✖ 2 problems (0 errors, 2 warnings, 0 infos, 0 hints)
```

Same file, different opinions, and — this is the part that matters — **zero errors, exit 0.** Spectral's defaults nag you about a missing contact and missing tags; Redocly's defaults *fail the build* over a security declaration and the example domain. Neither is "right," but if you want a linter that stays out of your way until you write its ruleset yourself, that's Spectral. If you want strong opinions out of the box and you're willing to file down the two or three that annoy you, that's Redocly — and its `no-unresolved-refs` catch is genuinely the better safety net of the two for the failure that actually ships broken SDKs.

## The verdict, on the "survives a Tuesday" scale

- **A normal Tuesday** (lint a hand-written spec in CI): **use it.** It's fast, it's deterministic across 100 runs, and it catches the dangling `$ref` that turns into a broken client. Add a `redocly.yaml` on day one so the default ruleset stops failing files that are fine, and bump `operation-operationId` to `error` so your gate isn't lying.
- **A bad Tuesday** (a truncated file from a crashed generator, a 100k-line monster, a filename someone's malware named): **use it.** Eight break-it-on-purpose scenarios, eight clean handles. It would not fall over.
- **A Tuesday where the intern has sudo** (they followed the official tutorial): **warn them first.** They will hit `redocly preview-docs`, get forty lines of help and an "unknown arguments" line they'll read as their own typo, and lose the afternoon. Tell them it's `redocly preview` or `redocly build-docs` now, and paste them a `redocly.yaml`, before they ever open a tutorial.

`redocly lint` earns the CI slot. Everything wrapped around it — the deleted command, the wall of warnings on a clean file, the load-bearing bug filed as a warning — is a first-day tax, not a dealbreaker. Pay it once, commit the config, and it does the one job you hired it for and refuses to break doing it.

*Tested: Redocly CLI 2.49.0, Spectral 6.16.3, Node v22.23.2 on Ubuntu. Every command above was run; every number is a real number. If a table row says it survived, a real input tried to kill it.*
