---
name: add-topic
description: 'Add one or more topics to this knowledge-base repository. Use when: adding a new item (event, person, work, discovery, etc.) within the repo concept; unsure whether a topic deserves a knowledge-table row or a full dedicated article; bulk-adding multiple topics at once; auto-discovering coverage gaps across the concept''s categories. Concept-agnostic — reads subject/taxonomy from seed.md. Orchestrates research, format selection, file creation, README linking, and session logging.'
argument-hint: 'Topic name or comma-separated list. Leave blank to auto-discover coverage gaps.'
---

# Add Topic

## What This Skill Does

Given one or more topics within the repository's concept, this skill:
1. Researches each topic using authoritative sources
2. Decides the output format (table row vs. dedicated file)
3. Creates or updates the correct files
4. Links everything from the README knowledge table
5. Optionally logs the session to `seed.md`

Always read the **Concept Definition** in [seed.md](../../../seed.md) first for `subject`, `scope`, `taxonomy`, and `conventions`.

---

## Procedure

### Step 1 — Determine Topics

**If topics were provided**, use them (split on commas).

**If no argument was given**, auto-discover gaps:
- Read [README.md](../../../README.md) and count rows per category from `concept.taxonomy`.
- Identify under-represented categories (fewer than 3 entries).
- Propose 1–2 well-known in-scope topics per under-represented category.
- Proceed with all if running non-interactively; otherwise confirm first.

### Step 2 — Research Each Topic

For each topic, follow the full [research](../research/SKILL.md) procedure: fetch ≥2 authoritative sources, extract identifier/people/what/significance/category, and confirm it falls within `concept.scope`. Skip and note any topic that can't be confirmed in-scope.

### Step 3 — Choose Output Format

| Condition | Format |
|-----------|--------|
| Sparse (1–3 facts, minor item) | **Table row only** → Step 4a |
| Rich (4+ facts, notable significance) | **Dedicated file + table row** → Step 4b |
| Already has a dedicated file | **Update existing file**; ensure README links it |

When in doubt, prefer the dedicated file.

### Step 4a — Add a Knowledge-Table Row

Open [README.md](../../../README.md) and add a row under the heading named by `concept.conventions.knowledge_table` (read from [seed.md](../../../seed.md)):
`| Item | One-sentence description ending with its significance |`. Do not duplicate existing rows;
preserve all other content.

### Step 4b — Create a Dedicated File + README Link

- **Path** (`concept.conventions.file_path`): `<category-slug>/<topic-slug>.md` (slug = lowercase, hyphens, no special characters).
- **Create the file** using the template in [content.instructions.md](../../instructions/content.instructions.md) (frontmatter `title`, `date`, `category`; sections Summary, Significance, Sources).
- **Link from README**: turn the item's table cell into a link
  `| [Item](<slug>/<topic-slug>.md) | ... |`.

### Step 5 — Report

Output a summary table:

| Topic | Format | File | Status |
|-------|--------|------|--------|
| ...   | ...    | ...  | Created / Updated / Skipped (reason) |

### Step 6 — Log to Seed (Optional)

If asked to record the session, follow the [encode-seed](../../prompts/encode-seed.prompt.md) prompt to append an entry to the seed Evolution Log.
