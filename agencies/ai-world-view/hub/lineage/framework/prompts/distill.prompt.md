---
name: Distill
description: "Lineage meta-review on the frontier model: analyze every member repo end-to-end (seeds, Evolution Logs, framework, failure history), improve the whole evolution cycle, and distill it into a minimal portable seed package that can spawn a similar-or-better lineage for ANY starting concept. Use when: the lifecycle gate reports phase `distill` (lineage reached distill_at_members); manually re-distilling after major framework changes. Runs in the lineage driver; reads all members via LIFECYCLE_PAT."
argument-hint: "Optional: `--force` to re-distill even if state.distilled_at is already set."
agent: agent
tools: [read, edit, execute, web, github]
---

Run the **distillation**: a frontier-model retrospective across the whole lineage whose goal is a **bare-minimum seed package** — the smallest set of seeds, instructions, prompts, and workflows that, after configuration (concept + org + secrets), grows a similar-or-better lineage for **any** starting concept (e.g. "the year 1776", "an organization", "a technology").

Read [lifecycle.yml](../../lifecycle.yml) first. Preconditions: the lifecycle gate reports `distill` (lineage ≥ `distill_at_members`, `state.distilled_at` null) or `--force`; `LIFECYCLE_PAT` available for cloning members. **Run only in the canonical driver — the `lineage[0]` repo.** Distillation ships the portable `seed-package/` and sets `state.distilled_at`, and the driver is the deterministic forward-pollination source; a non-driver member that self-distills writes the package into the wrong repo and leaves the driver un-distilled. If this repo is not `lineage[0]`, stop (the workflow phase gate already enforces this — see `grow.yml`).

## Part A — Review the lineage

1. Clone every lineage member (`GH_TOKEN="$LIFECYCLE_PAT"`).
2. Read `telemetry/learnings.jsonl` in the driver first — this is the already-captured friction ledger (`status: embedded`). Note every captured learning id/signal so you can mark them `already-embedded` in step 4 and skip re-deriving them. The goal is to find **new** structural and cross-member patterns, not to re-verify what the per-cycle `/learn` passes already fixed.
3. Study, per member: `seed.md` (especially §8 Evolution Logs — the genesis records), `lifecycle.yml`, content shape and quality, and the framework layer; in the driver, also the merged PR history (`gh pr list --state merged`) — it is the failure-and-fix ledger (token scopes, permission denials, conflict patterns, propagation gaps).
4. Extract findings: what every successful generation actually needed at birth vs. what was carried along unused; which prompt instructions earned their tokens; which failures recur and are NOT already in learnings.jsonl; where quality varies between members and why.

## Part B — Improve the cycle

Apply concrete improvements to the **live framework** in the driver (prompts, skills, agents, instructions, workflow, CLAUDE.md/LIFECYCLE.md): tighten what's bloated, fix what the failure ledger shows breaking, encode member-quality lessons into the Curator/Architect guidance. Stay concept-agnostic — never bake a year or subject into framework logic. The `pollinate` skill fans these improvements out to every member on the next tick.

## Part C — Distill the seed package

Create/refresh **`seed-package/`** in the driver repo — the portable bootstrap kit:

- `README.md` — configure-and-launch instructions for a brand-new lineage: create the GitHub org, set org secrets (`ANTHROPIC_API_KEY`, `LIFECYCLE_PAT` with repo-create/archive + workflow scope, optional `CLAUDE_CODE_OAUTH_TOKEN`), install the Claude GitHub App, create the first repo named for the starting concept, copy the package contents, push — the cron germinates it from there. Include the worked example: starting concept "the year 1776".
- `seed.template.md` — minimal Concept Definition skeleton (§1 YAML with placeholders + empty §8 Evolution Log); everything else regenerates.
- `lifecycle.template.yml` — full policy block (succession/consolidation/models/distill knobs with placeholder rules) + virgin state.
- `MANIFEST.md` — the exact minimal file list that constitutes the package (which `.github/` and `.claude/` files are load-bearing, which are regenerable), with one line on each file's role.

The package body **is** the framework layer — the manifest references it rather than duplicating it. Test of done: a reader with the package, an org, and two secrets can reach a germinated, self-growing first repo without touching anything else.

## Part D — Record & publish

1. Set `state.distilled_at: <ISO date>` in `lifecycle.yml`.
2. Append a `### Distillation — <date>` entry to seed.md §8 (findings, improvements, package version) via **encode-seed**.
3. Publish via **publish-session**.

## Output Format

```
## Distillation Report

**Members reviewed**: <n> — <slugs>
**Findings**: <3–7 bullets, sharpest first>
**Cycle improvements applied**: <files touched + why>
**Seed package**: seed-package/ @ <commit> — <file count> files, bootstrap-tested logic: <ok | gaps>
**Next**: improvements fan out via pollinate on the next tick
```
