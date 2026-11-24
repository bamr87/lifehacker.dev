<!-- kit: governance v0.1.0 -->
# 0004 — Agencies

- **Status:** proposed
- **Date:** 2026-11-22
- **Proposed by:** Claude Code (agent), on the maintainer's direction of 2026-11-22
- **Ratified by:**
- **Affects:** constitution § 9 (new); PRD FR6 and NFR5; feature LHD-009
- **Supersedes:** none
- **Related:** [ADR 0002](../adr/0002-agencies.md); zer0-CMS ADR 0012; [hub constitution § 23.6](https://github.com/bamr87/bamr87/blob/main/docs/constitution.md#23-writing-section-chronicles-fleet-activity)

## Context

The maintainer directed that the content sites held in zer0-CMS, and the Year of AI and AI World View networks, move into lifehacker.dev as sub-agencies, so that lifehacker.dev is the content source and zer0-CMS is the platform. The constitution describes one site and its news sections; it has no rule for a repository that also holds other sites' content, who writes each one, or what keeps that content off the apex domain. [ADR 0002](../adr/0002-agencies.md) records the technical decision. This amendment adds the rules that must keep holding after it, so they outrank a later change to a script or a workflow.

It does not change § 1. The three missions are the maintainer's wording, adopted by amendment 0003, and whether the direction statement should now name the agencies is left to the maintainer.

## Amendment

Add a new section after § 8:

## 9. Agencies

_(amendment 0004)_

1. **lifehacker.dev is the content source; zer0-CMS is the platform.** This repository holds the content of its sub-agencies. zer0-CMS manages, renders and publishes it. Neither keeps a second copy of the other's part.
2. **An agency is a registered, self-contained tree.** Every agency site lives under `agencies/`, is listed in `_data/agencies.yml` with its source and its custody, and arrives or is refreshed only through `scripts/agencies/import.rb`.
3. **One write side per site.** A site's custody is `home` (written here and nowhere else) or `mirror` (written at its source and refreshed here), never both.
4. **Nothing under `agencies/` reaches the apex domain unreviewed.** `agencies` stays in `_config.yml` `exclude:`. Publishing an agency from this repository is its own change, with an ADR, merged by the maintainer.
5. **The same merge gate, a voice of its own.** § 2 applies to every file under `agencies/`: no push to `main`, no secrets, a human merge. The apex site's brand and front-matter gates apply to `pages/` only; an agency keeps its own voice, and its own guide governs its tree.

## Consequences

Agents treat `agencies/` as other sites' content held in custody, not as pages of lifehacker.dev: they register before importing, never edit a mirror, and never remove the build exclude. `scripts/ci/lint_agencies.rb` enforces rules 2 and 4 in the harness; rules 1, 3 and 5 are review rules. The PRD gains FR6 and NFR5, and the feature catalog gains LHD-009. Merging the pull request that carries this record ratifies it. Until then the record stays `Status: proposed`.
