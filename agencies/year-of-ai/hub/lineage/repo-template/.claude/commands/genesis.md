---
description: "Bootstrap (or rebuild) a fully autonomous self-growing knowledge-base repo for ANY concept from a single prompt, then hand off to /grow."
argument-hint: "\"<concept>\" (e.g. \"the year 1987\", \"quantum computing\") — blank = rebuild from seed.md"
---

Bootstrap or rebuild this repository as a self-growing knowledge base around a single **concept**. This is the universal entry point: one prompt → a fully autonomous repo that thereafter grows via `/grow`.

Follow the canonical procedure in `.github/prompts/genesis.prompt.md` exactly:

1. **Determine the concept** — use `$ARGUMENTS` as the `subject`; if blank, read the existing `seed.md` Concept Definition (rebuild mode); if blank and `seed.md` is missing but `lifecycle.yml` exists, use the newest lineage member's `subject` (freshly planted successor).
2. **Derive the Concept Definition** appropriate to *that* subject — `scope`, a 4–7 entry `taxonomy` (name + kebab-case slug), `source_strategy` (≥2 authoritative sources), and `conventions`.
3. **Write `seed.md`** (the DNA) — section 1 Concept Definition + sections 2–7, and start/preserve section 8 Evolution Log.
4. **Ensure the customization layer exists** — the concept-agnostic `.github/` instructions, skills, agents, and prompts (and this `.claude/` adapter layer that mirrors them).
5. **Create `README.md`** framed for the subject with a starter, source-verified knowledge table.
6. **Seed `ROADMAP.md`** from the taxonomy.
7. **Hand off** — run the **sync-seed** skill, then optionally one `/grow` tick. Report the derived concept, files created, and the next step.

Concept (blank = rebuild from existing `seed.md`): $ARGUMENTS
