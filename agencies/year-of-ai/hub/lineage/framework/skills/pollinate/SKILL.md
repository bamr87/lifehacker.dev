---
name: pollinate
description: "Cross-pollinate framework learnings across the lineage: propagate foundational changes (prompts, skills, agents, seed structure, CLAUDE.md, LIFECYCLE.md) forward from the canonical driver repo to every lineage member, and backward from members to the driver, via Claude-authored auto-merged pull requests. Use during every shepherd tick, after /evolve changes the customization layer, or whenever a member's framework has drifted from the canonical source. Concept-agnostic — reads the lineage from lifecycle.yml. Touches framework files only; never content or state."
---

# Pollinate

Keep the **foundational logic** — `.github/` (instructions, skills, agents, prompts, workflows), `.claude/` (adapters), `CLAUDE.md`, `LIFECYCLE.md` — convergent across every repository in the lineage, in both directions, with a pull-request audit trail. Claude is the intermediary: it authors the PRs, and it merges them.

> **Forward pollination is now deterministic.** `.github/scripts/lineage.sh` runs before the
> agent on every tick and mirrors the canonical framework into drifted successors (Direction 1)
> with zero model turns — telemetry showed the hand-run forward pass was the lineage's single
> biggest cost sink. This skill is now used for the **backward** path (Direction 2, which needs
> judgement) and for manual propagation after an `/evolve`. Do not re-run Direction 1 by hand on
> a shepherd tick; that duplicates `lineage.sh`.

## Scope guard (hard rules)

- **Framework files only**: `.github/`, `.claude/`, `CLAUDE.md`, `LIFECYCLE.md`.
- **Never** touch a repo's content files, `seed.md`, `README.md`, `ROADMAP.md`, or `lifecycle.yml` — those are per-instance and machine-maintained.
- All cross-repo git/`gh` operations use `GH_TOKEN="$LIFECYCLE_PAT"` / the `x-access-token` remote.
- If pushing `.github/workflows/` is rejected (PAT lacks `workflow` scope), retry the branch without the workflows directory and note the skip in the PR body.

## Direction 1 — forward (driver → members)

The lineage **driver** (the repo whose workflow is executing; normally the oldest member) is the canonical framework source.

1. Read `state.lineage` from `lifecycle.yml`. Targets: every member except this repo and any `consolidated`/archived member.
2. For each target: clone it, diff its framework files against this repo's checkout.
3. If there is a diff: create branch `pollinate/from-<driver-slug>-<YYYYMMDD>`, apply the canonical versions, commit (`chore: pollinate framework from <driver> — <one-line summary>`), push, then `gh pr create` (body lists the changed files and the originating commit/learning) and `gh pr merge --squash --delete-branch`. If the merge is blocked (protections, conflicts), leave the PR open and report it instead of forcing.
4. No diff → no PR, no noise.

## Direction 2 — backward (member → driver)

Members improve the framework too — an `/evolve` run inside a member tick, a fix the agent made to a prompt or skill while working there. Those learnings must not die in the member.

1. After executing a tick in a member clone, diff the member's framework files against the driver's checkout.
2. Classify each differing file:
   - **Member-novel** (the member changed it; the driver's version is the older common ancestor): candidate for back-propagation.
   - **Driver-newer** (the driver changed it and the member is stale): handled by Direction 1 — do not overwrite the driver.
   - **Both changed**: do not auto-merge. Open the PR without merging and flag it for review.
3. For member-novel changes: branch `pollinate/from-<member-slug>-<YYYYMMDD>` **in the driver repo**, apply, commit, PR, `gh pr merge --squash --delete-branch`. The next forward pass fans the learning out to every other member automatically.

## Cadence

Forward (Direction 1) is handled deterministically by `.github/scripts/lineage.sh` before each tick — not by this skill. Invoke this skill for the **backward** pass (after a member tick that changed framework files) and for manual `/evolve` propagation. One PR per repo per direction per run, maximum. Idempotent: a rerun with no drift produces nothing.

## Output Format

```
## Pollination Report

**Forward**: <n> member(s) updated via PR (<links>) | all in sync
**Backward**: <learning summary + PR link | none>
**Flagged for review**: <PRs left open, with reason | none>
```
