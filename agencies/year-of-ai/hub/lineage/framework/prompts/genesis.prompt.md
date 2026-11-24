---
name: Genesis
description: "Bootstrap a fresh, fully autonomous self-growing knowledge-base repo for ANY concept from a single prompt. Use when: starting a new repository around a subject (e.g. a year, a field, a person, a technology); re-seeding an empty repo; rebuilding this repo from its seed.md DNA. Universal — the one prompt that scaffolds everything, then hands off to /grow."
argument-hint: "The seed concept to build the repo around (e.g. \"the year 1987\", \"quantum computing\", \"the Apollo program\"). Leave blank to rebuild from the existing seed.md."
agent: agent
tools: [read, edit, execute, web]
---

Bootstrap (or rebuild) this repository as a self-growing knowledge base around a single **concept**. This is the universal entry point: one prompt → a fully autonomous repo that thereafter grows via `/grow`.

## Instructions

### 1. Determine the concept
- **If an argument was given**, that string is the `subject`.
- **If blank**, read the existing [seed.md](../../seed.md) and use its Concept Definition (rebuild mode).
- **If blank and seed.md is missing/empty** but [lifecycle.yml](../../lifecycle.yml) exists, this is a freshly planted successor: the `subject` is the newest `lineage` member's `subject` (successor-germination mode).

### 2. Derive the Concept Definition
For a new subject, derive — appropriate to *that* subject, not copied from any example:
- `scope` — a one-line inclusion rule (what counts as on-topic).
- `taxonomy` — 4–7 categories/dimensions natural to the subject, each with a `name` and a kebab-case `slug`. (A year → history/science/arts/economics/people; a technology → concepts/people/milestones/ applications/controversies; etc. Derive, don't assume.)
- `source_strategy` — ≥2 authoritative sources (encyclopedic + specialist).
- `conventions` — knowledge_table heading, file_path pattern `<category-slug>/<topic-slug>.md`, frontmatter `[title, date, category]`, tone.

### 3. Write seed.md (the DNA)
Create/overwrite [seed.md](../../seed.md) with the structured blueprint: section 1 Concept Definition (the YAML block), sections 2–7 (Identity, Architecture, Content Inventory, Structure Inventory, Growth Loop, Rebuild Procedure), and section 8 Evolution Log (start it with a genesis entry; if rebuilding, preserve the existing log). Follow the structure documented in the current seed.md.

### 4. Ensure the customization layer exists
The `.github/` layer is **concept-agnostic and identical across instances**. Verify these exist; create any that are missing by copying the canonical versions (they read the concept from seed.md):
- instructions: `content.instructions.md`, `agents.instructions.md`
- skills: `research/`, `add-topic/`, `build-structure/`, `plan-roadmap/`, `sync-seed/`, `publish-session/`
- agents: `curator.agent.md`, `architect.agent.md`
- prompts: `genesis`, `grow`, `deep-dive`, `update-readme`, `encode-seed`, `publish`, `evolve`

### 5. Create the initial README
Write [README.md](../../README.md) framed for the subject: title, a one-line description, a Topics section listing the taxonomy, and a `## Notable Events` (or subject-appropriate) starter table with a few well-known, source-verified in-scope rows (use the **research** skill / `fetch_webpage`).

### 6. Seed the roadmap
Create [ROADMAP.md](../../ROADMAP.md) with an initial Backlog derived from the taxonomy (structural artifacts + content gaps + an evolve cadence), per the `plan-roadmap` format.

### 7. Hand off
Run the **sync-seed** skill to align the DNA, then optionally run one **`/grow`** tick to produce the first real growth. Report: the derived concept (subject + taxonomy), files created, and the next step (`/grow`, or register a `/schedule` routine for unattended growth).

> The result is a repo that is simultaneously a knowledge base about the concept and a reusable
> framework — copy `.github/` elsewhere and run `/genesis "<new concept>"` to spawn another.
