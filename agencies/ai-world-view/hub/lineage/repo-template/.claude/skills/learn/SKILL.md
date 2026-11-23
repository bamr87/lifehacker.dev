---
name: learn
description: "Capture learnings from a completed growth cycle and embed them into the foundational prompts. Reads the telemetry ledger for the just-closed generation, mines it for recurring friction, wasted/redundant work, failures, and slow steps, then writes the minimal edits to the .github/ prompt/skill/agent layer that remove that friction — so future cycles run faster and cheaper. Records each learning in an append-only ledger to avoid re-deriving it. Concept-agnostic; pollinate fans the embedded edits across the lineage. Touches framework files + the learnings ledger only — never content, seed.md, or lifecycle state."
---

# Learn (Claude Code adapter)

Canonical procedure: **`.github/skills/learn/SKILL.md`**. Read that file and follow it exactly.

Summary — the per-cycle improvement flywheel (telemetry → embedded prompt edits):
1. **Window**: read `telemetry/evolution.jsonl.gz` records since the last `### Replant`/`### Distillation`; read `telemetry/learnings.jsonl` to skip already-captured learnings.
2. **Mine** for friction, ranked by the optimize/streamline/minimize-time goal: recurring re-derivation (same fact re-investigated every run — highest value), wasted/no-op runs, redundant work, cost/turn outliers, failures.
3. **Embed ≤3 edits** into the canonical `.github/` layer, biased to *removing* work (embed a known fact so the agent stops re-deriving it; delete a proven-redundant step; tighten a thrash-causing instruction).
4. **Record** each in `telemetry/learnings.jsonl` (`learnings/v1`), `status: embedded`.
5. **Publish**: branch `learn/<gen>-<date>`, PR, auto-merge (`--squash`) only safe-class edits; structural ones stay open for review. `pollinate` fans them out.

Scope: framework files + learnings ledger only — never content, `seed.md`, `README.md`, `ROADMAP.md`, or `lifecycle.yml`. Idempotent. End with the `## Cycle Learnings` block.
