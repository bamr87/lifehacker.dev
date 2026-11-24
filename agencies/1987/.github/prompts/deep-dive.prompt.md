---
name: Deep Dive a Topic
description: "Research a single topic within the repo concept in depth and create a dedicated markdown file for it. Use when: exploring a specific item (event, person, work, discovery) in detail; creating a standalone article beyond a knowledge-table row; building out the category folders. Concept-agnostic — reads subject/taxonomy from seed.md. Do NOT use for bulk-adding (use add-topic) or quick table-only additions (use update-readme)."
argument-hint: "A topic within the repo concept to explore in depth. Leave blank to pick the most notable table item lacking a dedicated file."
agent: agent
tools: [read, edit, web]
---

Research the provided topic in depth and produce a dedicated markdown file for it, per the repo's **Concept Definition** in [seed.md](../../seed.md).

## Instructions

### 1. Load the concept and research skill
Read `concept` from [seed.md](../../seed.md) (subject, scope, taxonomy, conventions), then read and follow [research](../skills/research/SKILL.md) for all research steps.

### 2. Determine the topic
- Use the argument if provided.
- Otherwise, read [README.md](../../README.md) and pick the most notable table item that does not yet have a dedicated file.

### 3. Research the topic
Execute the full `research` procedure: fetch ≥2 authoritative sources per `concept.source_strategy`, extract identifier/people/what/significance/category, and confirm the topic falls within `concept.scope`.

### 4. Determine the file path
Map the topic's category to its `slug` from `concept.taxonomy`, then build `concept.conventions.file_path` → `<category-slug>/<topic-slug>.md` (slug = lowercase, hyphens, no special characters).

### 5. Create the topic file
Use the dedicated-file template in [content.instructions.md](../instructions/content.instructions.md): frontmatter (`title`, `date`, `category`) followed by `# Title`, key figures, `## Summary`, `## Key Facts`, `## Significance`, `## Sources` (≥2).

### 6. Link from the README
Open [README.md](../../README.md), find or add the topic's row in the table headed by `concept.conventions.knowledge_table` (read from seed.md), and turn the item cell into a link to the new file. Preserve all other content exactly.

### 7. Report
Summarize: the file created (path), top 3 facts found, and whether a README link was added/updated.
