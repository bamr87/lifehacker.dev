---
title: "Stop the KeyError: defensively parsing tool JSON in Python"
description: "A link-checker's JSON changed shape and crashed the workflow with KeyError 'details'. Here's the repro and the defensive parse that survives all four shapes."
date: 2025-01-27
categories: [Hacks]
tags: [ci-cd, data]
author: amr
excerpt: "Your script read error['status']['details'] for a year. Then the tool moved the field, and CI died with KeyError. The fix is one helper."
preview: /images/previews/stop-the-keyerror-defensively-parsing-tool-json-in.webp
permalink: /hacks/fixing-github-actions-link-checker-keyerror/
---
The link-checking workflow had run green for months. Then one morning it went red, and the log said this:

```
KeyError: 'details'
  File "analyze_links.py", line 25, in analyze_link_failures
    'error': {'message': error['status']['details']},
                         ~~~~~~~~~~~~~~~^^^^^^^^^^^
```

Nobody touched `analyze_links.py`. The repo's markdown was the same. The only thing that changed was the link checker, which had quietly updated and moved a field around in its JSON output.

That is the whole genre of bug. Your code reads `a['b']['c']` from some other program's output, that program ships a release, and the field you indexed is now somewhere else. Python doesn't shrug it off — it raises, the process exits non-zero, and the workflow fails on a line you never edited.

## What the code assumed

The script took the checker's results and flattened each failure into a record. The offending line read the error detail out of a nested dict:

```python
# Convert the error map to individual result records
for file_path, errors in error_map.items():
    for error in errors:
        results.append({
            'url': error['url'],
            'status': 'Failed',
            'error': {'message': error['status']['details']},  # <- here
            'file': file_path,
        })
```

`error['status']['details']` bakes in three assumptions in eleven characters:

- `status` is always present,
- `status` is always a dict,
- that dict always has a `details` key.

All three were true for the version of the tool the code was written against. The new release kept `status` but renamed the human-readable text from `details` to `message` for some entries. One assumption broke, and the whole run went with it.

## Reproduce the exact crash

You don't need the link checker installed to see this. The bug is pure Python — it's a dict that doesn't have the shape you indexed. Here's the failure on its own:

```python
# Save as keyerror.py and run it: python3 keyerror.py
def analyze(error_map):
    results = []
    for file_path, errors in error_map.items():
        for error in errors:
            results.append({
                'url': error['url'],
                'status': 'Failed',
                'error': {'message': error['status']['details']},
                'file': file_path,
            })
    return results

# status is a dict, but the detail now lives under 'message', not 'details'
error_map = {"docs/intro.md": [
    {"url": "https://slow.example/", "status": {"code": 0, "message": "Timeout"}},
]}
analyze(error_map)
```

We ran that on Python 3.14. The real traceback:

```
Traceback (most recent call last):
  File "keyerror.py", line 18, in <module>
    analyze(error_map)
    ~~~~~~~^^^^^^^^^^^
  File "keyerror.py", line 9, in analyze
    'error': {'message': error['status']['details']},
                         ~~~~~~~~~~~~~~~^^^^^^^^^^^
KeyError: 'details'
```

That's the same `KeyError: 'details'` from CI, with the same carets pointing at the same subscript. The carets are doing you a favor: `^^^^^^^^^^^` sits under `['details']`, telling you exactly which access blew up — not `error`, not `['status']`, but the `['details']` on the end.

You'll know you've reproduced it correctly when the caret line points at the last subscript and the message names the missing key in quotes.

There's a meaner cousin, too. If a different release makes `status` a plain string instead of a dict, the same line throws something else:

```
TypeError: string indices must be integers, not 'str'
```

Same root cause — wrong shape — different exception. Catching only `KeyError` would miss it.

## The fix: one helper that asks before it reads

The fix isn't a bigger try/except. It's pulling the extraction into a function that checks the shape at each step and degrades instead of crashing:

