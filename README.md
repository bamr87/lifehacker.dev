# lifehacker.dev

> Surviving life, one byte at a time. Knowledge, tools, and comedy — published
> by a robot, reviewed by a human, shipped with the mistakes left in.

[![site](https://img.shields.io/badge/site-lifehacker.dev-d946ef)](https://lifehacker.dev)
[![theme](https://img.shields.io/badge/theme-zer0--mistakes-22d3ee)](https://github.com/bamr87/zer0-mistakes)

A [Jekyll](https://jekyllrb.com/) site rendered by the
[`bamr87/zer0-mistakes`](https://github.com/bamr87/zer0-mistakes) **remote theme**
and served by **GitHub Pages** at the apex domain `lifehacker.dev`. It is also a
**headless CMS driven by [Claude Code](https://claude.com/claude-code)** — see
[`AUTOPILOT.md`](AUTOPILOT.md).

## What's here

| Path | What it is |
|---|---|
| `_config.yml` | The whole site config — identity, neon skin, collections, defaults, plugins. |
| `_config_dev.yml` | Local-preview overlay (disables `remote_theme` so builds use local theme files). |
| `_data/navigation/`, `authors.yml`, `landing.yml` | Site data the remote theme needs but does **not** deliver. |
| `_data/brand/` | The machine-readable brand: `identity.yml`, `voice.yml`, `glossary.yml`. The autopilot reads these. |
| `_data/backlog.yml` | The autopilot's content queue. |
| `pages/_posts/` `_hacks/` `_tools/` `_about/` `_docs/` | Content collections (under `pages/` because `collections_dir: pages`). |
| `index.md`, `blog.md`, `hacks.md`, `tools.md`, `search.json`, `sitemap.md`, `404.html` | Spine pages. `search.json`/`sitemap.md` are hand-authored because the theme's generator is a plugin that GitHub Pages won't run. |
| `.claude/skills/grow-lifehacker/` | The autopilot skill. |
| `scripts/preview.sh` | Local Docker preview (overlay against a theme clone). |
| `docs/` | The setup tutorial and the build journey log (excluded from the site build). |

## Why the config is hand-written, not copied

`remote_theme` only delivers the theme's `_layouts/`, `_includes/`, `_sass/`, and
`assets/`. It does **not** deliver the theme's `_config.yml`, `_data/`, or
`_plugins/`. So this repo deliberately re-declares everything the theme's layouts
expect, and ships its own `_data/`. (Copying the theme's `_config.yml` wholesale
would also inherit the theme author's analytics keys — don't.) The
[Field Notes](https://lifehacker.dev/blog/) tell that story with jokes.

## Local preview

```bash
scripts/preview.sh          # overlay onto a theme clone + docker compose up → http://localhost:4000
scripts/ci/run-all.sh       # run the full test harness locally (build + lint + drift + brand)
```

GitHub Pages builds the real site from `main` on push. Pull requests are gated by
a GitHub Actions **test harness** ([`.github/workflows/test.yml`](.github/workflows/test.yml))
that reproduces the Pages build in safe mode and lints content, links, drift, and
brand voice. The checks live in [`scripts/ci/`](scripts/ci/) and run identically
for humans (`scripts/ci/run-all.sh` or the `/test-lifehacker` skill) and in CI. A
human still merges every PR — branch protection + [`CODEOWNERS`](.github/CODEOWNERS)
enforce it. See [`docs/runbook-fleet.md`](docs/runbook-fleet.md) for setup.

## The autopilot

This site grows itself: Claude Code reads `_data/brand/` + `_data/backlog.yml`,
drafts on-voice content with screenshots, files theme bugs upstream, and opens a
PR. **A human reviews and merges every change.** Full design in
[`AUTOPILOT.md`](AUTOPILOT.md) and at [/docs/autopilot/](https://lifehacker.dev/docs/autopilot/).

## License

Content © its authors. The theme is MIT-licensed by
[zer0-mistakes](https://github.com/bamr87/zer0-mistakes).
