---
description: "Audit and improve this repo's AI customization layer (agents, instructions, skills, prompts) — discoverable descriptions, minimal tools, correct delegation, concept-agnosticism."
argument-hint: "<scope: agents|instructions|skills|prompts> — blank = audit all"
---

Audit the AI customization layer and implement the highest-impact improvements. Keep it **concept-agnostic** — every file must read the concept from `seed.md`, never hardcode a subject.

Follow the canonical procedure in `.github/prompts/evolve.prompt.md`:

1. **Inventory** `.github/{agents,instructions,skills,prompts}` (or just the `$ARGUMENTS` scope).
2. **Evaluate** each file: discoverable "Use when:" description; minimal tools; correct delegation (orchestrators delegate, content agents don't orchestrate); required sections present; no scope creep; concept-agnostic; complete frontmatter. Mark Pass / Warn / Fail.
3. **Rank** Warn/Fail items by impact (broken delegation → undiscoverable descriptions → missing sections → over-tooled → missing referenced files).
4. **Implement** all Fail items and the top ~3 Warn items, editing in place.

After changing any `.github/` prompt, agent, or skill, **update its `.claude/` adapter** (`.claude/commands`, `.claude/agents`, `.claude/skills`) so the two layers stay in sync — descriptions especially.

Scope: $ARGUMENTS
