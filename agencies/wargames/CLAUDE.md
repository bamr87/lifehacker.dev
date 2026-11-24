# CLAUDE.md

Guidance for AI coding agents (Claude Code, Copilot, Cursor) working in **wargames**.

Wargames is a **content-only Jekyll site**: a vendored markdown mirror of the [OverTheWire](https://overthewire.org/wargames/) challenges, published on GitHub Pages with the [zer0-mistakes](https://github.com/bamr87/zer0-mistakes) theme loaded via `remote_theme`. "Done" means the content renders under the theme and the Pages build stays green. The challenge pages under `overthewire/**` are **vendored** — re-sync them from upstream via `scripts/docs-aggregator/`, don't hand-edit the upstream text. The one exception is the **Study guide** section at the end of each page (between `<!-- study-guide:start -->` and `<!-- study-guide:end -->` markers) plus the site-owned front matter (`description`, `excerpt`, `title`, and the stamps listed in `README.md`); those are this site's own additions and are edited in place.

## Stack & commands

```bash
# build:                  python3 ../../tools/jekyll_theme.py build wargames   # zer0-CMS's Jekyll-theme option (Docker, no Ruby) → _site/
# re-sync content:        pip install -r scripts/docs-aggregator/requirements.txt && ./scripts/docs-aggregator/aggregate_docs.sh
# lint:                   python3 ../../tools/unwrap-prose.py --check
# after a re-sync:        python3 ../../tools/unwrap-prose.py --write pages/_docs/wargames/overthewire && python3 tools/carry-study-guides.py pages/_docs/wargames/overthewire
# tests:                  none — content-only repo; the CI gates below are the whole safety net
```

There is no test suite. CI is four workflows: `ci.yml` (thin caller of the hub's shared `standard-ci.yml` — don't edit the logic here), `markdown-oneline.yml` (the same `unwrap-prose.py --check`, with `SCHEMA.md`/`CHANGELOG.md` excluded), `jekyll-gh-pages.yml` (push to `main` → Bundler build → publish `_site/` to the `gh-pages` branch), and `claude.yml` (the `@claude` mention handler seeded from the hub's `templates/agent-context/` — an `@claude` mention in an issue, PR comment, or review runs `anthropics/claude-code-action`, one run at a time per thread, authenticated by `CLAUDE_CODE_OAUTH_TOKEN` with `ANTHROPIC_API_KEY` as fallback).

Re-sync gotcha: `aggregate_docs.sh` still stages its output under `pages/_docs/wargames/` (its it-journey-era layout; upstream is cloned into `work/`) — it does **not** rewrite `overthewire/**` in place, so diff and move the refreshed pages over after a run. A re-sync also drops the study guides and the site-owned front matter: run `../../tools/unwrap-prose.py --write` and then `tools/carry-study-guides.py` on the staged pages *before* moving them over (steps in `README.md`), and write a guide for any page it reports as unmatched. A re-sync with no upstream change should then produce no diff. Delete `pages/` and `work/` afterwards; Jekyll would build `pages/` as duplicate content.

Study-guide rules: no passwords, payloads or finished solutions (the guides explain concepts and give hint-level approaches); state only what the upstream page or a verified source supports, and say so where a level's topic is unknown; keep one paragraph per line; avoid Liquid (`{{`, `{%`) in prose (the aggregator itself emits `{{ '/docs/…' | relative_url }}` for upstream's absolute links, which is intended); use relative links such as `../` so they work under the `/wargames` baseurl. The guide is wrapped in `<section class="study-guide" markdown="1">` with an `sg-map` callout and an `sg-nav` previous/next row; keep that structure so the site's CSS applies.

## Site wiring

- `_config.yml` — `remote_theme: bamr87/zer0-mistakes`; `defaults` attach theme layouts to the root-level content (no Jekyll collections); `exclude` keeps tooling out of the build.
- `index.md` — homepage (`layout: home`, `permalink: /`): hero, learning path and game cards (the cards come from `_data/games.yml` through the theme's `card-grid` include).
- **Presentation layer.** `remote_theme` ships only `_layouts/`, `_includes/`, `_sass/` and `assets/`, not the theme's `_config.yml` or `_data/`, so the chrome's settings live here: `_config.yml` (`repository`, `theme_skin`, `logo`, `favicon`, footer keys, per-game `defaults`), `assets/css/user-overrides.css` and `assets/js/user-overrides.js` (the theme's documented consumer hooks, enabled by `user_overrides: true`), `assets/images/wargames/`, `search.json`, `tags.md` (the "All levels" index at `/tags/`), and `_data/`. Preview with the production-faithful recipe in `README.md`; a plain gem-theme preview merges theme config and hides real defects.
- `overthewire/**` — vendored challenge pages at `/docs/wargames/…` (`layout: default` + auto games sidebar), each ending with a site-authored study guide. Each level page carries `nav_order` + `sidebar_label` front matter (stamped by the aggregator) that the sidebar sorts/labels by; don't hand-edit — re-sync instead. `overthewire/index.md` is the games index and also carries a guide (the comparison table of all games).
- `_data/navigation/` — `main.yml` (navbar) only. The games→levels sidebar is **auto-built** by the theme's `nav: pages` mode (set on the `overthewire` scope in `_config.yml`) from the page URLs under `/docs/wargames/` — there is no sidebar data file to generate or maintain.
- `zer0.install.yml` — declarative installer config; re-scaffold with the theme's `scripts/bin/install --config zer0.install.yml`.

## Conventions

- Conventional Commits: `type(scope): description` (`feat`/`fix`/`docs`/`refactor`/`test`/`chore`/`ci`).
- Default branch is `main` — branch from it and open a PR; never push to it directly.
- README-First, README-Last: read the nearest `README.md` before changing a directory, and update it after.
- Don't suppress type errors (`as any`, `@ts-ignore`, `# type: ignore`) or leave empty exception handlers.

## Fleet context

This repo is one of ~40 managed by the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87) (registry: `_data/projects.yml`; tiered baseline: `docs/STANDARDS.md`). It is vendored there as a git submodule: commit and push changes **here** first — the hub only bumps its pointer afterwards. Shared CI, release, schema, and agent kits are seeded from the hub's `templates/`; prefer adopting those over hand-rolling equivalents.
