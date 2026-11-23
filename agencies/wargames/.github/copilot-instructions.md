# Wargames — GitHub Copilot Instructions

## Project overview

- **What it is**: a content-only Jekyll site — a vendored markdown mirror of the [OverTheWire](https://overthewire.org/wargames/) security wargames, published on GitHub Pages
- **Site title**: Wargames
- **Author**: bamr87
- **Theme**: [zer0-mistakes](https://github.com/bamr87/zer0-mistakes), loaded remotely (`remote_theme`) — this repo vendors no theme files
- **Content**: `index.md` (homepage) and `overthewire/**` (the challenge pages). There is no `pages/` directory and no Jekyll collections.

## Key commands

```bash
bundle install                             # Install dependencies
bundle exec jekyll serve                   # Dev server at http://localhost:4000/wargames/
bundle exec jekyll build                   # Build site
python3 ../../tools/unwrap-prose.py --check      # Lint: one paragraph per line (--write to fix)
```

## Conventions

- Don't hand-edit the upstream text in `overthewire/**`; it is re-synced from upstream by `scripts/docs-aggregator/`. The **Study guide** block at the end of each page (between `<!-- study-guide:start -->` and `<!-- study-guide:end -->`) and the `description` / `excerpt` front matter are this site's own and may be edited.
- Study guides are spoiler-free: no passwords, payloads or finished solutions.
- Markdown prose is one paragraph per line (CI enforces it).
- No theme overrides: no `_layouts/`, `_includes/`, `_sass/` or `_plugins/` here. Theme changes belong in zer0-mistakes. Style the site only through the theme's documented layers: `_config.yml`, `_data/`, and `assets/css/user-overrides.css` / `assets/js/user-overrides.js`.
- Navigation: the top navbar is `_data/navigation/main.yml`; the games sidebar is built automatically from page URLs.
- Conventional Commits, and open a pull request rather than pushing to `main`.

## Content front matter

Challenge pages are stamped by the aggregator and look like this:

```yaml
---
title: Bandit1
description: "One-sentence summary of the page"
excerpt: "One-sentence summary of the page"
permalink: /docs/wargames/bandit/bandit1/
categories: [wargames, bandit]
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit1.md
license: MIT
nav_order: 1
sidebar_label: "Level 1"
---
```

See `CLAUDE.md` and `AGENTS.md` for the fuller site-wiring reference.
