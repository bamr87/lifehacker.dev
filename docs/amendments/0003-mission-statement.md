<!-- kit: governance v0.1.0 -->
# 0003 — Missions

- **Status:** proposed
- **Date:** 2026-11-16
- **Proposed by:** Grok Bot (agent), at the maintainer's request
- **Ratified by:**
- **Affects:** constitution §1; PRD §1.1; feature LHD-008
- **Supersedes:** none
- **Related:** [PRD.md](../../PRD.md) §1.1; feature LHD-008

## Context

Constitution §1 Mission was a product description (or, for a new constitution, had not been written yet), not a three-mission direction statement. The fleet now requires every repo's constitution §1 to be one direction statement followed by exactly three numbered missions, adopted through a numbered amendment the maintainer ratifies by merging. The maintainer asked for those missions to be comprehensive and epic: lifehacker.dev as the ultimate open home for all things practical technology. Mission 1 follows the maintainer's wording, adapted to this domain: provide data, tools, resources and transparency for all stakeholders, domain practitioners and the general public. The ambition is the direction, not a claim that the work is already finished. The missions are aligned with this repo's existing constitution and PRD.

## Amendment

Replace constitution §1 with the following, retitled **Missions**:

lifehacker.dev's direction is to become the ultimate open home for all things practical technology — data, tools, resources and transparency, gathered in one place that anyone can inspect and reuse.

1. **Provide data, tools, resources and transparency for all stakeholders, technology practitioners and the general public.** Readers, writers, operators and anyone trying to survive modern tech are first-class audiences. The aim is a shared, inspectable commons: the same hacks, the same tools, and the same trail from draft to published page for everyone.
2. **Publish hacks, tools, field notes and wire posts on a steady cadence, with satire in the framing and never in the facts.** The site stays funny without misleading: comedy is welcome in the voice, and accuracy is required in the content, especially on the wire.
3. **Run as an open, human-gated headless CMS: an autopilot drafts, reviews and ships content, CI enforces quality, and a human remains the only merge gate.** Brand, queues, ledgers and site health live in the repository as data; no change reaches the apex domain lifehacker.dev without a human merge.

These missions set the course; they do not claim the work is finished. They serve the PRD goals: a steady publishing cadence, facts that stay accurate, and quality gates with a human-only merge to main.

_Source: [PRD.md](../PRD.md) §1.1._


## Consequences

Agents and reviewers judge fit against these three missions before inventing scope, treating them as the direction of the repo rather than a description of what already ships. The same text is added as PRD §1.1 so the constitution's `_Source:` line stays accurate. The original PRD purpose / overview paragraph is left in place. This PR also aligns the README and AGENTS.md taglines with the missions and links them to constitution §1, and adds feature LHD-008 to the feature catalog, traced to requirement MR1. Merging this PR ratifies amendment 0003. Until then the record stays `Status: proposed`.
