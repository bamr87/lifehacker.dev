# ADR 0003 — An agency is published as a collection of this site, under its own path; Wargames is the first

- **Status**: accepted
- **Date**: 2026-11-23 (accepted 2026-11-24, [#829](https://github.com/bamr87/lifehacker.dev/pull/829))
- **Deciders**: the maintainer (direction of 2026-11-22 and go-ahead of 2026-11-23); recorded by Claude Code
- **Related**: [ADR 0002](0002-agencies.md) (the trees and their custody); [constitution § 9](../constitution.md#9-agencies) rule 4; features LHD-009 and LHD-010; PRD FR6, FR7 and NFR5

## Context

[ADR 0002](0002-agencies.md) brought the sub-agencies' site trees into `agencies/`, held and deliberately unpublished, and left "where and how agencies are published" to the maintainer. Their answer: lifehacker.dev absorbs the content, each agency as a sub-agency of this site — "maybe as different collections? or sub-domains? or news section? what makes the most logical sense?"

The content decided it. Every one of the 18 Jekyll site roots among the trees already renders with the theme this site uses, so its pages need no new layouts here. The news sections could not hold them: Year of AI alone has 1,054 articles dated inside the years they describe (1776 to 2014) against this site's 327 posts, 1,039 of them pin permalinks under `/news/…`, which is this site's own section namespace, and the news gate requires a persona byline, an excerpt and one of four section categories that none of them has. Sub-domains would undo the consolidation: GitHub Pages serves one site and one custom domain per repository, so each sub-domain needs its own repository or another host.

Wargames went first because it risks least and fits best: 219 pages of security practice with uniform front matter, relative links between levels, no public URL to break (its old site returns 404), and the only agency squarely inside this site's stated mission.

## Decision

1. **A published agency is a Jekyll collection of this site.** Its pages live in `pages/_<name>/` and are served under `/<name>/`. The collection is declared in `_config.yml` (`collections:`) with a `defaults:` scope that sets its layout, banner, sidebar and an `agency:` key naming its row in the registry.
2. **Promotion is one tool, run once, for a site written here.** [`scripts/agencies/promote.rb`](../../scripts/agencies/promote.rb) moves the pages out of the tree with `git mv`, rewrites the URL base they carried and their byline keys, moves their images to `assets/images/<name>/`, and writes a `published:` block on the site's registry row. It refuses a `mirror`: publishing a copy of a site that is still written elsewhere would put the same pages on two sites.
3. **Pages pin their permalinks, and an index page must.** Jekyll has no special case for a collection's `index.md` (it would land at `/<name>/<dir>/index/`), so the collection's `permalink:` pattern is only the default for a page that pins nothing.
4. **An agency is not news.** Its pages are not in the `posts` collection, the feed or the news landings. The front door is the [`/agencies/`](../../pages/agencies.md) index, a navbar entry and a section of the sitemap, all driven by the registry; a news post may point into an agency like any other link.
5. **A lenient gate, read from the registry.** `lint_frontmatter.rb` holds every published collection to what `docs` is held to (a title, a description, a known byline, no future date), through its nested directories. `check_drift.rb` knows its URLs. `lint_agencies.rb` fails when a published site's collection is missing, undeclared or published from a mirror. The brand, preview and wire gates stay scoped to the news: an agency keeps its own voice ([constitution § 9](../constitution.md#9-agencies) rule 5).
6. **Styles an agency needs go in the theme's opt-in layer, namespaced.** `user_overrides: true` loads `assets/css/user-overrides.css`; every rule there is scoped to a class the agency's pages carry, so no other page changes.
7. **What stays in the tree is its back office.** Guides, licence, tooling and the old site configuration remain under `agencies/<agency>/`, still excluded from the build.

For Wargames: `agencies/wargames/overthewire/` became `pages/_wargames/`; `/docs/wargames/…` became `/wargames/…` (219 pinned permalinks and 4 Liquid links); the byline `bamr87`, which is not an author key here, became `amr`, the same person; 21 images moved to `assets/images/wargames/`; the study guide's styles were carried into the namespaced stylesheet. Nothing else in any page changed.

## Consequences

**Positive**

- One site, one build, one navigation and one search: a reader reaches an agency from the masthead, and the agency's pages inherit the theme, the skin and every fix to them.
- The pattern is data: the next agency is a registry row, a `collections:` entry and a `defaults:` scope. The gates, the sitemap and the agencies index pick it up without a code change.
- The news stays the news. Nothing an agency files can swamp the feed or the section landings.

**Negative**

- The site grows from 434 built pages to 654, and the Jekyll build from about 44 seconds to between 70 and 76 seconds over three runs in the same container. The native Pages build has a 10-minute limit; the larger agencies (Year of AI has about 1,100 articles) must be measured before they are promoted, and may force a move to a workflow build.
- `user_overrides: true` makes every page of the site request one more stylesheet and one more script. The script is empty and exists only because the theme's switch loads both.
- A refresh of Wargames from OverTheWire is still a person's procedure, run from the back office (`agencies/wargames/scripts/docs-aggregator/`, then `tools/carry-study-guides.py`). The tool was changed with the move so that a refresh keeps the new URLs and produces links this site's check accepts; a dry run on 2026-11-24 reproduced all 219 permalinks. It also showed three pages changed upstream since the last refresh, which this change does not apply.
- The old Wargames home page (a hero and a card grid per tier, with its own styles and `_data/games.yml`) was not carried: `/wargames/` is the map of games that was `/docs/wargames/`. It stays in the back office.
- Bylines are carried as the source had them. The study guides on each level page are filed under the founder's byline here, as they were there.
- Only Wargames sits inside "practical technology" as [constitution § 1](../constitution.md#1-missions) states it. Promoting the others broadens what this site is for, which is the maintainer's to say.

## Alternatives considered

- **A news section per agency.** Not chosen: see Context. The dates, the permalinks, the gate and the volume all say an archive is not news.
- **Sub-domains.** Not chosen: one Pages site per repository means a repository or a host per agency, which is the arrangement the move set out to end.
- **Each tree built as its own site and composed under sub-paths by a workflow.** Not chosen: it keeps every tree's own configuration and URL scheme with no rewriting, but it leaves the native Pages build, runs one Jekyll build per tree, and gives the agencies no shared navigation or search with the site they are meant to be part of. It remains the fallback if one build cannot hold the larger agencies.

## Left to the maintainer

- The order and timing of the other agencies, each mirror only after its write side moves here and its old URLs redirect.
- Whether drsai (children's picture books) belongs under this masthead.
- Whether constitution § 1 should name the agencies.

## Supersedes / Superseded by

- Supersedes: none (it settles the publishing question [ADR 0002](0002-agencies.md) left open)
- Superseded by: none
