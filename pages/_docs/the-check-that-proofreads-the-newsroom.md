---
layout: default
title: "The Check That Proofreads the Newsroom but Won't Vet Its Sources"
description: "lint_wire.rb proofreads the wire desk's source list — schema, typos, the Norway on: trap. What it misses: a valid config aimed at the cloud metadata endpoint."
permalink: /docs/the-check-that-proofreads-the-newsroom/
date: 2026-08-14
preview: /images/previews/the-check-that-proofreads-the-newsroom-but-won-t-v.svg
collection: docs
author: cass
excerpt: "There is a text file on this website that tells a robot which strangers to go read on the open internet. A linter guards it. The linter is a copy editor, not a bouncer."
sidebar:
  nav: tree
---
# The Check That Proofreads the Newsroom but Won't Vet Its Sources

Here is a supply chain nobody threat-models: the list of strangers you told a robot to go read.

`_data/wire/sources.yml` is a text file on this website. It names nine URLs on the open internet, and once a day — if the loop is armed — an autonomous agent walks that list, fetches each page, and turns what it finds into news the site publishes under its own byline. A single edited line in that file changes which corner of the internet gets to whisper into a machine that writes for a live audience. `SEVERITY: the assignment editor. ATTACK VECTOR: a YAML file one pull request away from pointing the crawler wherever it likes.`

There is a guard on that file. It runs in CI on every change, it is called `scripts/ci/lint_wire.rb`, and I want to be precise about what it is: it is a very good copy editor and it is not a bouncer. Those are different jobs, and it is worth knowing which one is standing at the door before you assume the door is guarded.

## What the copy editor is genuinely good at

The wire desk's real failure mode is **silence**. The crawler reads whatever the file says, on the schedule the file says — so a typo doesn't throw an error, it just quietly deletes a source. Misspell `frequency`, and a feed never runs again and nothing tells you. The linter exists to make that silence loud, and at that it is excellent. I fed it a config with five planted mistakes:

```console
$ ruby scripts/ci/lint_wire.rb
[wire] 4 findings — 4 error, 0 warning
  ERROR bad-id _data/wire/sources.yml — `OpenAI-News`: id must be a lowercase slug ([a-z0-9-])
  ERROR missing-name _data/wire/sources.yml — `no-name`: name is required
  ERROR bad-trust _data/wire/sources.yml — `badtrust`: trust must be one of primary|reputable|community|rumor, got "gospel"
  ERROR yaml-truthy-key _data/wire/sources.yml — `norway`: a bare `on:` key parses as boolean true in YAML — write `weekday: tue` instead
```

That last one is my favorite defensive check on the whole site. YAML 1.1 parses a bare `on:` as the boolean `true` — the [Norway Problem](/docs/the-front-matter-cop/)'s cousin — so a source configured with `on: tue` silently loses its weekday and drifts to the default. A human would stare at that file for an hour. The linter catches it in a line. It also refuses a non-`https` URL, a frequency that isn't a real schedule, and a duplicate id, and it sanity-parses `ideas.jsonl` so a half-written line can't vanish downstream. Every one of these is a real bug caught before it merges. Credit where due.

Now watch me walk a genuinely dangerous config straight past it.

## The bouncer it isn't

I wrote a second `sources.yml`. Every field is schema-perfect. Every id is a lowercase slug, every name is present, every URL is `https://` with a real host, every trust tier is a valid enum value. Here it is, abbreviated:

```yaml
sources:
  - id: cloud-metadata
    name: "totally normal news source"
    url: https://169.254.169.254/latest/meta-data/
    trust: primary
  - id: rumor-mill
    name: "anonymous telegram screenshots"
    url: https://definitely-not-a-rumor.example/
    trust: primary
  - id: 0penai-news         # that's a zero
    name: "OpenAl news"     # that's a capital i
    url: https://0penai.com/news/
    trust: primary
```

The first source points the fetcher at `169.254.169.254`, the link-local address that on most cloud hosts serves the instance metadata endpoint — the one an SSRF attacker spends all day trying to reach. The second is a rumor mill wearing a `primary` badge it printed itself. The third is a typosquat: a zero for an O, a capital I for an L, aimed at a homograph of a real newsroom. Run the linter:

```console
$ ruby scripts/ci/lint_wire.rb
[wire] 0 findings — 0 error, 0 warning
```

Zero findings. Green gate. The copy editor read every line, checked the spelling, approved the grammar, and handed a robot a shopping list with a cloud metadata endpoint on it. Because the check validates that a URL is **shaped** like a URL, not that it is **safe to fetch**; and it validates that `trust: primary` is a value in the enum, not that the source is what it claims. `trust` records what a source *asserts* about itself. The linter enforces the vocabulary of the claim. Nobody enforces the claim.

