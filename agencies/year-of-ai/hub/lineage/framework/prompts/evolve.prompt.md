---
name: Evolve Customizations
description: "Audit and improve this repository's AI customization layer. Use when: reviewing agents, instructions, skills, or prompts for gaps or weaknesses; proposing the next iteration of the customization ecosystem; checking that agent descriptions are discoverable, tool sets are minimal, delegation chains are correct, and nothing hardcodes the concept instead of reading it from seed.md."
argument-hint: "Optional: scope to audit (e.g. 'agents', 'instructions', 'skills', 'prompts'). Leave blank to audit all layers."
agent: agent
tools: [read, search, edit, todo]
---

Audit the current AI customization layer of this repository and implement the highest-impact improvements. First read the **Concept Definition** in [seed.md](../../seed.md) — the layer must remain concept-agnostic (reading the concept from seed.md), never hardcoding a specific subject.

## Instructions

### 1. Inventory

Read every file in `.github/agents/`, `.github/instructions/`, `.github/skills/`, and `.github/prompts/`. If the user specified a scope, read only that folder. Build a list of all customization files with their name, type, and `description` field.

### 2. Evaluate Each File

Score each file against these criteria:

| Check | Pass Condition |
|-------|---------------|
| **Discoverable description** | Contains "Use when:" with specific trigger phrases; no vague "helpful agent" language |
| **Minimal tools** | Agents/prompts only include tools actually needed for their role |
| **Delegation correct** | Orchestrators delegate content work; content agents don't orchestrate |
| **Required sections present** | Agents have: role statement, Constraints (DO NOT/ONLY), Workflow/Pipeline, Output Format |
| **No scope creep** | Agent/prompt does one job; does not bleed into unrelated tasks |
| **Concept-agnostic** | No hardcoded subject (e.g. a specific year/category); reads the concept from seed.md |
| **Frontmatter complete** | `description`, `name`, `argument-hint` (if user-facing), `tools` (if restricted) |

Mark each file as **Pass**, **Warn** (minor gap), or **Fail** (broken or missing required element).

### 3. Rank Improvements

Collect all Warn and Fail items. Rank by impact:
1. Broken delegation chains (Fail) — fix first
2. Undiscoverable descriptions (Fail) — fix second
3. Missing required sections (Warn)
4. Over-tooled agents (Warn)
5. Missing files for documented workflows referenced in instructions but not yet created

### 4. Implement Top Improvements

Fix all Fail items and the top 3 Warn items (unless the user specified fewer). For each fix:
- Edit the file in place — do not create new files unless a referenced file is entirely missing.
- Apply [agent conventions](../instructions/agents.instructions.md) for any agent edits.
- Apply [content standards](../instructions/content.instructions.md) for any markdown edits.
