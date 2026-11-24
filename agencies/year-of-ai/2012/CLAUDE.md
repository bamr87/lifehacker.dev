# CLAUDE.md

This repository is a **self-growing knowledge base** in the [`year-of-ai`](https://github.com/year-of-ai) lineage. It holds only its own **content**, a GitHub Pages `_config.yml` (a `remote_theme` consumer of [`bamr87/zer0-mistakes`](https://github.com/bamr87/zer0-mistakes)), the `.claude/` adapter toolkit, and `telemetry/`.

## How it grows — it does not grow itself

Growth is orchestrated **centrally by the hub** (`year-of-ai/year-of-ai.github.io`). On each tick the hub checks out this repo, stages the canonical agent framework into `.github/` and this repo's concept seed as `seed.md`, runs a **Haiku → Sonnet → Opus** escalation to research and write new content, then publishes **only** the new content + telemetry back here. The seed, the growth policy, and the framework all live in the hub, never in this repo. See the hub's [orchestration model](https://year-of-ai.github.io/orchestration/).

## Conventions

- **Content** lives under the taxonomy category directories defined by this repo's seed; each topic is one Markdown file with `title` / `date` / `category` front matter, written in a factual, neutral, encyclopedic, third-person tone, with every fact verified against ≥2 sources.
- **`.claude/` is adapters only.** The skills (`.claude/skills/`) and commands (`.claude/commands/`) are thin pointers; their canonical procedures are staged from the hub under `.github/` at tick time. `seed.md` is likewise present only during a tick.
- **`README.md` is the site homepage** (`jekyll-readme-index`). Don't add theme files (`_layouts`, `_includes`, `_sass`) — the theme is remote.

## Governance

Read [`docs/constitution.md`](docs/constitution.md) before changing anything: it is the highest-precedence rule set here and wins over this file when they disagree. It changes only through a numbered record in [`docs/amendments/`](docs/amendments/), ratified by the maintainer merging the PR; agents propose, never merge. Every user-facing feature has a stable id in [`features/features.yml`](features/features.yml) with `status`, location and the PRD requirement ids it serves; the PRD's "Feature catalog" block is generated from it (`python3 <bamr87/bamr87>/tools/governance_lint.py prd-sync . --write`; check with `… check .`). Never hand-edit that block or `CHANGELOG.md`.
