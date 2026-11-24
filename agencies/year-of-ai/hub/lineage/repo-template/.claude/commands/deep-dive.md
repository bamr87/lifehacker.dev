---
description: "Research one topic within the repo concept in depth and create a dedicated markdown file (frontmatter, Summary, Key Facts, Significance, Sources), then link it from the README."
argument-hint: "<topic> — blank = the most notable table item lacking a dedicated file"
---

Research the given topic in depth and produce a dedicated markdown file for it, bounded by the **Concept Definition** in `seed.md`.

Follow the canonical procedure in `.github/prompts/deep-dive.prompt.md`:

1. Read `concept` from `seed.md`, then follow the **research** skill for all sourcing (≥2 authoritative sources per `concept.source_strategy`).
2. If `$ARGUMENTS` is blank, pick the most notable README table item that lacks a dedicated file.
3. Confirm the topic is within `concept.scope`; extract identifier / people / what / significance / category.
4. Write the file at `<category-slug>/<topic-slug>.md` using the dedicated-file template in `.github/instructions/content.instructions.md` (frontmatter `title`, `date`, `category`; sections Summary, Key Facts, Significance, Sources ≥2).
5. Link the topic's row in the README knowledge table to the new file. Preserve all other content.

Topic: $ARGUMENTS
