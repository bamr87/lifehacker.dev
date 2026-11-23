---
description: "Populate or expand the README knowledge table by researching topics (≥2 sources each) within the repo concept."
argument-hint: "<comma-separated topics> — blank = auto-detect gaps"
---

Research topics and add knowledge-table rows to `README.md`, bounded by the **Concept Definition** in `seed.md`.

Follow the canonical procedure in `.github/prompts/update-readme.prompt.md`:

1. Read `concept` from `seed.md`, then follow the **research** skill.
2. Determine topics: use `$ARGUMENTS` if provided; otherwise identify gaps — `concept.taxonomy` categories with fewer than 2 entries, or well-known in-scope items not yet listed.
3. Research each topic (≥2 authoritative sources; confirm it's within `concept.scope`).
4. Add one row per topic to the `## Notable Events` table: `| Item | one-sentence description under 25 words ending in its significance |`. Do **not** duplicate existing rows; preserve all existing content exactly.
5. Report topics added and any skipped (out of scope / source inaccessible).

Topics: $ARGUMENTS
