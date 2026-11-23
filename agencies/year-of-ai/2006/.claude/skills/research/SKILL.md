---
name: research
description: "Research a topic within this repository's concept and return structured findings. Use when looking up items (events, people, works, discoveries) within the concept, crawling authoritative sources, verifying facts, or gathering facts before deciding on a knowledge-table row vs. a dedicated file. Reads subject/scope/source_strategy from seed.md. Does NOT write files — use add-topic for that."
---

# Research (Claude Code adapter)

Canonical procedure: **`.github/skills/research/SKILL.md`** (shared with the Copilot / VS Code layer). Read that file and follow it exactly.

Summary:
1. Read the **Concept Definition** in `seed.md` — `subject`, `scope`, `source_strategy`, `taxonomy`. All research is bounded by these.
2. Per `concept.source_strategy`, gather **≥2 authoritative sources** (one encyclopedic such as Wikipedia/Britannica; one specialist where possible).
3. Extract: **Identifier** (exact date/value anchoring it to the subject), **People**, **What**, **Significance**, **Category** (matching `concept.taxonomy` slug).
4. Return structured markdown — a knowledge-table row and/or dedicated-file body per `.github/instructions/content.instructions.md`. **Do not write repository files**; hand findings back to the caller (e.g. the add-topic skill).
5. Confirm the topic is within `concept.scope`; cite both sources on any conflict; ensure sources are publicly accessible.
