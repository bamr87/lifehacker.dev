---
description: "Capture learnings from the just-closed growth cycle and embed them into the foundational prompts — telemetry friction → minimal prompt edits that make future cycles faster and cheaper. Runs off the growth critical path; pollinate fans the edits across the lineage."
argument-hint: "[--window N] — optional; number of recent runs to analyze (default: since last replant/distill)"
---

Run the **per-cycle learning flywheel** for this lineage.

Canonical procedure: read `.github/skills/learn/SKILL.md` and follow it exactly. Reads `telemetry/evolution.jsonl.gz` (the just-closed generation) and `telemetry/learnings.jsonl` (already-captured), mines for friction ranked by the optimize/streamline/minimize-time goal, embeds ≤3 minimal edits into the canonical `.github/` prompt layer (biased to *removing* work — embed known facts, delete redundant steps, tighten thrash), records each in the learnings ledger, and opens an auto-merged PR for safe-class edits (structural ones stay open for review).

Scope: framework files + `telemetry/learnings.jsonl` only — never content, `seed.md`, or `lifecycle.yml` state. End with the `## Cycle Learnings` block. Window override: $ARGUMENTS