```python
def extract_error_message(error):
    status = error.get('status')
    if isinstance(status, dict):
        # Try the field names the tool has used, then fall back to the raw dict
        return status.get('details') or status.get('message') or str(status)
    if status is not None:
        # status is a string (or anything else) — stringify it
        return str(status)
    # No status key at all
    return error.get('message', 'Unknown error')
```

Every line here corresponds to a shape we actually saw or could see: status-as-dict-with-details (the old shape), status-as-dict-with-message (the shape that broke us), status-as-string (the TypeError cousin), and status-absent. None of them raise. The worst case is the literal string `Unknown error`, which is a fine thing to write into a report and a terrible thing to crash a pipeline over.

Wire it into the loop and the indexing disappears:

```python
for file_path, errors in error_map.items():
    for error in errors:
        results.append({
            'url': error.get('url', ''),
            'status': 'Failed',
            'error': {'message': extract_error_message(error)},
            'file': file_path,
        })
```

## You'll know it worked when every shape comes back as text

Feed the helper all four shapes at once and watch nothing throw:

```python
# Save as fixed.py (with extract_error_message above) and run it: python3 fixed.py
cases = [
    {"url": "https://a/", "status": {"code": 404, "details": "Not Found"}},  # old shape
    {"url": "https://b/", "status": {"code": 0, "message": "Timeout"}},      # shape that broke us
    {"url": "https://c/", "status": "Cached(Ok)"},                           # status as a string
    {"url": "https://d/"},                                                   # no status at all
]
for c in cases:
    print(c["url"], "->", extract_error_message(c))
```

We ran that. The real output:

```
https://a/ -> Not Found
https://b/ -> Timeout
https://c/ -> Cached(Ok)
https://d/ -> Unknown error
```

The first row is the shape the original code handled. The second is the shape that crashed it — now it reads `Timeout` cleanly. The third and fourth are the cases the original never considered, and they come back as plain strings instead of tracebacks. That's the tell: four different input shapes, four strings out, zero exceptions.

## The .get() chain, briefly, so you trust it

`status.get('details')` returns `None` when the key is absent instead of raising. `None or status.get('message')` then moves on to the next candidate, and `or str(status)` is the last resort. The chain reads in priority order: prefer `details`, then `message`, then dump whatever the dict is so a human can read it. The one sharp edge: `or` also skips empty strings, so a genuinely-empty `details: ""` falls through to `message`. For an error report that's the behavior you want — an empty detail is no detail.

## Don't swallow the whole script, though

Defensive parsing per record is good. Wrapping the entire run in a bare `except` that prints "something went wrong" and exits 0 is not — that turns a red build into a green one that checked nothing. Keep the function tolerant and let real, unexpected failures still fail loudly:

```python
try:
    analysis = analyze_link_failures(load_results('results.json'))
except Exception as e:
    # Write a minimal report so downstream steps have a file to read,
    # then STILL fail the job — a crash is not a passing run.
    with open('analysis_summary.txt', 'w') as f:
        f.write("BROKEN_COUNT=0\nTOTAL_COUNT=0\nSUCCESS_RATE=0\n")
    print(f"Analysis failed: {e}")
    raise SystemExit(1)
```

The minimal file keeps the next workflow step from crashing on a missing path; the `SystemExit(1)` keeps the build honest. The goal is to survive *expected* variation in someone else's JSON, not to hide *your* bugs.

## The part where it broke, stated plainly

The crash wasn't a typo and it wasn't your code — it was an external tool changing its output shape under a hardcoded `a['b']['c']` access. Python turns that into an immediate `KeyError` (or `TypeError`, depending on how the shape moved) and exits non-zero, so a workflow that "we didn't touch" goes red anyway.

The lesson worth taping to the monitor: **any time you index into JSON that another program produced, that program's next release is allowed to break you.** Reach for `.get()` with fallbacks at every level you don't control, check `isinstance` before you assume a type, and pick one safe default. It's a few more lines than `error['status']['details']`, and it's the difference between a parser that bends when the tool changes and one that snaps.
