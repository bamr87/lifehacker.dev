# ADR 0002 — lifehacker.dev holds its sub-agencies' site trees; zer0-CMS is the platform

- **Status**: proposed
- **Date**: 2026-11-22
- **Deciders**: the maintainer (direction of 2026-11-22); recorded by Claude Code
- **Related**: [amendment 0004](../amendments/0004-agencies.md) (constitution § 9); feature LHD-009; PRD FR6 and NFR5; zer0-CMS ADR 0012 (the companion change); [hub constitution § 23.6](https://github.com/bamr87/bamr87/blob/main/docs/constitution.md#23-writing-section-chronicles-fleet-activity)

## Context

The maintainer's direction, in their words: "review the site directory in zer0-cms, and consolidate/migrate all the content into lifehacker.dev as different sub-agencies. the goal is to transform lifehacker as the content source, and zer0-CMS is the platform. year-of-ai and ai-world-view should also be under lifehacker. the zer0 demosites should stay in zer0-cms."

Before this change the fleet's content sat in three kinds of place. zer0-CMS held nine sites under `sites/`: five bodies of content (1987, 2005, drsai, irony-works, wargames) and four demonstrations of the platform itself. The Year of AI and AI World View networks lived in their own GitHub organizations, as 19 repositories: a hub and one repository per year or country. lifehacker.dev held only its own news sections. The hub constitution already names lifehacker.dev the fleet's news agency, and this repository's own automation was shut down on 2026-11-05 in favour of the central zer0-CMS system, so the two roles the maintainer describes were half in place: a platform that held content, and a content source that held one site.

Two facts shaped the mechanics. Production here is GitHub's own Pages build of the whole repository, while the CI build overlays only `pages/`, `_data/`, `_includes/` and `assets/` onto a theme clone, so a new top-level directory is built in production and invisible to CI unless it is excluded. And on the import date the documented public URLs of 1987, drsai, irony-works and wargames returned 404, while both network hubs and all 17 member sites answered: four of the sites had no public home to break, and 19 had one that must not be broken. The same four had lost more than their public home: the repositories they first lived in (`bamr87/1987`, `bamr87/drsai`, `bamr87/irony-works`, `bamr87/wargames`) no longer exist, so zer0-CMS's `main` held the only copy of each.

## Decision

1. **An agency is a registered, self-contained tree.** Each sub-agency is a directory under `agencies/` holding one site (`agencies/<agency>/`) or, for a network, a hub and its members (`agencies/<agency>/<site>/`). [`_data/agencies.yml`](../../_data/agencies.yml) is the registry of record: every agency's name, beat and kind, and every site's path, custody, public URL and source. [`scripts/ci/lint_agencies.rb`](../../scripts/ci/lint_agencies.rb) fails the harness when the registry and the trees disagree.
2. **Trees are imported whole, by one tool.** [`scripts/agencies/import.rb`](../../scripts/agencies/import.rb) exports the tracked files of one source commit — content, site configuration and the site's own tooling — and writes the commit, date, file count and tree digest into the registry. Two differences from the source are allowed and recorded per site: a file this repository's ignore rules refuse is dropped, and Markdown is held to one paragraph per line by the repair the gate already uses. Nothing is copied in by hand.
3. **One write side per site.** `custody: home` marks a tree that is written here and nowhere else: the five from zer0-CMS, which the companion change removes there. `custody: mirror` marks a tree whose source is still written — the 18 that still grow in the two organizations — and which is refreshed here, never edited.
4. **Nothing under `agencies/` is part of the apex site.** `agencies` is in `_config.yml` `exclude:`, and the lint fails if that line goes missing. Publishing an agency from this repository is a separate, reviewed change with its own ADR.
5. **Gates.** The human merge gate, the secret rule and one paragraph per line apply to agencies as to everything else. The apex site's brand, front-matter, preview and wire gates stay scoped to `pages/`: an agency keeps its own voice, and its own `AGENTS.md` governs its tree.
6. **zer0-CMS is the platform.** It registers each site by its path in a checkout of this repository, imports and round-trips it, and renders and publishes it as its own jobs. Its ADR 0012 removes the five trees from its monorepo, records what each still owes in its capability ledger, and turns its importer's round-trip corpus for those sites into a contract test against `agencies/`. The four demonstration sites stay there.

## Consequences

**Positive**

- One repository holds the fleet's content, with a written answer for every tree to "where did this come from and who writes it".
- The platform and the content have one boundary instead of a shared directory: zer0-CMS no longer builds or gates content it does not own, and content changes no longer run the platform's CI.
- The five trees whose only maintained copy was inside the platform's monorepo now sit where content is reviewed.

**Negative**

- The repository grows by 3,764 files (about 55 MB), and a pull request that touches only `agencies/` runs the full pipeline until the change classifier learns the directory.
- A mirror drifts from its source between refreshes. The registry says which commit each copy holds, and `import.rb --verify` answers whether it still matches, but nothing refreshes a mirror on a schedule.
- Each tree brings machinery that is inert here: 48 workflow files under nested `.github/workflows/`, and each tree's `.claude/` commands and guides, which load only when someone works inside that tree.
- The builds zer0-CMS recorded for 2005 and wargames were made from the bytes before the prose reflow, which changed two and five of their Markdown files. Whoever publishes those sites next re-records them.
- Nothing publishes an agency from here yet, so the four sites without a public URL stay unpublished until the next decision.
- The trees from zer0-CMS were moved unedited, so their guides still name its build tool by a relative path that does not resolve here, and 1987 has no `_config.yml` for the platform to register. Nothing can build those four from this repository until the platform builds an external checkout or the guides are corrected.
- The order of the two merges is a safety rule. Until this import is on `main`, zer0-CMS's `main` is the only place four of the trees exist; its companion change must not merge first.

## Alternatives considered

- **Fold each agency into this site's one Jekyll build, as sections.** Not chosen now: it means rewriting every agency page to this site's front matter and gates, and the agencies have their own voices and structures. It stays possible per agency later, through the content-import flow, and needs the content here first either way.
- **Keep the sites as separate repositories, joined as submodules.** Not chosen: it consolidates nothing, and the content would still be written and reviewed in every one of its source repositories.
- **Carry git history across.** Not chosen: zer0-CMS's `main` holds each of its trees as one squashed commit already, so there is little to carry; four of the five original repositories no longer exist; the two networks' repositories keep their own history for as long as they are the write side; and the registry pins the exact commit each tree came from.
- **Move content only, and leave each site's tooling in zer0-CMS.** Not chosen: the tools resolve paths relative to their own tree, so splitting them breaks them, and the platform's ledger already tracks what it must absorb from each one.

## Left to the maintainer

- Where and how agencies are published (their URLs, and whether this repository moves from the native Pages build to a workflow that builds each tree). Settled since by [ADR 0003](0003-agencies-as-collections.md): as collections of this site, under their own paths.
- When each mirror's write side moves here, and what happens to the two organizations' repositories and growth engines when it does.
- The hub's registry rows and submodules for the two network hubs.

## Supersedes / Superseded by

- Supersedes: none
- Superseded by: none
