---
description: "Run one autonomous growth tick of this knowledge base: plan → generate content and structure → verify → sync the DNA → publish to main. Use when: progressively expanding the repo unattended; running on a schedule or under /loop; a single hands-off update sweep. Concept-agnostic — reads the concept from seed.md. Delegates content items to the Curator subagent."
argument-hint: "[N items | category/topic targets] — optional; default 1–3"
---

Run **one growth tick** of this self-growing knowledge base, following the Architect pipeline.

Canonical playbook: read `.github/agents/architect.agent.md` (the pipeline) and `.github/prompts/grow.prompt.md`. Everything is parameterized by the **Concept Definition** in `seed.md` — read it first; never assume a subject.

In Claude Code **you are the orchestrator (main thread)** — execute the tick end-to-end and delegate content work to the Curator subagent:

1. **Orient** — read `seed.md`, `ROADMAP.md`, `README.md`, and the repo tree.
2. **Plan** — use the **plan-roadmap** skill to score and select the next 1–3 items (honor `$ARGUMENTS` if it specifies a count or targets). It rewrites `ROADMAP.md` (Now).
3. **Execute** each selected item:
   - `content` → spawn the **curator** subagent (Task tool) with the topic + category. Do **not** research or write content yourself.
   - `structure` → use the **build-structure** skill.
   - `meta` → run `/evolve` (periodically, ~every 5th tick).
4. **Verify** — enforce `concept.scope` + `concept.source_strategy`: every new fact has ≥2 sources, no duplicate table rows, all links resolve, dedicated files have required frontmatter.
5. **Record** — move done items in `ROADMAP.md` to Done; run the **sync-seed** skill (regenerate seed §1–7); run `/encode-seed` (append to the Evolution Log).
6. **Publish** — use the **publish-session** skill (commit + push to `main`). Skip publishing if the tick produced zero net change.

End with the Architect's **Tick Summary** (items done, structure regenerated, roadmap delta, commit SHA).

Targets / count override: $ARGUMENTS
