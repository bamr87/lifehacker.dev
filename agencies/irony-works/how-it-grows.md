---
layout: default
title: How It Grows
permalink: /how-it-grows/
preview: /assets/images/previews/default.svg
description: >
  A scheduled machine proposes candidate ironies, an adversarial gate scores
  them on five axes, and survivors arrive as a pull request. Merging is the
  selection pressure — nothing reaches canon without a human hand.
---

The vault grows on a cycle. The machine proposes; the reader disposes.

```
 idea ──SCOUT──▶ candidate ──▶ ╔═════════════╗
                               ║ ALANIS GATE ║──fail──▶ compost/
                               ╚══════╤══════╝          (the merely
                                 pass │                  unfortunate)
                                      ▼
                           SCRIBE ──▶ nursery/ (pull request)
                                      │
                          human merge = selection
                                      ▼
                                    canon
```

## The five roles

**Scout** proposes candidates for the cycle's domain — history of science, literature and language, technology, politics, commerce, or the vault itself. It is rewarded for one true irony and penalised for five plausible ones.

**The [Alanis Gate]({{ '/entries/alanis-gate/' | relative_url }})** scores each
candidate 0–2 on five axes — reversal, commentary, inevitability, specificity, and non-substitutability — and rejects anything that reduces to bad luck, coincidence, hypocrisy, or plain tragedy. Threshold is 7 of 10.

**Scribe** drafts the survivors against the entry schema, with sources, and downgrades `veracity` when the evidence is thin rather than sharpening the story to match the telling.

**Linker** weaves new entries into the graph, and **Gardener** tends it — deduplicating, chasing orphans, and revisiting
[futures]({{ '/futures/' | relative_url }}) as they mature.

## The second genus

[Paradoxes]({{ '/paradoxes/' | relative_url }}) run the same pipeline with
their own schema and their own adversary. A paradox entry states **premises**, an **inference**, a **conclusion**, and the **collision** that makes the conclusion unacceptable — an intuition, a fact, or logic itself — and the collision predicts Quine's kind: veridical, falsidical, or antinomy.
The [Epimenides Gate]({{ '/entries/epimenides-gate/' | relative_url }}) scores
plausibility, validity, collision, cost, and specificity, threshold seven, and is named for the most famous paradox in the world, which is not one. The rotation interleaves the genera: a bare domain grows ironies, a `paradox:` family grows paradoxes, and the same nursery holds both until a human merges. The framework is written up as
[The Anatomy of a Paradox]({{ '/entries/the-anatomy-of-a-paradox/' | relative_url }}).

## What the gates throw away

The rejects are kept. Every failed irony is logged in the
[compost ledger]({{ '/compost/' | relative_url }}) with its verdict:
`MERELY-UNFORTUNATE`, `BAD-LUCK`, `COINCIDENCE`, `HYPOCRISY`, or `NOT-EVEN-WRONG`; every failed paradox in a second ledger with its own: `MERELY-SURPRISING`, `EQUIVOCATION`, `TRANSPARENT-FALLACY`, `DILEMMA`, `ANOMALY`, or `NOT-EVEN-WRONG`. The negative space of a definition teaches as much as the definition — and history occasionally files an appeal.

## Veracity, because good stories lie

Every entry carries a rating: `attested`, `contested`, `legend`, or `speculative`. The better an anecdote, the more likely history has sharpened it. A pipeline that harvests great stories without a veracity axis will launder legends into an encyclopedia at machine speed, so the vault flags uncertainty as first-class metadata rather than quietly inheriting it.

## The guardrails are code, not etiquette

The engine may write to exactly three places: the
[nursery]({{ '/nursery/' | relative_url }}) and the two compost ledgers. It cannot
modify canon, its own prompts, the workflows, or the configuration — the restriction is a path whitelist enforced by a function that throws, not a sentence in a prompt asking nicely.

Promotion to canon happens one way: a human merges the pull request. That is the whole governance model, and it is the reason this site can be grown by a machine without becoming a landfill.

<p class="mt-4">
  <a class="btn btn-primary" href="{{ '/entries/' | relative_url }}">Browse every entry</a>
  <a class="btn btn-outline-secondary" href="{{ '/nursery/' | relative_url }}">See what's pending</a>
</p>
