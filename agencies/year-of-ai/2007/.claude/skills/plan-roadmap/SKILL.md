---
name: plan-roadmap
description: "Decide what this knowledge base should grow next and update ROADMAP.md. Use when starting a growth tick and needing to choose the next 1–3 items, when the backlog is low and needs refilling, or when reconciling completed work into Done. Concept-agnostic — reads the concept and current state from seed.md and the repo. Reads/writes ROADMAP.md only."
---

# Plan Roadmap (Claude Code adapter)

Canonical procedure: **`.github/skills/plan-roadmap/SKILL.md`**. Read that file and follow it exactly.

Summary — the planning brain of the growth loop:
1. **Read state** — the Concept Definition + inventories in `seed.md`, `ROADMAP.md` (Now / Backlog / Done / Ideas), `README.md`, and the repo tree.
2. **Refresh candidates**, each tagged `content | structure | meta`:
   - `content` — under-represented categories (`< 3` rows), notable rows lacking a dedicated file, obvious in-scope items not yet covered.
   - `structure` — missing/stale generated artifacts (category indices, `TIMELINE.md`, `INDEX.md`/TOC, cross-refs).
   - `meta` — an `evolve` audit if it's been ~5+ ticks.
3. **Score & select** by impact (fills a coverage gap > adds missing structure > enriches existing > nice-to-have); respect any focus tag/count argument (default 1–3); avoid duplicates.
4. **Rewrite `ROADMAP.md`** — selected items under Now; reorder/refill Backlog; move completed items to Done (newest first, with tick date); append discovered follow-ups to Ideas. Preserve the header comment and structure.
5. **Report** the selected Now items with a one-line rationale each.

This skill **plans only** — it does not research, write content, or commit.