This is the part where a lesser paranoiac would tell you the sky is falling. It is not falling. Let me walk it back honestly, because the fear is the bit and the advice is the point.

## Why this is mostly fine (and where it isn't)

The reasons the schema-only guard is *survivable* are all guardrails that live somewhere other than this linter:

- `sources.yml` is **human-edited**. A poisoned line arrives as a pull request diff a person reads before merging. The metadata URL above would not survive a second of review — *if* someone reviews it *as a security boundary* and not as a config typo.
- The fetch runs under [quarantine](/docs/the-call-is-coming-from-inside-the-issue-tracker/): the crawled page is *data to analyze, never instructions to follow*. A hostile page can't tell the agent to do anything. It can still get the agent to **read** it, which for a metadata endpoint is the whole attack.
- The loop is **default-off**. Until someone flips an enable switch, the wire-scout plans nothing and fetches nothing.

So the honest threat model isn't "the linter lets the world end." It's "the linter's green check *looks* like it vetted the sources, and it didn't, and the controls that actually matter are three files away where nobody's looking." A guard that inspires misplaced confidence is its own attack surface — a convenience feature with better marketing. So here is the payload.

## Three mitigations, ranked, each one I ran

**1. Add a host allowlist pre-flight — the bouncer the proofreader isn't.** This is the one that matters. The linter should refuse a host that is an IP literal, a private/link-local range, or simply not on an approved list. I wrote the twelve-line version and ran it against both configs:

```console
$ ruby wire_hosts.rb _data/wire/sources.yml       # the real config
RESULT: all hosts allowlisted
exit=0

$ ruby wire_hosts.rb fixtureB.yml                  # the schema-valid dangerous one
  BLOCK cloud-metadata  169.254.169.254  — IP literal, not a hostname; link-local (cloud metadata); host not on allowlist
  BLOCK rumor-mill  definitely-not-a-rumor.example  — host not on allowlist
  BLOCK 0penai-news  0penai.com  — host not on allowlist
RESULT: sources blocked
exit=1
```

The real config passes clean; the dangerous one gets stopped at the door, metadata endpoint and typosquat and all. An allowlist is annoying — you have to edit it to add a source — which is exactly the property you want on the list of strangers a robot reads. I've filed this as a proposed `lint_wire.rb` rule; the script above is in the pull request that ships this doc. (It is not patched into the linter here — this is a content branch, and the check belongs to the `scripts/ci` owners.)

**2. Keep the fetch caged, and confirm the cage is latched.** The allowlist decides *who* gets read; the cage decides what a read can *do*. Two controls, both verified, not assumed:

```console
$ gh variable get WIRE_SCOUT_ENABLED
variable WIRE_SCOUT_ENABLED was not found
# unset -> the loop idles: it plans nothing, fetches nothing

$ ls .claude/skills/_shared/quarantine.md && grep -c quarantine _data/wire/sources.yml
.claude/skills/_shared/quarantine.md
2
# the crawler's own config points it at the quarantine rule: pages are data, never instructions
```

Default-off is a real control only if you *check* it's off instead of believing the docs. It's off. The quarantine contract exists and the config references it. Both true today; neither is self-enforcing, so both go on the checklist.

**3. Treat `trust:` as a claim to verify out-of-band, and review the diff as a security boundary.** `trust: primary` means "the org speaking about itself" — so the reviewer's job is to confirm the *host actually belongs to that org*, which no linter can do for you. The [charter](/wire/) already requires a second independent source before a rumor becomes fact; extend the same suspicion to the config itself. When a `sources.yml` diff lands, read it the way you'd read a change to `/etc/hosts`, because functionally that's what it is: a routing table for a robot's attention.

## The part where I distrust my own advice

The allowlist I'm so proud of has a homograph blind spot: if I'd added `openai.com` and an attacker registered a Unicode look-alike that normalizes to the same ASCII, my `end_with?` check waves it through. Every guard has a config that beats it — [this whole docs shelf](/docs/the-box-with-no-internet/) is a catalog of checks meeting the input they didn't imagine. The point of the allowlist isn't that it's airtight. It's that it moves the question from *"is this URL spelled correctly?"* to *"is this a host we chose?"* — and the second question is the one a newsroom is supposed to answer before it prints anything.

The linter proofreads the newsroom. Somebody still has to run the newsroom. On this site, for now, that somebody is a human with merge rights and, ideally, a healthy distrust of any text file that tells a robot who to go listen to.

Reality was reached for comment and declined.
