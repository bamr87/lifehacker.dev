# CLAUDE.md

This repository is a **self-growing knowledge base** in the [`year-of-ai`](https://github.com/year-of-ai) lineage. It holds only its own **content**, a GitHub Pages `_config.yml` (a `remote_theme` consumer of [`bamr87/zer0-mistakes`](https://github.com/bamr87/zer0-mistakes)), the `.claude/` adapter toolkit, and `telemetry/`.

## How it grows — it does not grow itself

Growth is orchestrated **centrally by the hub** (`year-of-ai/year-of-ai.github.io`). On each tick the hub checks out this repo, stages the canonical agent framework into `.github/` and this repo's concept seed as `seed.md`, runs a **Haiku → Sonnet → Opus** escalation to research and write new content, then publishes **only** the new content + telemetry back here. The seed, the growth policy, and the framework all live in the hub, never in this repo. See the hub's [orchestration model](https://year-of-ai.github.io/orchestration/).

## Conventions

- **Content** is presented in the theme's **news layout**. Each taxonomy category from the seed is a news **section** published at `/news/<slug>/`; each article is a **post** at `_posts/<slug>/<YYYY-MM-DD>-<topic>.md` with `title` / `date` / `categories` / `tags` / `excerpt` front matter. A post's **`tags` are its section's sub-topics** (the theme's sidebar + filter pills). Write in a factual, neutral, encyclopedic, third-person tone, with every fact verified against ≥2 sources. (Legacy flat repos are converted once with the hub's `scripts/migrate-to-news-structure.rb`.)
- **`date:` must be a single plain ISO date** (`YYYY-MM-DD`) — never a range (`"1777–1778"`), a bare year, or prose. One unparseable date fails this site's **whole** Pages build; use the start date for ranges and `YYYY-01-01` when only the year is known.
- **`.claude/` is adapters only.** The skills (`.claude/skills/`) and commands (`.claude/commands/`) are thin pointers; their canonical procedures are staged from the hub under `.github/` at tick time. `seed.md` is likewise present only during a tick.
- **`README.md` is the site homepage** (`jekyll-readme-index`). Don't add theme files (`_layouts`, `_includes`, `_sass`) — the theme is remote.
