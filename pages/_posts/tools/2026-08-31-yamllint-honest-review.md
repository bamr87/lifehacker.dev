---
title: "yamllint: the honest review"
description: "yamllint catches the YAML that parses wrong — bare yes/no/on coercion, duplicate keys, the Norway problem — but its default profile buries it in style nags."
date: 2026-08-31
categories: [Tools]
tags: [data, system]
author: cass
verdict: "Wire it into CI — but relax the default config first, because out of the box it screams about column 81 while a bare 'NO' quietly becomes false"
excerpt: "The linter that catches the YAML your parser silently accepts — bare truthy coercion, duplicate keys, the Norway problem. Verdict: keep it, but tune it or it cries wolf."
preview: /images/previews/yamllint-the-honest-review.svg
permalink: /tools/yamllint-honest-review/
---
**Verdict: install it, wire `yamllint -c .yamllint .` into CI, and write that `.yamllint` file BEFORE you run it once — because the default profile is a smoke alarm that goes off when you make toast and stays silent during the actual fire.** yamllint is the tool that reads your config the way a compiler reads code: suspiciously, character by character, refusing to trust that "it parsed" means "it means what you think." I reach for it on any repo where a YAML file decides something that matters — which deploy target, which feature flag, which port. Every one of those files is a small unsigned instruction that some machine will obey at 3 a.m. without a human in the loop. That is my definition of an attack surface.

I have no relationship with yamllint or its author. It's free, MIT-licensed, and installs from `pip`. Nobody paid me. I don't trust things that are free either, so I read the source; it's a couple thousand lines of Python that shell out to nothing and phone home to nowhere. That is the nicest thing I will say about any dependency this month, and I'm still going to threat-model it.

## The threat nobody models: the config file everyone trusts

Here is the file I want you to be afraid of. It looks fine. It passed review. It has been in production for eight months.

```yaml
region: NO
production: yes
feature_flags:
  on: true
port: 8080
port: 9090
```

Now here is what your program actually loads when it reads that file. This is real captured output — I ran Python's own `yaml.safe_load` on that exact file, no linter, no tricks:

```console
$ python3 -c 'import yaml,pprint; pprint.pprint(yaml.safe_load(open("deploy.yml")))'
{'feature_flags': {True: True},
 'port': 9090,
 'production': True,
 'region': False}
```

Read that dictionary and feel your stomach drop. `region: NO` — the ISO country code for Norway — was silently coerced to the boolean `False`. `production: yes` became `True`, which is either what you meant or a very expensive misunderstanding. The key `on:` under `feature_flags` got parsed as the boolean `True`, so your flag is now keyed on a boolean nobody will ever look up by name. And `port` is defined twice: the parser kept `9090` and threw `8080` in the trash without a word. No error. No warning. Exit code 0. Your program is now listening on a port you didn't configure, in an environment it thinks is Norway-shaped and false.

This is the YAML boolean coercion trap, sometimes called the Norway Problem, and it is not a bug in your parser — it is the YAML 1.1 spec working as designed. `safe_load` is doing exactly what it promised. The problem is that "safe" here means "won't execute arbitrary code," not "won't quietly change what your file says."

**SEVERITY: the intern who typed `NO` meaning the country. ATTACK VECTOR: a boolean spec from 2009 that thinks `yes`, `no`, `on`, `off`, `y`, and `n` are all opinions about truth. BLAST RADIUS: one region flag, silently inverted, discovered in the incident review.**

## What yamllint does about it

Now run yamllint on the same file. This is real captured output — `yamllint -f standard` against that identical `deploy.yml`:

```console
$ yamllint -f standard deploy.yml
deploy.yml
  1:1       warning  missing document start "---"  (document-start)
  1:9       warning  truthy value should be one of [false, true]  (truthy)
  2:13      warning  truthy value should be one of [false, true]  (truthy)
  4:3       warning  truthy value should be one of [false, true]  (truthy)
  6:1       error    duplication of key "port" in mapping  (key-duplicates)
```

There it is. Three `truthy` warnings — one for each bare `NO`/`yes`/`on` that your parser was about to coerce behind your back — and one hard `error` for the duplicate `port` key, the exact bug that `safe_load` swallowed in silence. yamllint exits non-zero, which means CI can actually stop the merge. This is the whole reason the tool exists and earns its place: it flags the class of mistake that a plain parse accepts without complaint. That two-line `python3 -c 'import yaml; yaml.safe_load(...)'` snippet people recommend as the "free alternative"? I just showed you it loads this file happily and hands you a Norway that is `False`. It validates that the YAML parses. yamllint validates that the YAML means something. Those are different jobs, and only one of them catches the incident.

So why isn't this the easiest recommendation I've ever written? Because of what else is in that output, and what happens the first time you point it at a real repo.

## The dealbreakers that stay in the box

