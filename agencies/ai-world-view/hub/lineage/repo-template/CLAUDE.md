# CLAUDE.md

This repository is a **self-growing knowledge base** in the [`ai-world-view`](https://github.com/ai-world-view) lineage. It holds only its own **content**, a GitHub Pages `_config.yml` (a `remote_theme` consumer of [`bamr87/zer0-mistakes`](https://github.com/bamr87/zer0-mistakes)), the `.claude/` adapter toolkit, and `telemetry/`.

## How it grows — it does not grow itself

Growth is orchestrated **centrally by the hub** (`ai-world-view/ai-world-view.github.io`). On each tick the hub checks out this repo, stages the canonical agent framework into `.github/` and this repo's concept seed as `seed.md`, runs a **Haiku → Sonnet → Opus** escalation to research and write new content, then publishes **only** the new content + telemetry back here. The seed, the growth policy, and the framework all live in the hub, never in this repo. See the hub's [orchestration model](https://ai-world-view.github.io/orchestration/).

## Conventions

- **Content** lives under the taxonomy category directories defined by this repo's seed; each topic is one Markdown file with `title` / `date` / `category` front matter, written in a factual, neutral, encyclopedic, third-person tone, with every fact verified against ≥2 sources.
- **`.claude/` is adapters only.** The skills (`.claude/skills/`) and commands (`.claude/commands/`) are thin pointers; their canonical procedures are staged from the hub under `.github/` at tick time. `seed.md` is likewise present only during a tick.
- **`README.md` is the site homepage** (`jekyll-readme-index`). Don't add theme files (`_layouts`, `_includes`, `_sass`) — the theme is remote.
