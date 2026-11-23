---
description: "Use when adding, editing, or researching content for this knowledge-base repository. Covers content standards, source verification, markdown formatting, the news/section layout (posts, sections, tags-as-subsections), the knowledge-table index, generated artifacts, and which skills/prompts to invoke. Concept-agnostic — reads the subject and taxonomy from seed.md."
applyTo: "**/*.md"
---

# Content & Workflow Standards

This repository grows a knowledge base around a single **concept**, presented in the shared zer0-mistakes theme's **news layout**. Always read the **Concept Definition** block in [seed.md](../../seed.md) first — it defines the `subject`, `scope`, `taxonomy`, `source_strategy`, and `conventions` that every rule below references. Never hardcode a specific subject (e.g. a particular year) into content logic; derive it from the concept.

## The news layout (how content is organised)

The theme renders content as a **newsroom**:

- Each `concept.taxonomy` category is a **news section** published at `/news/<section-slug>/` (the `section` layout). Its directory is `_posts/<section-slug>/`.
- Each article is a **post** at `_posts/<section-slug>/<YYYY-MM-DD>-<topic-slug>.md` (the `article` layout, set by a `_config.yml` posts default).
- A post's **`tags` are the finer sub-topics within its section.** The theme turns them into the section's collapsible "Topics" sidebar and filter pills, and into each article's automatic "Related Posts" block. Tags are the "topics as subsections" — choose a small, **reused** vocabulary per section (e.g. `elections`, `middle east`, `terrorism`) so each tag groups several posts, not one.
- `/news/` is the magazine landing (the `news` layout); it is the site homepage.

Converting a legacy flat repo (`<section>/<topic>.md` at the root) to this layout is a one-time job for the hub tool `scripts/migrate-to-news-structure.rb`; new content is authored directly in the layout below.

## Sections (categories)

All content belongs to exactly one section from `concept.taxonomy` in [seed.md](../../seed.md). Each taxonomy entry has a `name` (e.g. `History & Politics`) and a `slug` (e.g. `history-politics`, used for the `_posts/<slug>/` directory, the `/news/<slug>/` URL, and the tag on the section index).

## Source Standards

- Follow `concept.source_strategy`: verify every fact against **at least two authoritative sources** (one encyclopedic such as Wikipedia/Britannica; one specialist where possible).
- The specialist source must itself be authoritative: official/institutional publications (press releases, government or scientific bodies, court/SEC filings), established news organizations, or academic work. Fan sites, hobbyist blogs, and content farms do **not** count toward the two-source minimum (cite them only as a supplementary third link, if at all).
- Confirm the topic falls **within `concept.scope`**. Reject or note topics outside it.
- Prefer primary-era / authoritative sources when available.

## Articles (posts)

Create an article whenever research yields **4+ distinct facts** or the topic has notable significance (thin items may stay a knowledge-table row only — see below).

- **Path** (`concept.conventions.file_path`): `_posts/<section-slug>/<YYYY-MM-DD>-<topic-slug>.md` (slug = lowercase, hyphens, no special characters; date = the topic's single ISO date).
- **Required front matter** (`concept.conventions.frontmatter`) and structure:

```markdown
---
title: "<Topic Title>"
date: <YYYY-MM-DD>                 # a single plain ISO date, never a range/prose
categories:
  - <Section Name>                # exact taxonomy name, e.g. History & Politics
tags:                             # 2–4 reused section sub-topics — the "subsections"
  - <sub-topic>
  - <sub-topic>
excerpt: "<one-sentence card/description summary>"
preview: /images/previews/<section-slug>.svg
# featured: true                  # optional — one marquee post per section
---

**Key figures**: <names, or "N/A">

## Summary

<2–3 paragraph overview>

## Significance

<why this matters>

## Sources

- [<Source Title>](<URL>)
- [<Second Source>](<URL>)
```

- **No body `# Title` H1** and **no `**Category**:` line** — the `article` layout renders the title and category badge. Do **not** hand-write a `## Related` section; the layout generates related posts from shared `tags`.
- **Cross-links** to other articles use their permalink via Liquid, e.g.
  `[Angela Merkel]({{ '/news/history-politics/angela-merkel-chancellor/' | relative_url }})`.

## Knowledge Table (README index)

- README.md is the browsable **knowledge index** (published at `/knowledge-index/`), not the homepage. It carries the table under the `## Notable Events` heading (or the heading named in `concept.conventions.knowledge_table`).
- Row format: `| <Item> | One-sentence description ending with its significance |`
- Never duplicate an existing row. Keep descriptions factual, neutral, and under 25 words.
- When an article exists for the item, link it to its permalink:
  `| [Item]({{ '/news/<section-slug>/<topic-slug>/' | relative_url }}) | ... |`

## Generated Artifacts (do not hand-edit)

Agent-maintained and regenerated by skills — do not edit by hand (they will be overwritten):
- `seed.md` sections 1–7 (the DNA) — maintained by **sync-seed** (only the Evolution Log is hand/append).
- `ROADMAP.md` — maintained by **plan-roadmap**.
- Section index pages (`_posts/<slug>/<year>-01-01-index.md`, `layout: section`), the `/news/` landing, `_data/navigation/posts.yml` + `main.yml`, the `assets/images/previews/*.svg` placeholders, and the `TIMELINE.md`/`INDEX` — maintained by **build-structure**.

## Agent Workflow

- **Add a new topic** → **add-topic** skill (research → format → create post + tags → link → optional log).
- **Research only** → **research** skill (structured facts; writes nothing).
- **(Re)build sections/landing/nav** → **build-structure** skill.
- **Convert a legacy flat repo to the news layout** → hub `scripts/migrate-to-news-structure.rb`.
- **Long-form article** → **deep-dive** prompt (`/deep-dive`).
- **One autonomous growth tick** → **grow** prompt (`/grow`).
- **Bootstrap a fresh repo for any concept** → **genesis** prompt (`/genesis "<concept>"`).
- **Log a session** → **encode-seed** prompt (`/encode-seed`) — appends to the seed Evolution Log.

## Content Tone & Style

- Write in clear, formal, encyclopedic prose. Active voice; present tense for descriptions, past tense for narrative.
- Avoid editorializing. State facts and significance without personal opinion.
- Match the tone declared in `concept.conventions.tone`.
