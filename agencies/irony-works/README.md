# Irony Works

> The perpetual encyclopedia of irony. Expectation, reversed. Recursively.

[![Live site](https://img.shields.io/badge/live-bamr87.github.io%2Firony--works-2ea44f)](https://bamr87.github.io/irony-works/) [![License](https://img.shields.io/github/license/bamr87/irony-works)](LICENSE)

## Overview

**Irony Works** is a self-growing Obsidian vault that catalogs irony in all its forms — past, present, and pending — and, since its second genus was planted, paradoxes old, new, debated, and hypothetical; tended by an AI engine and published to the web with the [zer0-mistakes](https://github.com/bamr87/zer0-mistakes) theme. It is a seed, not a site: clone it, plant it, and the germination cycle takes over.

An encyclopedia of irony compiled by a machine that cannot be embarrassed is either the death of the form or its final proof. This repository exists to find out.

## Features

- Entries must state an `expectation` and a `reversal` in front matter, so irony can be checked
- The Alanis Gate scores candidate entries before they leave the nursery
- A second genus for paradoxes, old, new, debated and hypothetical
- An AI germination cycle (scout, gate, scribe, nursery and compost) run from `engine/scripts/`
- The vault is transplanted into a Jekyll collection and published with the zer0-mistakes theme

## The Premise

Irony is not a mood. It is a **structure**: an expectation, articulated or assumed, and a reversal that comments on it. Rain on a wedding day is weather. A meteorologist rained out of her own wedding is closer. A meteorologist rained out of the wedding she scheduled using her own forecast — that's an entry.

Because irony has structure, it can be **verified**. Every entry in this vault is required to state its `expectation` and its `reversal` as frontmatter fields. If a candidate cannot articulate both, it is not irony — it is merely unfortunate, and it goes to the [compost](vault/compost/the-merely-unfortunate.md).

The vault is rendered by a theme named **zer0-mistakes** — a fitting frame for a catalog of humanity's most productive mistakes. The engine's own contradictions are documented in the [Hall of Mirrors](vault/mirrors/), because an encyclopedia of irony that exempted itself would fail its own gate.

## Anatomy of an Entry

```yaml
---
title: The Kodak Moment
form: [situational, historical]     # see vault/forms/
status: canon                       # seed → sapling → canon → petrified
veracity: attested                  # attested | contested | legend | speculative
era: contemporary
expectation: >
  Kodak, synonymous with photography, would own whatever photography became.
reversal: >
  Kodak invented the digital camera in 1975, shelved it to protect film,
  and was bankrupted by it in 2012.
planted: 2026-08-06
alanis: 9/10                        # gate score, threshold 7
sources: [ ... ]
---
```

The `expectation`/`reversal` pair is the load-bearing wall. It makes irony machine-checkable, deduplicable, and traversable — you can query the vault for every entry where an institution was undone by its own invention, and the graph will hand you a genre.

The `veracity` field exists because the better an irony, the harder it must be verified. Perfect anecdotes are how legends launder themselves into encyclopedias (see [[nobels-obituary]], filed under `legend` on purpose).

## How It Grows

```
 idea ──SCOUT──▶ draft ──SCRIBE──▶ ╔═════════════╗
                                   ║ ALANIS GATE ║──fail──▶ compost/
                                   ╚══════╤══════╝          (the merely
                                     pass │                  unfortunate)
                                          ▼
                            nursery/ (pull request)
                                          │
                              human merge = selection
                                          ▼
                       canon ◀──GARDENER tends: links,
                                prunes, promotes, revisits
                                futures/ as they mature
```

A scheduled **germination cycle** (`.github/workflows/germinate.yml`) runs the engine: the Scout proposes candidates from a rotating domain list, the Scribe drafts them against the templates, the Alanis Gate scores them, and survivors arrive as a pull request into `vault/nursery/`. Merging is the selection pressure. Nothing enters canon without a human hand — the machine proposes, the reader disposes. The rotation interleaves the two genera: a bare domain (`history-of-science`) grows ironies through the Alanis Gate; a `paradox:` family (`paradox:time-and-physics`) grows paradoxes through the Epimenides Gate.

Rejected candidates are not deleted. They are logged in the compost ledger with their verdict (`MERELY-UNFORTUNATE`, `COINCIDENCE`, `HYPOCRISY`, `BAD-LUCK`), because the negative space of irony is itself instructive. Rejected paradoxes have a ledger and a verdict list of their own.

## The Alanis Gate

Quality control is named for the most famous failure of the genre: a 1996 hit single titled after irony that lists almost none — and thereby becomes the most ironic thing about itself. The gate's rubric ([engine/prompts/alanis-gate.md](engine/prompts/alanis-gate.md)) scores five axes: genuine reversal, meaningful commentary, hindsight inevitability, specificity, and non-substitutability (it must not reduce to bad luck, coincidence, or hypocrisy). Threshold: 7/10.

The song itself passes the gate. Its scenarios do not.

## The Second Genus: Paradoxes

Irony is an expectation and a reversal that comments on it. A **paradox** is the same discipline turned on reasoning: premises a reader accepts, an inference the reader cannot fault, and a conclusion the reader refuses. Every entry in `vault/paradoxes/` states all four as frontmatter — the three *apparently*s of Sainsbury's definition, plus the wall the conclusion hits:

```yaml
---
title: The Liar
type: paradox
kind: antinomy                  # veridical | falsidical | antinomy — Quine's three ways
standing: contested             # resolved | contested | open
era: ancient
posed: "4th century BCE — Eubulides of Miletus, per Diogenes Laërtius II.108"
premises:
  - "A sentence is true if and only if what it says is the case."
  - "'This sentence is false' says of itself that it is false."
  - "Every sentence is either true or false."
inference: >
  If it is true, it is false; if it is false, it is true.
conclusion: >
  The sentence is true if and only if it is false.
collision: >
  Logic itself.
fault: >
  Unlocated: Tarski's hierarchy, Kripke's gaps, and Priest's gluts each pay differently.
epimenides: 10/10               # gate score, threshold 7
---
```

The `collision` field predicts the `kind`: a conclusion that collides with an intuition is probably true (veridical); with a fact, false (falsidical); with logic itself, an antinomy, and a principle has to go. The mandate — paradoxes **old, new, debated, and hypothetical** — is encoded as fields rather than folders, because the Liar is old *and* debated and Newcomb's problem is new, debated, *and* hypothetical: `era` and `posed` carry age, `standing` carries the debate, and a `hypothesis` field, present only when the paradox rides on a counterfactual, carries the rest.

Paradox candidates face their own adversary, the **Epimenides Gate** ([engine/prompts/paradox/epimenides-gate.md](engine/prompts/paradox/epimenides-gate.md)), named for the most famous paradox in the world, which is not one — a Cretan's claim that all Cretans are liars is merely false, and its strengthened descendant is the deepest antinomy in logic. Five axes: plausibility, validity, collision, cost, and specificity; threshold 7. Rejects go to a second ledger, [The Merely Puzzling](vault/compost/the-merely-puzzling.md), with the verdicts `MERELY-SURPRISING`, `EQUIVOCATION`, `TRANSPARENT-FALLACY`, `DILEMMA`, `ANOMALY`, or `NOT-EVEN-WRONG`. The full framework is [The Anatomy of a Paradox](vault/the-anatomy-of-a-paradox.md); the three ways have notes of their own on the trunk, beside the forms of irony.

## The Vault

| Folder | Contents |
|---|---|
| `vault/forms/` | The taxonomy — one note per form of irony (verbal, situational, dramatic, Socratic, cosmic, structural, historical, meta/post) and one per way of paradox (veridical, falsidical, antinomy) |
| `vault/works/` | Annotated works: the canon of ironic literature, Sophocles to Bainbridge |
| `vault/figures/` | The ironists themselves |
| `vault/instances/` | Documented ironies of history and the present |
| `vault/paradoxes/` | The second genus — paradoxes old, new, debated, and hypothetical, each stating premises, inference, conclusion, and collision |
| `vault/mirrors/` | The Hall of Mirrors — this machine's own ironies |
| `vault/futures/` | Open positions: expectations on record, reversals pending |
| `vault/nursery/` | AI drafts awaiting review |
| `vault/compost/` | The Merely Unfortunate and The Merely Puzzling — rejected ironies and paradoxes, with verdicts |
| `vault/templates/` | Obsidian templates enforcing the schema |

Open `vault/` as an Obsidian vault. The graph view is the arboretum: forms are the trunk, everything else branches by wikilink.

## Quickstart

1. **Clone and open.** Point Obsidian at `vault/`. Start at [[Home]].
2. **Add credentials.** Preferred: run `claude setup-token` and save the result as the `CLAUDE_CODE_OAUTH_TOKEN` repo secret — the engine rides the Claude Code CLI on your subscription. Fallback: an `ANTHROPIC_API_KEY` secret for the metered [Claude API](https://docs.claude.com/en/api/overview). Locally, an authenticated Claude Code install needs no setup at all. The harness block in `engine/seed.config.yml` is the swap point (lifehacker.dev adapter stubbed).
3. **Enable Actions + Pages.** Germination runs weekly (or on dispatch, with a `count` input). Publishing builds the vault through zer0-mistakes on every push to `main`.
4. **Merge what deserves to live.** That's the whole job.

## Governance (hard guardrails)

The engine may write **only** to `vault/nursery/` and the two compost ledgers. It may never modify canon entries, its own prompts, the workflows, or this file. Promotion, pruning of canon, and rule changes are human-only. These constraints are enforced in the scripts by path whitelist, not by politeness.

## Publishing

`_config.yml` uses `remote_theme: bamr87/zer0-mistakes`. The publish workflow first runs `engine/scripts/transplant.mjs`, which converts `[[wikilinks]]` to permalinks and moves entries into a Jekyll collection, then builds and deploys Pages. The vault stays the source of truth; the site is a pressing.

## Development

```bash
npm i js-yaml --no-save
node engine/scripts/gate.mjs vault/nursery/some-entry.md
node engine/scripts/transplant.mjs
```

Full commands, conventions and gotchas for humans and AI agents live in [CLAUDE.md](CLAUDE.md).

## Contributing

Contributions are welcome via pull request. Use [Conventional Commits](https://www.conventionalcommits.org/) and keep the CI checks green. See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow. AI agents should start with [CLAUDE.md](CLAUDE.md).

## Changelog

Notable changes are recorded in [CHANGELOG.md](CHANGELOG.md); the full record is in the [commit history](https://github.com/bamr87/irony-works/commits/main).

## License

Engine: [MIT](LICENSE). Vault content: [CC BY-SA 4.0](LICENSE-CONTENT). Attribution for the founding intent belongs to [the founding prompt](vault/the-founding-prompt.md), preserved verbatim as the seed's seed.

---

<!-- bamr87-portfolio-footer -->
Part of the [bamr87 portfolio](https://github.com/bamr87) — browse every project on [Amr's GitHub profile](https://github.com/bamr87).