**The default profile is puritanical, and it hides the fire behind the toast.** Point stock yamllint at a real file and the `truthy` and `key-duplicates` findings — the ones that matter — are buried under a wall of `line-length` errors capped at **80 columns** and `document-start` nags demanding a leading `---`. I ran it against one real post's front matter on this very site and got nineteen `line too long (104 > 80 characters)` errors before it reached anything semantic. A tool that reports the SEO description being 81 columns wide at the same severity as a duplicate key is a tool training you to ignore it. Alert fatigue is not a UX complaint; it is how the real finding gets scrolled past.

**`extends: relaxed` is a trap that disarms the one rule you needed.** The obvious fix — start from the built-in `relaxed` profile — is worse than it looks. I tested it. On that same `deploy.yml`, `extends: relaxed` silenced the line-length noise, yes, but it ALSO silenced all three `truthy` warnings. The relaxed profile turns off truthy checking. So you quiet the toast alarm and, in the same motion, unplug the smoke detector in the server room. "Relaxed" is marketing for "we removed the check that would have caught your Norway."

**It lints text, not Jekyll, so it lies about files that build perfectly.** yamllint has no idea what a Jekyll post is. It reads the `---` at the top as a YAML document-start marker, lints your front matter, hits the closing `---`, and then keeps going — treating your Markdown body as a second YAML document. Real captured output from a real post on this site, whose body opens with a bold `**Verdict:`:

```console
$ yamllint -f standard 2025-07-22-vscode-for-neuroscience.md
  13:2      error    syntax error: expected alphabetic or numeric
                     character, but found '*' (syntax)
```

That file builds cleanly and serves in production. yamllint calls it a syntax error because a Markdown `**` is not valid YAML, which is true and completely useless. Every static-site repo needs an `ignore:` block or yamllint will fail your build over prose.

**It's a Python install carrying its own version drift.** It's `pip install yamllint`, which means it lives in whatever Python environment your CI runner happens to have that week, and "works on my machine" is a supply-chain statement I take personally. If you'd rather not pin a Python dep, the same lint runs in a container with no local install:

```bash
docker run --rm -v "$PWD":/data cytopia/yamllint .
```

I'll be honest: I didn't run that container line for this review — I ran the `pip`-installed `yamllint 1.38.0` for every captured block above. I'm showing you the invocation, not claiming its output. Pin the image digest if you use it; `latest` is somebody else's mutable pointer, and I don't let strangers pick my linter's version.

## The three mitigations that actually matter

Paranoia without a payload is just anxiety. Here is what I actually configured and tested, ranked.

**1. Ship a tuned `.yamllint` that keeps the semantic rules and kills the style theater.** This is the whole game. Disable the noise, keep `truthy` strict, keep `key-duplicates` at error. I ran this exact config against the trap file:

```yaml
# .yamllint
extends: default
rules:
  line-length: disable
  document-start: disable
  truthy:
    check-keys: true
    allowed-values: ['true', 'false']
```

```console
$ yamllint -c .yamllint -f standard deploy.yml
  1:9       warning  truthy value should be one of [false, true]  (truthy)
  2:13      warning  truthy value should be one of [false, true]  (truthy)
  4:3       warning  truthy value should be one of [false, true]  (truthy)
  6:1       error    duplication of key "port" in mapping  (key-duplicates)
```

Same real findings, zero line-length noise. Now the output is all signal, and a developer might actually read it. Add an `ignore:` for `pages/_posts/**` if you're on Jekyll.

**2. Quote every string that YAML could mistake for a boolean, a number, or a country.** yamllint tells you where; this fixes it for good. `region: "NO"` stays the string `"NO"`. Quote `"yes"`, `"no"`, `"on"`, `"off"`, and version numbers like `"1.10"` that would otherwise become the float `1.1`. The `truthy` rule with `check-keys: true` (mitigation 1) is what makes this enforceable in CI instead of aspirational in a style guide. The reader is the protagonist here: you didn't type a bug, the spec ambushed you — this is the fix that ends the ambush.

**3. Never trust `extends: relaxed` as your whole config.** If you inherit a repo whose `.yamllint` is one line reading `extends: relaxed`, treat it as a disabled smoke detector. Verify what's actually on: `yamllint -c .yamllint --list-files .` won't show rule state, so read the resolved rules or just test it against a known-bad file like my `deploy.yml` and confirm it still catches the duplicate key and the bare `yes`. A linter you didn't test is a linter you're trusting on marketing, and I don't do that.

## Should you use it

Yes — with the tuned config, not the default one. yamllint catches the exact class of YAML failure that your parser accepts in silence and your reviewer's eyes slide right over, and it does it in a couple of seconds with no network and no telemetry. The dealbreakers are all configuration, not corruption: a puritanical default profile, a `relaxed` mode that throws out the baby, and total ignorance of Jekyll. Tune it once, commit the `.yamllint`, wire it into CI, and it becomes the quiet check that turns a 3 a.m. incident into a rejected pull request.

The free alternative — the two-line `yaml.safe_load` — is free because it does less: it proves your file parses and tells you nothing about what it parsed into. I showed you what that costs. Reality was reached for comment about why `NO` means `False`, and declined.
