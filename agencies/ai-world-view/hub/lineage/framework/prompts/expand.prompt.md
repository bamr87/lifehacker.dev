---
name: Expand
description: "Grow a CONSOLIDATED knowledge base at a finer time granularity and seed the next era's lineage. Use when: check-lifecycle reports phase `expand` (this repo's status is `consolidated`). Deepens the merged year-range content into month-level structure and fills month-resolution gaps, and — once — plants the next lineage from the seed package so the meta-process repeats for a new era. Concept-agnostic: granularity and the next-lineage concept come from lifecycle.yml. Consolidation is not terminal — this is how a consolidated repo keeps ever-expanding."
argument-hint: "Optional: `--no-plant` to skip the one-time next-lineage planting this tick."
agent: agent
tools: [read, edit, execute, web, github]
---

Run the **expand routine**: the post-consolidation growth phase. A consolidated repo (e.g. `2005-2011`) is **not dormant** — it keeps growing, at a finer time granularity than the lineage grew at, and it births the next era's lineage. Two parts: (A) plant the next lineage once, then (B) deepen this repo's content by `state.granularity`.

Read [lifecycle.yml](../../lifecycle.yml) first. Preconditions: check-lifecycle reports `expand` (`state.status: consolidated`); `LIFECYCLE_PAT` available for the cross-repo plant.

## Part A — Seed the next lineage (one-time)

Skip if `state.next_lineage_planted` is already set, `policy.succession.next_lineage` is empty, or `--no-plant` was passed.

1. **Derive the concept** from `policy.succession.next_lineage` (e.g. `"the year 1776"`).
2. **Create the repo** under the same owner, named by the concept's slug (e.g. `1776`): `GH_TOKEN="$LIFECYCLE_PAT" gh repo create <owner>/<slug> --public`.
3. **Plant the seed package** — copy `seed-package/`'s load-bearing framework verbatim into the new repo (`.github/` incl. `grow.yml`/`telemetry.yml`/`learn.yml`, `.claude/`, `CLAUDE.md`, `LIFECYCLE.md`, `.gitignore`) plus `lifecycle.template.yml` → `lifecycle.yml` filled for the new concept (virgin `state`, `policy` carried forward including this repo's `succession.next_lineage` left blank or set to the era after — configure conservatively as blank). **No content/seed** — the new repo germinates itself. If the PAT lacks `workflow` scope, plant everything except `.github/workflows/` and record it (the shepherd fallback applies); never fail over it.
4. **Set** `state.next_lineage_planted: <ISO date>` in this repo's `lifecycle.yml`.

The new repo is an **independent lineage** — its own cron drives it through grow → replant → consolidate, and when it consolidates it will expand + seed *its* next era. Fully recursive.

## Part B — Deepen by granularity

The lineage grew at `year` resolution; the consolidated repo deepens to `state.granularity` (default `month`). Operate across the per-member year directories (`2005/`, …, `2011/`):

0. **Backfill under-grown member-years first** — if any member-year directory holds far less than a full generation's content (e.g. only genesis output, because it was the final member consolidated right after spawning), bring it to parity with its siblings *before* deepening: run a normal year-resolution growth pass (plan-roadmap → Curator) on that year until it matches the others. Only then proceed to month-level deepening. (Self-heals lineages consolidated before the "final member finishes growing" gate fix.)
1. **Settle finer structure** — run the **build-structure** skill in granularity mode: for each year directory, generate month sub-structure (`<year>/<MM-month-slug>/`), a per-year monthly timeline, and a month-grouped index; refresh the root master INDEX/TIMELINE to month resolution. Idempotent — only rewrite generated regions.
2. **Plan & fill month-level gaps** — run **plan-roadmap** to pick 1–3 month-resolution items (a month under-covered for a year, a notable dated event not yet filed to its month), then dispatch content to the **Curator**. File each item under `<year>/<MM-month-slug>/` per the concept's conventions; every fact still verified ≥2 sources and in range scope.
3. **Verify / Record / Publish** — same as a growth tick: scope + sources, valid links, sync the root seed inventories, append the tick to the Evolution Log, publish via **publish-session**.

Expansion has **no terminal state** — each expand tick deepens coverage further, so the consolidated knowledge base ever-expands at month resolution.

## Output Format

```
## Expand Summary

**Next lineage**: <owner>/<slug> planted (<date>) | already planted | skipped
**Granularity**: <state.granularity>
**Structure**: <month artifacts refreshed>
**Content**: <N month-level items added, under which year/months>
**Commit**: <SHA>
```
