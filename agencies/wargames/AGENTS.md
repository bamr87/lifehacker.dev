# AGENTS.md — AI Agent Guide for Wargames

> **Since 2026-11-23 this directory is the Wargames agency's back office.** Its pages are published as a collection of lifehacker.dev: `overthewire/` is now `pages/_wargames/` at the repository root, served under `/wargames/` (the URLs were `/docs/wargames/…`), and the images are in `assets/images/wargames/`. Read every `overthewire/` path below as `pages/_wargames/`. The pages build with the rest of lifehacker.dev (`scripts/ci/build.sh`), not with the `jekyll_theme.py` command below. The refresh tool moved with them: `scripts/docs-aggregator/transform.py` writes `/wargames/…` permalinks (`URL_PREFIX`) and makes relative reference links resolve, so a refresh no longer undoes the move. To refresh, stage the tool's output anywhere (`--output-dir`), unwrap it to one paragraph per line, run `tools/carry-study-guides.py <staged>/wargames/overthewire --old-dir ../../pages/_wargames`, then move the result into `pages/_wargames/`. A dry run against OverTheWire on 2026-11-24 reproduced all 219 permalinks and showed upstream changes in three pages (`bandit/bandit14.md`, `leviathan/index.md`, `narnia/index.md`); they have not been applied. Decision: `docs/adr/0003-agencies-as-collections.md`.

> Cross-tool entry point for AI coding agents (GitHub Copilot, Claude Code, Cursor, Aider, etc.)

## Project snapshot

- **What it is**: A content-only Jekyll site — a vendored markdown mirror of the [OverTheWire](https://overthewire.org/wargames/) challenges, published on GitHub Pages
- **Theme source**: remote (`remote_theme: bamr87/zer0-mistakes`) — this repo vendors **zero** theme files
- **Theme repo**: https://github.com/bamr87/zer0-mistakes
- **Content**: at the repo root — `index.md` (homepage) and `overthewire/**` (the challenge pages). There is no `pages/` directory and no populated Jekyll collections.

## Quick commands

```bash
# Build (zer0-CMS's Jekyll-theme option: the theme at the tag the root workspace.yml pins, Jekyll 4.4.1
# in the image tools/jekyll/Dockerfile pins — Docker, no Ruby) into _site/
python3 ../../tools/jekyll_theme.py build wargames

# Lint (markdown prose must be one paragraph per line — CI enforces it)
python3 ../../tools/unwrap-prose.py --check    # --write to fix
```

There is no test suite. CI is the safety net — see the workflow list in [`CLAUDE.md`](CLAUDE.md).

## Operating rules

1. Make minimal, surgical changes. Match existing style.
2. Validate before declaring done — run a Jekyll build and `python3 ../../tools/unwrap-prose.py --check`.
3. Site content lives at the repo root (`index.md`, `overthewire/**`); site data lives in `_data/`.
4. **Don't hand-edit the upstream text in `overthewire/**`** — those pages are vendored and re-synced from upstream by `scripts/docs-aggregator/`. The exceptions are the **Study guide** block at the end of each page (between the `study-guide` marker comments) and the site-owned front matter (`description`, `excerpt`, `title`, …); after a re-sync, restore them with `../../tools/unwrap-prose.py --write` then `tools/carry-study-guides.py` (see [`README.md`](README.md)). Study guides must stay spoiler-free: no passwords, payloads or finished solutions.
5. **No theme overrides here.** This repo is a pure `remote_theme` consumer with no `_layouts/`, `_includes/`, `_sass/`, or `_plugins/` — keep it that way. Theme changes belong upstream in [zer0-mistakes](https://github.com/bamr87/zer0-mistakes). The theme's documented consumer layers are fine and are how the site is styled: `_config.yml` keys, `_data/`, page front matter, and `assets/css/user-overrides.css` / `assets/js/user-overrides.js` (loaded because `user_overrides: true`). `remote_theme` does not merge the theme's own `_config.yml`, so any key the chrome reads must be set in this repo's `_config.yml`.
6. **Verify presentation in a browser, against what production serves** — not a plain gem-theme build, which merges theme config and hides defects. See "Local development" in [`README.md`](README.md).

See [`CLAUDE.md`](CLAUDE.md) for the fuller site-wiring reference and [`README.md`](README.md) for the reader-facing overview.
