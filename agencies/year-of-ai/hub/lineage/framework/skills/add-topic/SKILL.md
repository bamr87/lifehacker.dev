---
name: add-topic
description: 'Add one or more topics to this knowledge-base repository. Use when: adding a new item (event, person, work, discovery, etc.) within the repo concept; unsure whether a topic deserves a knowledge-table row or a full article post; bulk-adding multiple topics at once; auto-discovering coverage gaps across the concept''s sections. Concept-agnostic — reads subject/taxonomy from seed.md. Orchestrates research, format selection, post creation, README linking, and session logging.'
argument-hint: 'Topic name or comma-separated list. Leave blank to auto-discover coverage gaps.'
---

# Add Topic

## What This Skill Does

Given one or more topics within the repository's concept, this skill:
1. Researches each topic using authoritative sources
2. Decides the output format (table row vs. article post)
3. Creates or updates the correct files in the theme's news layout
4. Links everything from the README knowledge table
5. Optionally logs the session to `seed.md`

Always read the **Concept Definition** in [seed.md](../../../seed.md) first for `subject`, `scope`, `taxonomy`, and `conventions`, and the news-layout rules in [content.instructions.md](../../instructions/content.instructions.md). Each `taxonomy` category is a **news section** (`_posts/<section-slug>/`, published at `/news/<section-slug>/`); a post's **`tags` are its section sub-topics**.

---

## Procedure

### Step 1 — Determine Topics

**If topics were provided**, use them (split on commas).

**If no argument was given**, auto-discover gaps:
- Read [README.md](../../../README.md) and count rows per section from `concept.taxonomy`.
- Identify under-represented sections (fewer than 3 entries).
- Propose 1–2 well-known in-scope topics per under-represented section.
- Proceed with all if running non-interactively; otherwise confirm first.

### Step 2 — Research Each Topic

For each topic, follow the full [research](../research/SKILL.md) procedure: fetch ≥2 authoritative sources, extract identifier/people/what/significance/section, and confirm it falls within `concept.scope`. Skip and note any topic that can't be confirmed in-scope.

### Step 3 — Choose Output Format

| Condition | Format |
|-----------|--------|
| Sparse (1–3 facts, minor item) | **Table row only** → Step 4a |
| Rich (4+ facts, notable significance) | **Article post + table row** → Step 4b |
| Already has a post | **Update existing post**; ensure README links it |

When in doubt, prefer the article post.

### Step 4a — Add a Knowledge-Table Row

Open [README.md](../../../README.md) and add a row under the heading named by `concept.conventions.knowledge_table`:
`| Item | One-sentence description ending with its significance |`. Do not duplicate existing rows;
preserve all other content.

### Step 4b — Create an Article Post + README Link

- **Path** (`concept.conventions.file_path`): `_posts/<section-slug>/<YYYY-MM-DD>-<topic-slug>.md` (slug = lowercase, hyphens; date = the topic's single ISO date).
- **Front matter**: `title`, `date` (plain ISO), `categories: [<Section Name>]`, `tags: [<2–4 reused section sub-topics>]`, `excerpt` (one-sentence summary), `preview: /images/previews/<section-slug>.svg` (add `featured: true` only for a section's one marquee post). **Choose tags from the section's existing tag vocabulary** so they group with sibling posts — check the other posts in `_posts/<section-slug>/` first.
- **Body**: no `# Title` H1 and no `**Category**:` line (the layout renders them); sections `## Summary`, `## Significance`, `## Sources`. No hand-written `## Related` (the layout generates related posts from shared tags). See the template in [content.instructions.md](../../instructions/content.instructions.md).
- **Link from README**: make the item's table cell link to the post's permalink:
  `| [Item]({{ '/news/<section-slug>/<topic-slug>/' | relative_url }}) | ... |`.

After adding posts, run [build-structure](../build-structure/SKILL.md) so the section index counts, the `/news/` landing, and the navigation data stay current.

### Step 5 — Report

Output a summary table:

| Topic | Format | File | Status |
|-------|--------|------|--------|
| ...   | ...    | ...  | Created / Updated / Skipped (reason) |

### Step 6 — Log to Seed (Optional)

If asked to record the session, follow the [encode-seed](../../prompts/encode-seed.prompt.md) prompt to append an entry to the seed Evolution Log.
