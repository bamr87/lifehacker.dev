---
name: Update README with Research
description: "Populate or expand this repo's knowledge table by researching topics with the research skill. Use when: adding new items to the Notable Events table; bulk-updating the README from a list of topics; enriching existing entries. Concept-agnostic — reads subject/taxonomy from seed.md."
argument-hint: "Comma-separated topics to research and add. Leave blank to suggest missing topics automatically."
agent: agent
tools: [read, edit, web]
---

Research and update [README.md](../../README.md) using the `research` skill, bounded by the repo's **Concept Definition** in [seed.md](../../seed.md).

## Instructions

1. **Load the concept and skill**: Read `concept` from [seed.md](../../seed.md), then read and follow [research](../skills/research/SKILL.md).

2. **Determine topics**:
   - If topics were provided, use those.
   - Otherwise, read [README.md](../../README.md) and identify gaps — categories from `concept.taxonomy` with fewer than 2 entries, or well-known in-scope items not yet listed.

3. **Research each topic**: Execute the full `research` procedure (≥2 sources per `concept.source_strategy`; confirm the topic is within `concept.scope`).

4. **Update the README**:
   - Add a row to the `## Notable Events` table for each researched topic:
     `| Item | One-sentence description ending with its significance |`
   - Do **not** duplicate existing rows. Preserve all existing content exactly.

5. **Report**: List the topics added and any skipped (e.g., out of scope or source inaccessible).
