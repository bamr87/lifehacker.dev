---
name: research
description: 'Research a topic within this repository''s concept and return structured findings. Use when: looking up items (events, people, works, discoveries, etc.) within the concept; crawling authoritative sources; verifying facts and attribution; gathering facts before deciding whether to create a knowledge-table row or a dedicated file. Concept-agnostic — reads subject/scope/source_strategy from seed.md. Does NOT write files on its own — use add-topic for that.'
argument-hint: 'A topic within the repo concept (e.g. an event, person, work, or discovery).'
---

# Research

## What This Skill Does

Given a topic within the repository's concept, this skill:
1. Reads the **Concept Definition** in [seed.md](../../../seed.md) to learn the `subject`, `scope`, and `source_strategy`.
2. Fetches content from authoritative web sources.
3. Extracts key facts: identifying detail, people, context, significance, category.
4. Returns structured findings (it does not write repository files).

---

## Procedure

### Step 1 — Load the Concept

Read `concept` from [seed.md](../../../seed.md). Note `subject`, `scope`, `source_strategy`, and the `taxonomy` categories. All research is bounded by these.

### Step 2 — Identify Sources

Per `concept.source_strategy`, gather **at least two authoritative sources** (one encyclopedic such as Wikipedia/Britannica; one specialist where possible). Use a web search/fetch with a query like `"<topic> <subject> significance"`.

### Step 3 — Extract Key Facts

Capture:
- **Identifier**: exact date, value, or detail anchoring the item to the `subject`.
- **People**: key figures (name, role).
- **What**: the event, work, or development.
- **Significance**: why it matters.
- **Category**: the matching slug from `concept.taxonomy`.

### Step 4 — Format Output

Return structured markdown — a knowledge-table row and/or the body of a dedicated file per [content.instructions.md](../../instructions/content.instructions.md). Do **not** write files; hand findings back to the caller (e.g. the add-topic skill).

### Step 5 — Verify

- Confirm the topic falls within `concept.scope`.
- Note any source conflicts and cite both.
- Ensure sources are publicly accessible (no paywalled URLs).

---

## Notes

- If a topic only partially relates to the concept, focus on the in-scope portion.
- Prefer an encyclopedic source as the primary crawl target; cross-check with a specialist source.
