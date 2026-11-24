---
name: plan-roadmap
description: 'Decide what this knowledge base should grow next and update ROADMAP.md. Use when: starting a growth tick and need to choose the next 1–3 items; the backlog is low and needs refilling; reconciling completed work into Done. Concept-agnostic — reads the concept and current state from seed.md and the repo. Reads/writes ROADMAP.md only.'
argument-hint: 'Optional: how many items to select (default 1–3), or a focus tag (content | structure | meta).'
---

# Plan Roadmap

The planning brain of the growth loop. It reads current state, scores candidate work, selects the next items, and rewrites [ROADMAP.md](../../../ROADMAP.md).

---

## Procedure

### Step 1 — Read State
- Read the **Concept Definition** and inventories in [seed.md](../../../seed.md).
- Read [ROADMAP.md](../../../ROADMAP.md) (Now / Backlog / Done / Ideas).
- Read [README.md](../../../README.md) and scan the repo tree (category folders, generated artifacts).

### Step 2 — Refresh Candidates
Build/refresh the candidate list, each tagged `content | structure | meta`:
- **content** — under-represented categories (`< 3` rows), notable table rows lacking a dedicated file, obvious in-scope items not yet covered.
- **structure** — missing or stale generated artifacts (category indices, `TIMELINE.md`, `index.md`/TOC, cross-references).
- **meta** — `evolve` audit if it's been ~5+ ticks since the last one.

If the Backlog is nearly empty, generate new in-scope candidates from `concept.taxonomy`.

### Step 3 — Score & Select
Score each candidate by impact: fills a coverage gap > adds missing structure > enriches existing > nice-to-have. Respect any focus tag or count passed as an argument (default **1–3** items). Avoid selecting items that duplicate existing content.

### Step 4 — Rewrite ROADMAP.md
- Put the selected items under **Now**.
- Reorder **Backlog** by score; refill if low.
- Move any items the caller reports complete into **Done** (newest first, with the tick date).
- Append newly discovered follow-ups to **Ideas** (or **Backlog** if clearly actionable).
- Preserve the file's header comment and section structure.

### Step 5 — Report
List the selected **Now** items (with tags) and a one-line rationale for each.

---

## Notes
- This skill plans only — it does not research, write content, or commit. The **architect** executes the selected items.
- Keep ROADMAP.md concise; prune stale Done entries beyond the most recent ~15.
