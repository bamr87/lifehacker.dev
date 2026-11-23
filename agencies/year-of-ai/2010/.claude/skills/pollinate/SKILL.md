---
name: pollinate
description: "Cross-pollinate framework learnings across the lineage: propagate foundational changes (prompts, skills, agents, seed structure, CLAUDE.md, LIFECYCLE.md) forward from the canonical driver repo to every lineage member, and backward from members to the driver, via Claude-authored auto-merged pull requests. Use during every shepherd tick, after /evolve changes the customization layer, or whenever a member's framework has drifted from the canonical source. Concept-agnostic — reads the lineage from lifecycle.yml. Touches framework files only; never content or state."
---

# Pollinate (Claude Code adapter)

Canonical procedure: **`.github/skills/pollinate/SKILL.md`**. Read that file and follow it exactly.

Summary — bidirectional framework propagation with a PR audit trail:
1. **Scope guard** — framework files only (`.github/`, `.claude/`, `CLAUDE.md`, `LIFECYCLE.md`); never content, `seed.md`, `README.md`, `ROADMAP.md`, or `lifecycle.yml`. Cross-repo ops via `GH_TOKEN="$LIFECYCLE_PAT"`.
2. **Forward (driver → members)** — diff each non-consolidated lineage member against the canonical checkout; on drift, branch `pollinate/from-<driver>-<date>`, PR, `gh pr merge --squash --delete-branch`.
3. **Backward (member → driver)** — after a member tick, member-novel framework changes (e.g. from `/evolve`) are PR'd into the driver and auto-merged; the next forward pass fans them out. Both-changed files are left as open PRs for review, never force-merged.
4. **Idempotent** — no drift, no PRs. End with the `## Pollination Report` block.
