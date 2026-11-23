---
name: learn
description: "Capture learnings from a completed growth cycle and embed them into the foundational prompts. Reads the telemetry ledger for the just-closed generation, mines it for recurring friction, wasted/redundant work, failures, and slow steps, then writes the minimal edits to the .github/ prompt/skill/agent layer that remove that friction — so future cycles run faster and cheaper. Records each learning in an append-only ledger to avoid re-deriving it. Concept-agnostic; pollinate fans the embedded edits across the lineage. Touches framework files + the learnings ledger only — never content, seed.md, or lifecycle state."
---

# Learn — the per-cycle improvement flywheel

Close the loop between the raw telemetry (`telemetry/evolution.jsonl.gz`) and the foundational prompts. The **goal is to optimize, streamline, and minimize the processing time** of every future growth cycle: each learning graduates from *observed in the data* → *embedded in a prompt* so the agent never re-derives it. This is the fast, narrow loop; `/distill` is the deep, infrequent one.

## Scope guard (hard rules)

- **Edit only**: `.github/` (instructions, skills, agents, prompts, workflow prose), `.claude/` adapters, `CLAUDE.md`, `LIFECYCLE.md`, and `telemetry/learnings.jsonl`.
- **Never** touch content files, `seed.md`, `README.md`, `ROADMAP.md`, or `lifecycle.yml` state.
- **Stay concept-agnostic** — never bake a year/subject into a prompt.
- Bound the run: **≤ 3 learnings per invocation**, smallest edits that work. Cheap and fast beats thorough — this runs every generation.

## Procedure

1. **Read the window.** Decompress `telemetry/evolution.jsonl.gz`; take the records since the last `### Replant`/`### Distillation` boundary (the just-closed generation), typically 4–6 runs. Read `telemetry/learnings.jsonl` (already-captured learnings) — **never re-derive** one that is already `embedded` or `superseded`. **Shallow-generation fast-path**: if every record in the window has `phase_resolution.phase ≠ grow` (e.g. all records are `distill` or `replant`), the generation had no growth ticks. Limit mining to framework-level observations from the distillation/replant result text; skip steps that require ≥2 growth-tick runs to detect recurrence. Fewer signals → fewer edits is correct.
2. **Mine for friction**, ranked by the optimization goal:
   - **Recurring re-derivation** — the same fact/limitation re-investigated or re-reported in ≥2 run summaries (e.g. a known scope gap flagged every run). *Highest value: embedding it as a known fact removes turns from every future run.*
   - **Wasted/no-op runs** — `is_error` results, 1-turn runs, fallbacks that should have fired.
   - **Redundant work** — repeated tool sequences that re-establish state a prior step guaranteed.
   - **Abnormal cost/turns/duration** — outliers vs. the cycle median.
   - **Failures & denials** — anything that blocked or retried.
3. **Synthesize ≤3 edits**, biased toward changes that *remove* work:
   - **Embed a known fact** into the relevant prompt so the agent stops re-investigating it.
   - **Delete a redundant step** the data proves is a no-op.
   - **Tighten an instruction** that caused thrash or an avoidable retry. Apply each to the **canonical `.github/` file** (keep `.claude/` adapters' descriptions in sync).
4. **Record** each learning in `telemetry/learnings.jsonl` (schema below), `status: embedded`.
5. **Publish.** Branch `learn/<generation>-<YYYYMMDD>`, commit `chore(learn): embed <n> cycle learning(s) — <summary>`, open a PR, and **auto-merge (`--squash --delete-branch`) only if every edit is in the safe class** (known-fact embedding, redundant-step removal, instruction clarification). Anything structural → leave the PR open and flag it. `pollinate` fans merged edits across the lineage on the next tick.
6. **Idempotent**: no new actionable signal → no edit, no PR.

## Learnings ledger schema — `learnings/v1`

One JSON object per line in `telemetry/learnings.jsonl`:

| Field | Meaning |
|---|---|
| `schema` | `"learnings/v1"` |
| `id` | Stable id, e.g. `L007` |
| `observed_in` | Run numbers / generation the signal came from |
| `signal` | One line: the friction observed in the telemetry |
| `class` | `recurring-rederivation` \| `wasted-run` \| `redundant-work` \| `cost-outlier` \| `failure` |
| `action` | `embed` \| `delete-step` \| `tighten` \| `flag-for-review` |
| `target` | The framework file the edit landed in |
| `status` | `embedded` \| `flagged` \| `superseded` |
| `expected_impact` | e.g. `"-3 turns/run"`, `"removes a doomed primary attempt"` |
| `recorded_at` | ISO date |

## Output Format

```
## Cycle Learnings — <generation>

**Window**: runs <a>–<b> (<n> records)
**New learnings embedded**: <m>
| id | signal | action → target | expected impact |
|----|--------|-----------------|-----------------|
**Flagged for review**: <PRs left open | none>
**Skipped (already captured)**: <count>
```
