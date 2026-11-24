---
title: "Planting Irony Works: Making Irony Machine-Checkable"
description: "Design notes from building a self-growing Obsidian encyclopedia of irony — schema-first AI curation, adversarial gates, and PRs as natural selection."
date: 2026-08-06
draft: true
categories: [posts, ai, knowledge-systems]
tags: [obsidian, github-actions, claude, jekyll, zer0-mistakes, agentic-workflows, irony]
lastmod: 2026-08-06
---

Today's session started with a one-paragraph prompt — build the perpetual encyclopedia of irony — and ended with a 55-file seed repository: an Obsidian vault, a five-prompt AI engine, three GitHub Actions workflows, and a quality gate named after Alanis Morissette. The interesting part isn't the whimsy. It's that the whimsy forced several genuinely reusable patterns for AI-grown knowledge bases.

## The core problem: fuzzy concepts don't scale

"Collect all the irony" is exactly the kind of instruction that turns an autonomous content pipeline into a landfill. An LLM will happily generate infinite plausible-sounding ironies, most of which are actually bad luck, coincidence, or hypocrisy wearing irony's coat. Volume was never going to be the challenge; *discrimination* was.

The fix was schema-first. Irony has a structure — an expectation and a reversal that comments on it — so we made that structure mandatory frontmatter:

```yaml
expectation: >
  Kodak, synonymous with photography, would own whatever photography became.
reversal: >
  Kodak invented the digital camera in 1975, shelved it to protect film,
  and was bankrupted by it in 2012.
```

If a candidate can't fill both fields, it isn't irony — it's merely unfortunate, and the pipeline routes it to a compost ledger instead of the vault. This is the transferable lesson: **when you want an AI to curate a fuzzy concept, don't define the concept in prose — encode its skeleton as required fields.** The schema becomes the classifier. It works for irony; it would work equally well for "tech debt," "design patterns," or "postmortem-worthy incidents."

## The Alanis Gate: adversarial review beats better generation

Instead of prompting the generator to be more careful, we gave it an adversary. Every candidate passes through a separate gate prompt that scores five axes (genuine reversal, meaningful commentary, hindsight inevitability, specificity, non-substitutability) and issues a verdict below threshold: MERELY-UNFORTUNATE, BAD-LUCK, COINCIDENCE, HYPOCRISY, or NOT-EVEN-WRONG.

Two implementation details mattered more than expected. First, the gate ships with a **calibration set** — worked examples at known scores, including the canonical rejects (rain on a wedding day: 2/10) and a deliberately tricky pass (the song "Ironic," judged as a whole, is genuinely ironic *because* its scenarios aren't). Calibration examples stabilize LLM scoring far more than adjectives in the rubric do. Second, the gate outputs its **axis scores and reasoning**, not just verdicts — which keeps the human reviewer checking work rather than rubber-stamping trust.

Rejections aren't deleted, either. The compost ledger logs every failure with its verdict, which gives the human curator negative examples to calibrate against and leaves a paper trail for appeals. Knowledge systems need a visible "no" pile.

## PRs as selection pressure

The growth loop runs as a scheduled GitHub Action: scout proposes candidates for a rotating domain, scribe drafts them, the gate scores them, and survivors arrive as a pull request into a `nursery/` folder. Nothing reaches canon without a human merge.

This turns out to be the cheapest possible governance model, because Git already built it. The PR *is* the review interface, the diff *is* the provenance record, and merge-vs-close *is* natural selection. Borrowing from the AI Evolution Engine work, the engine also runs under hard guardrails — a path whitelist in code (nursery and compost only; never canon, prompts, workflows, or config), enforced by a function that throws, not by a sentence in the prompt asking nicely. If a machine can rewrite its own rules, it eventually will; make the filesystem say no.

## Dual-format publishing: Obsidian in, Jekyll out

The vault is authored in Obsidian conventions (wikilinks, callouts, graph-colored folders) but published through the zer0-mistakes Jekyll theme. Rather than compromise either format, a small `transplant.mjs` script runs at build time: it indexes every note's title, rewrites `[[wikilinks]]` into collection permalinks, and emits a `_entries/` collection for Jekyll. Source of truth stays local-first and human-editable; the site is a build artifact. One-way transforms at publish time beat trying to make two ecosystems share a dialect.

## A veracity field, because good stories lie

One unglamorous field earned its place fast: `veracity: attested | contested | legend | speculative`. The better an anecdote, the more likely history has sharpened it — Nobel's famous premature obituary, for instance, is a documented *legend*: the will and the prizes are fact, but the triggering clipping has resisted verification. An AI pipeline that harvests "great stories" without a veracity axis will launder legends into an encyclopedia at machine speed. Flagging uncertainty as first-class metadata is cheaper than un-teaching a corpus later.

## Working-with-AI tip

When you want an AI to *judge* content and not just generate it, split the roles into separate prompts and make the judge output structured scores with reasons — then anchor the judge with a calibration set of worked examples at known scores, including near-misses. A generator with taste is unreliable; a generator plus a calibrated adversary plus a human merge button is a pipeline. And put the real guardrails in code: the prompt says "please don't touch canon," but the `assertWritable()` function is what actually means it.

## What's next

Wire the lifehacker.dev harness adapter (the swap point is stubbed in `engine/scripts/lib.mjs`), let a few germination cycles run, and see whether the Comprehensiveness Wager — the vault's own open bet that gated growth can scale without becoming the Library of Babel — settles as discipline or as the Hall of Mirrors' next exhibit.
