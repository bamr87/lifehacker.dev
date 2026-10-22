# PRD — lifehacker.dev

> The product requirements for lifehacker.dev — problem, users, goals and non-goals, current features, requirements and proposed success metrics.

Derived from the README, agent docs, config and code in [`bamr87/lifehacker.dev`](https://github.com/bamr87/lifehacker.dev). Anything not stated in those sources is marked **TBD**; success metrics are proposals.

## 1. Overview / problem

A satirical-but-working Jekyll site ("Surviving life, one byte at a time") served by GitHub Pages at the apex domain lifehacker.dev, rendered by the `bamr87/zer0-mistakes` remote theme. It doubles as a headless CMS driven by a Claude Code autopilot that drafts, reviews and ships content, with a human (CODEOWNERS) as the only merge gate.

## 2. Target users

- Readers looking for practical tech hacks, tool reviews and news ("Wire") with a comedic voice
- The maintainer reviewing autopilot-authored PRs
- Fleet operators reusing the autopilot/CI patterns

## 3. Goals and non-goals

**Goals**

- Publish hacks, tools, field notes and wire posts on a steady cadence via the autopilot
- Keep facts accurate: satire in the framing, never the facts (wire)
- Enforce content quality with CI lints (front matter, brand, drift, links) and a Pages safe-mode build

**Non-goals**

- Patching theme bugs locally (they go upstream to zer0-mistakes)
- Auto-merging to `main` — merges are human-only
- Pinning `remote_theme` to a tag/ref

## 4. Core features (current)

- News sections Hacks / Tools / Field notes / Wire under `pages/_posts/`, with pinned `/hacks|tools|wire/:slug/` permalinks
- Machine-readable brand in `_data/brand/` (identity, voice, glossary) read by the autopilot
- Content backlog `_data/backlog.yml` with a custom merge driver
- Wire assignment editor `_data/wire/sources.yml` (sources, trust tiers, filters)
- Offline-generated cover art (`scripts/preview/`)
- CI harness: Pages safe-mode build plus front-matter, brand, drift and link lints
- Author personas in `_data/authors.yml`

## 5. Requirements

**Functional**

- News posts require `title description date author excerpt tags` and matching `categories:`; tools also need `verdict:`, wire needs non-empty sources
- Filename date must match front-matter `date:`; no future dates
- Authors must exist in `_data/authors.yml`
- All model calls go through the fleet runner `bamr87/bamr87/.github/actions/claude-run`

**Non-functional**

- Builds under GitHub Pages safe mode
- Brand `avoid_phrases` hard-fail; other brand findings advisory
- Cover-art seed order is a stable contract (append-only)
- Performance/accessibility budgets: TBD

## 6. Success metrics (proposed — not defined in sources)

- Posts shipped per week by section
- Autopilot PR acceptance rate
- CI lint pass rate on first push
- Reader traffic: TBD (no analytics source identified)

## 7. Roadmap / open questions

- Target publishing cadence per section: TBD
- Monetization / audience growth goals: TBD

## 8. Links

- [README.md](README.md) · [AGENTS.md](AGENTS.md) · [docs/AUTOPILOT.md](docs/AUTOPILOT.md) · [CHANGELOG.md](CHANGELOG.md) · [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Backlog of record: [GitHub Issues](https://github.com/bamr87/lifehacker.dev/issues) (the content queue the autopilot drafts from is `_data/backlog.yml`)
