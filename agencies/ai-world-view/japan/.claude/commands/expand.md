---
description: "Grow a consolidated knowledge base at finer (month) granularity and seed the next era's lineage — the post-consolidation phase that makes consolidation non-terminal and ever-expanding."
argument-hint: "[--no-plant] — optional; skip the one-time next-lineage planting this tick"
---

Run the **expand routine** for this consolidated repo.

Canonical playbook: read `.github/prompts/expand.prompt.md` and follow it exactly. Everything is parameterized by `lifecycle.yml` (`policy.succession.next_lineage`, `policy.consolidation`, `state.granularity`, `state.next_lineage_planted`) — read it first.

Two parts:
1. **Part A — seed the next lineage (one-time)**: unless `state.next_lineage_planted` is set or `--no-plant`, create the next-era repo from `policy.succession.next_lineage`, plant the `seed-package/` framework + a fresh `lifecycle.yml` via `GH_TOKEN="$LIFECYCLE_PAT"`, germinate it, and set `state.next_lineage_planted`. It becomes an independent recursive lineage.
2. **Part B — deepen by granularity**: grow this repo at `state.granularity` (default `month`) — build-structure generates `<year>/<MM-month>/` sub-structure + monthly timelines/indices across the per-year directories, plan-roadmap targets month-level gaps, Curator fills them, publish.

Scope: never archive members or re-merge; expand only deepens this repo + plants the next lineage. End with the `## Expand Summary` block. Arguments: $ARGUMENTS
