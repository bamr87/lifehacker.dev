---
name: add-topic
description: "Add one or more topics to this knowledge-base repository. Use when adding a new item (event, person, work, discovery) within the repo concept, unsure whether a topic deserves a table row or a full article, bulk-adding multiple topics, or auto-discovering coverage gaps across categories. Reads subject/taxonomy from seed.md. Orchestrates research, format selection, file creation, and README linking."
---

# Add Topic (Claude Code adapter)

Canonical procedure: **`.github/skills/add-topic/SKILL.md`**. Read that file and follow it exactly. Always read the **Concept Definition** in `seed.md` first (`subject`, `scope`, `taxonomy`, `conventions`).

Summary:
1. **Determine topics** — use the provided list (split on commas); if none, auto-discover gaps (count README rows per `concept.taxonomy` category; propose 1–2 in-scope topics per under-represented category, fewer than 3 entries).
2. **Research each topic** via the **research** skill (≥2 authoritative sources; confirm in-scope; skip + note anything that isn't).
3. **Choose format** — table row only (1–3 facts / minor) vs. article post + row (4+ facts / notable); when in doubt prefer the post.
4. **Create/update files** — table row in `README.md` under the heading named by `concept.conventions.knowledge_table` (read from `seed.md`), and/or a post at `_posts/<section-slug>/<YYYY-MM-DD>-<topic-slug>.md` with `title`/`date`/`categories`/`tags`/`excerpt`/`preview` front matter per `.github/instructions/content.instructions.md`. A post's **tags** are its section's sub-topics — reuse the section's existing tag vocabulary. Never duplicate rows; preserve existing content.
5. **Link** the post from the README row via its permalink (`{{ '/news/<section-slug>/<topic-slug>/' | relative_url }}`); **report** a summary table (Topic | Format | File | Status).
6. Optionally log the session to the seed Evolution Log via `/encode-seed`.
