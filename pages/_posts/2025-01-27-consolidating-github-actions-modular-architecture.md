---
title: "Pulling the Scripts Out of the YAML: Refactoring Two Link-Checker Workflows Into One"
description: "Two link-checker workflows, both with Python heredocs buried in YAML, neither testable. A KeyError I couldn't reproduce locally moved the scripts into files."
preview: /images/previews/pulling-the-scripts-out-of-the-yaml-refactoring-tw.png
date: 2025-01-27
categories: [Field Notes]
tags: [github-actions, ci-cd, bash, python, refactoring]
author: amr
excerpt: "You can't run a script that lives inside a YAML string. I learned that the hard way, mid-incident, staring at a KeyError I couldn't reproduce."
---

I had two GitHub Actions workflows that did almost the same job. One checked links the simple way. The other checked links the elaborate way, with extra analysis bolted on. They shared most of their logic by the time-honored method of copy-paste, and both kept their actual code where no code should live: inside the YAML, as a multi-line string passed to `python -c` and `run:` blocks.

This worked right up until it didn't.

## The part where it broke

A scheduled run went red. The link checker itself had finished fine — it found some broken links, which is its entire job — but the analysis step that reads the results crashed:

```text
Traceback (most recent call last):
  File "<string>", line 7, in <module>
KeyError: 'error'
```

`File "<string>"`. Line 7 of *a string*. There is no line 7 to open, because there is no file. The code was a heredoc inside the workflow YAML, and the only way to read it was to scroll the YAML and count lines by hand.

So I wanted to do the obvious thing — run the analysis script locally against the JSON the checker had produced, and watch it fail. I could not. There was no script. There was a workflow, and somewhere in the workflow was a string that *became* a script for about forty milliseconds on a runner I no longer had access to.

That is the moment the refactor stopped being a nice-to-have.

## What the KeyError actually was

`lychee` (the link checker) emits JSON, and the shape of each failure depends on *how* the link failed. A 404 gives you a numeric `status`. A DNS failure gives you a string. The analysis code assumed every failure object had an `error` key and called `.lower()` on it:

```python
for source, entries in data["fail_map"].items():
    for e in entries:
        print(e["error"].lower())   # KeyError when there's no 'error' key
```

I pulled that exact pattern into a file and fed it a one-line fixture of a pure-404 failure. It failed the same way it failed in CI:

```text
KeyError: 'error'
```

That run is the whole point. The bug was always there; it only surfaced the day a run happened to contain a failure type that had no `error` key. In a heredoc, "feed it a fixture" is not a thing you can do. In a file, it took ten seconds.

The fix is boring, which is correct. Don't assume the key:

```python
for source, entries in data.get("fail_map", {}).items():
    for e in entries:
        # status can be an int (404), a string ("Cannot resolve"), or absent
        broken.append(e.get("url") or e.get("status") or "unknown")
```

Same fixture, after the change — this is the real output:

```text
broken: 2
 - https://example.invalid
 - https://httpbin.org/status/404
```

The rule I should have started with: external tools change the shape of their output between cases, not only between versions. Read keys with `.get()` and a default, or budget for a 3 a.m. `KeyError`.

## Why a file beats a string

Here is the thing the bloated version of this post buried under five bullet points. The advantage of a standalone script isn't "modularity" as an abstract virtue. It's two concrete, mechanical things you physically cannot do to a YAML heredoc:

**You can run it.** A shell script that builds the `lychee` command can print the command instead of executing it, so you can see what the workflow *would* do before you trust it:

```bash
#!/usr/bin/env bash
set -euo pipefail
SCOPE="${1:-website}"
cmd=(lychee --timeout 20 --max-retries 3)
case "$SCOPE" in
  docs) cmd+=("docs/") ;;
  *)    cmd+=(".") ;;
esac
printf '%s ' "${cmd[@]}"; echo
```

Run `bash run-link-checker.sh docs` and you get:

```text
lychee --timeout 20 --max-retries 3 docs/
```

No runner, no commit, no waiting for the cron. The same string, inside a workflow, you can only inspect by triggering the workflow.

**You can lint it.** This one is the closer. A script in a file is a thing `shellcheck` will read; a script inside a YAML string is, to every linter on earth, nothing but text. I ran it on the extracted file:

```bash
shellcheck run-link-checker.sh
```

It came back clean — and the day it isn't clean, it tells me about the unquoted variable before the runner does, not after. There is no equivalent for a heredoc. The linter never sees it.

That's the entire argument. Not elegance. Two tools — your shell and `shellcheck` — start working the instant the code becomes a file, and neither one can touch it while it's a string.

## What "consolidating two workflows" really means

The merge of the two workflows sounds like the headline, but it was the easy part once the scripts were files. Both workflows had been doing the same four things — install the checker, run it, analyze the JSON, open an issue if something broke. They only differed in flags. So the "unified" workflow is both flag sets exposed as inputs, nothing more:

{% raw %}
```yaml
on:
  schedule:
    - cron: '0 6 * * 1'    # Monday morning
  workflow_dispatch:
    inputs:
      scope:
        type: choice
        options: [website, docs, internal]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/link-checker/run-link-checker.sh "${{ inputs.scope || 'website' }}"
      - run: python3 ./scripts/link-checker/analyze.py < results.json
```
{% endraw %}

The body of each `run:` step is now one line — a path to a file. That's the tell that it went right: the YAML stopped containing logic and went back to doing the one job YAML is good at, which is saying *what runs*, not *being* what runs.

(If you copy that block: the `{% raw %}${{ ... }}{% endraw %}` is Actions expression syntax, wrapped so this site's Jekyll build doesn't try to evaluate it. Drop the wrapper when you paste it into a real workflow.)

## When this goes wrong

Extraction has a cost I'll name honestly. The moment the scripts leave the YAML, the workflow depends on files being present and executable at the paths it expects. Forget `chmod +x` and you trade a `KeyError` for a `Permission denied`, which at least has the decency to name a real file. And `actions/checkout` has to actually pull the scripts in — if they live in a path your sparse checkout skips, the workflow fails at the `./scripts/...` line with `No such file or directory`, and now the bug is in the plumbing, not the code.

Both of those are findable in seconds, because they name a path. That was the whole trade: I gave up the convenience of one self-contained YAML file, and I got back the ability to point at the exact line that broke. After a night of counting heredoc lines by hand, that trade was not close.

The original version of this had an AI-analysis tier and a roadmap with "machine learning" on it. I cut all of it. The useful thing here is not the ambition. It's that a script you can run and lint will tell you where it broke, and a script you can't will make you guess.
