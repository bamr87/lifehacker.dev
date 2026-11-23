---
description: "Use when creating, editing, or reviewing agent files for this repository. Covers tool minimalism, delegation patterns, required sections, output format conventions, and concept-scope constraints for .agent.md files."
applyTo: ".github/agents/*.agent.md"
---

# Agent Authoring Conventions

Agents in this repo are **concept-agnostic**. They read the **Concept Definition** from [seed.md](../../seed.md) and operate on whatever `subject`/`taxonomy` it declares — never hardcode a specific subject (e.g. a particular year) into an agent.

## Tool Selection

- Assign the **minimum set of tool aliases** needed for the agent's role. Excess tools dilute focus.
- Orchestrator agents (those that delegate to subagents) should only need `[read, search, todo, agent]`.
- Agents that create or edit files directly add `edit` (and `execute`/`web`) only if no subagent can handle it.
- Never include browser/execute tools in an agent whose only job is coordination.

| Agent Role | Typical Tool Set |
|------------|------------------|
| Orchestrator / pipeline | `[read, search, todo, agent]` |
| Content researcher | `[read, search, web]` |
| File creator / editor | `[read, search, edit]` |
| Full content specialist | `[read, search, edit, execute, web, todo, agent]` |

## Required Sections

Every `.agent.md` body must include these sections in order:

1. **Role Statement** — one short paragraph starting `You are the **<Agent Name>**,` describing a single focused purpose.
2. **Constraints** — explicit `DO NOT` / `ONLY` bullets: what's out of scope, whether it delegates or acts directly, and the publish gate (never push without running publish-session).
3. **Workflow or Pipeline** — numbered steps; each names the subagent or skill invoked, not just the action.
4. **Output Format** — exactly what the agent returns. Orchestrators end with a summary table (before/after counts, commit SHA or "not published").

## Delegation Pattern

Orchestrator agents **must not** research, write, or publish content directly. They queue work and invoke the **curator** agent for content operations and **publish-session** for commits.

```
# Correct
Invoke the **curator** subagent with: "Add topic: <name>, category: <slug>"

# Incorrect
Fetch a source and write the file directly.
```

## Scope Constraint

Every agent operates within `concept.scope` from [seed.md](../../seed.md). Any agent that accepts user input must validate that the requested topic connects to the concept before proceeding. If it cannot be confirmed in-scope, skip it and note the reason in the summary.

## Naming and Location

- File: `.github/agents/<role>.agent.md` (kebab-case, descriptive noun; concept-agnostic).
- `name:` frontmatter: Title Case, short (≤ 4 words).
- `description:` must follow the "Use when: ..." pattern with specific trigger phrases.
- `argument-hint:` should state expected input format with one concrete example.

## Example Frontmatter

```yaml
---
name: "<Role>"
description: "Use when: <specific trigger phrases>; <another trigger>; <when NOT to use>."
tools: [read, search, todo, agent]
argument-hint: "Topic name or category slug. Leave blank to auto-detect."
---
```
