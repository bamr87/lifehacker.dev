---
name: Grow
description: "Run one autonomous growth tick of this knowledge base: plan → generate content and structure → verify → sync the DNA → publish to main. Use when: progressively expanding the repo unattended; running on a schedule (Claude routine) or under /loop; a single hands-off update sweep. Concept-agnostic — reads the concept from seed.md. Delegates to the Architect agent."
argument-hint: "Optional: how many items to do this tick (default 1–3), or specific categories/items to target."
agent: architect
tools: [read, search, todo, agent]
---

Run **one growth tick** by following the Architect's pipeline. Read the **Concept Definition** in [seed.md](../../seed.md) first — everything is parameterized by it.

Delegate the full tick to the **Architect** agent ([architect.agent.md](../agents/architect.agent.md)), which executes:

1. **Orient** — read [seed.md](../../seed.md), [ROADMAP.md](../../ROADMAP.md), [README.md](../../README.md), and the repo tree.
2. **Plan** — `plan-roadmap` skill selects the next 1–3 items (honor any argument override).
3. **Execute** — `content` → **Curator** agent; `structure` → **build-structure** skill; `meta` → **evolve** prompt (periodic).
4. **Verify** — enforce `concept.scope` + `concept.source_strategy`; no duplicate rows; valid links; required frontmatter.
5. **Record** — update [ROADMAP.md](../../ROADMAP.md); run **sync-seed** (regenerate seed sections 1–7); run **encode-seed** (append to the Evolution Log).
6. **Publish** — **publish-session** skill commits and pushes to `main`.

End with the Architect's Tick Summary (items done, structure regenerated, roadmap delta, commit SHA).

> Unattended use: register this prompt as a recurring Claude routine via `/schedule` (e.g. daily),
> or run it under `/loop`. Auto-push to `main` requires the run environment to have git push access.
