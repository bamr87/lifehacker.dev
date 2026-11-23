# Wargames

> OverTheWire security wargames (Bandit, Natas and more) mirrored as a Jekyll study site, extracted from it-journey.

[![CI](https://github.com/bamr87/wargames/actions/workflows/ci.yml/badge.svg)](https://github.com/bamr87/wargames/actions/workflows/ci.yml) [![License](https://img.shields.io/github/license/bamr87/wargames)](LICENSE) [![Live site](https://img.shields.io/badge/live-bamr87.github.io%2Fwargames-2ea44f)](https://bamr87.github.io/wargames/)

## Overview

Curated **security wargames** content — a vendored, markdown mirror of the [OverTheWire](https://overthewire.org/wargames/) community challenges (Bandit, Natas, Narnia, Behemoth, Leviathan, Krypton, and more), published as a Jekyll site with the [zer0-mistakes](https://github.com/bamr87/zer0-mistakes) theme.

> **Provenance:** This collection was extracted from
> [bamr87/it-journey](https://github.com/bamr87/it-journey) (`pages/_docs/wargames/`) via
> `git subtree split`, so the full edit history is preserved here. It now lives as a standalone
> repository so the IT-Journey site can stay focused on its gamified quests.

## Features

- Markdown mirrors of OverTheWire wargames: Bandit, Natas, Narnia, Behemoth, Leviathan, Krypton and more
- Study guides that explain concepts with hint-level approaches, never passwords or solutions
- A Jekyll site on the zer0-mistakes theme, published to GitHub Pages
- Scripts to re-sync content from the upstream OverTheWire website

## Source & license

All challenge content is aggregated from the OverTheWire website and is distributed under the **MIT License**.

- **Upstream:** <https://github.com/OverTheWireOrg/OverTheWire-website> (`gh-pages` branch)
- **License:** [MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)

This is **vendored content** — treat the upstream text as read-only and re-sync from upstream rather than editing it by hand. Each page carries `source_repo` / `source_url` / `license` frontmatter recording its origin. The one deliberate exception is the [study guides](#study-guides) this site appends to each page.

## Study guides

Many upstream pages are sparse (some say only "There is no information for this level, intentionally"), so every page under `overthewire/**` ends with a **Study guide** written for learners: what the level or game teaches, the concepts behind it, a hint-level approach, and why the skill matters in real IT and security work. The game index pages add prerequisites, tool lists and a level-by-level roadmap, and `overthewire/index.md` compares all the games.

The guides follow a few rules:

- **Marked and appended.** A guide sits at the very end of its page between `<!-- study-guide:start -->` and `<!-- study-guide:end -->`, wrapped in a `<section class="study-guide">` that the site styles as a panel, so it is easy to tell apart from the vendored text above it, which is left untouched.
- **No spoilers.** Guides name the concept a level exercises but never contain passwords, payloads or finished solutions, so the games stay worth playing.
- **Honest about gaps.** Where upstream withholds a level's description and the topic could not be confirmed, the guide gives a general investigation method and says so instead of guessing.
- **Level map.** Numbering differs between games (in Bandit, page N explains how to *reach* level N; in Natas, page N is the level you are *in*), so most guides open with a one-line map of which account you are logged in as and which password you are after.
- **Page summaries and titles.** `description` and `excerpt` front matter are one-sentence summaries of the page (the theme shows `description` under the page title, and search indexes it). The values the aggregator derives from upstream are truncated body text such as `Level Goal ----------`. Level pages are titled `Bandit Level 2` rather than the aggregator's `Bandit2`.
- **Navigation.** Each level guide ends with previous / next links (relative, so they work under any `baseurl`), and the level map is shown as a callout.

Re-syncing from upstream regenerates the pages and drops the guides and the site-owned front matter. Carry them across with `tools/carry-study-guides.py` as described in [Regenerating from upstream](#regenerating-from-upstream).

## Theme & site

The site is built with the **zer0-mistakes** Jekyll theme, loaded remotely on GitHub Pages via the `remote_theme: bamr87/zer0-mistakes` directive — no theme files are vendored here, so this repo stays content-only.

The framework (`_config.yml`, `_data/`, `.github/workflows/jekyll-gh-pages.yml`, and a `Gemfile` and `.devcontainer/` that zer0-CMS removed when the site moved to its Jekyll-theme option) was scaffolded with the theme's AI installer and is described declaratively in [`zer0.install.yml`](zer0.install.yml). Re-scaffold or upgrade it with:

```bash
# from a checkout of bamr87/zer0-mistakes
scripts/bin/install init /path/to/wargames --config /path/to/wargames/zer0.install.yml --non-interactive --force
```

### Content wiring

- `index.md` → the homepage (`/`), using the theme's `home` layout.
- `overthewire/**` → the challenge pages, served at their `permalink` (`/docs/wargames/…`) with the theme's `default` layout and the auto games sidebar. The `overthewire/index.md` is the games index at `/docs/wargames/`.
- `_config.yml` `defaults` attach layouts to the root-level content (there are no Jekyll collections), and `exclude` keeps tooling/docs out of the build.

### Sidebar navigation

The left sidebar is a two-level tree — one collapsible group per game, its individual levels as children — so every challenge page is reachable. There is **no navigation data file to maintain**: the `overthewire` scope in `_config.yml` turns on the zer0-mistakes theme's `nav: pages` mode, which builds the tree **automatically from the page URLs** under `/docs/wargames/`:

```yaml
sidebar:
  nav: pages
  base: /docs/wargames/    # root the tree here
  order_by: nav_order      # sort each game's levels numerically
  title: Wargames
```

Ordering and labels come from per-page front matter stamped by the content pipeline — each level page carries `nav_order` (its numeric suffix, so levels sort 0,1,2,…,10) and `sidebar_label` (`"Level N"`). The aggregator (`scripts/docs-aggregator/transform.py`) sets both on every sync, so the sidebar stays in step with the content with nothing to regenerate by hand. The theme marks the current page active and expands its game on load (server-side, no JavaScript).

### Look and feel

`remote_theme` gives the site the theme's `_layouts/`, `_includes/`, `_sass/` and `assets/` and **nothing else**: it does not merge the theme's own `_config.yml`, `_data/` or plugins. Everything the theme's chrome needs is therefore set in this repo, using only the theme's documented customisation layers. No layout, include, sass or plugin is overridden.

| File | What it does |
|------|--------------|
| `_config.yml` | `repository` / `branch` (the theme builds "Edit on GitHub" and "View source" from them), `theme_skin: mint`, `logo`, `favicon`, `info_banner`, the footer `links` / `powered_by` / `footer_quick_links`, `user_overrides: true`, `search.content_length`, and per-game `defaults` that give each game's pages a banner and a difficulty badge. `email` is deliberately unset: even an empty value makes the footer emit an empty `mailto:` link. |
| `assets/css/user-overrides.css` | The site's only stylesheet: homepage, study-guide panel, "All levels" index, and hiding theme chrome that does not apply here (cookie banner, newsletter placeholder, tag badges). |
| `assets/js/user-overrides.js` | A shim that adds the `baseurl` to the search modal's hard-coded `/search.json` request, which otherwise 404s on a project site. |
| `assets/images/wargames/`, `favicon.ico` | Logo, favicon and one generated banner per game. |
| `search.json` | The search index the theme's search modal loads. `remote_theme` does not ship it. |
| `tags.md` | Served at `/tags/`: a one-page "All levels" index. The theme's category and tag badges link there. |
| `_data/games.yml` | The games by tier; feeds the homepage cards through the theme's `card-grid` include. |
| `_data/navigation/main.yml` | The top navbar, grouped by tier. |
| `_data/authors.yml` | Byline names. |

The left sidebar's group order and labels are fixed by the theme (it sorts games by URL name and labels them from the URL segment), so they cannot be changed from here.

### Local development

In zer0-CMS the site builds with the Jekyll-theme option, with Docker and no Ruby — the build the one Pages deploy runs:

```bash
python3 ../../tools/jekyll_theme.py build wargames   # → _site/
```

It loads the theme with `jekyll-remote-theme` at the tag the root `workspace.yml` pins, in Jekyll 4.4.1 with the plugins `tools/jekyll/Dockerfile` pins, so what you see is what production serves.

## Project structure

```
index.md                 # Homepage (layout: home): hero, learning path, game cards
search.json              # Search index for the theme's search modal
tags.md                  # "All levels" index, served at /tags/
favicon.ico
assets/                  # css/user-overrides.css, js/user-overrides.js, images/wargames/ (logo, banners)
overthewire/             # Vendored OverTheWire challenge pages + study guides
  index.md               #   Games index (/docs/wargames/)
  bandit/                #   Linux/Unix fundamentals
  natas/                 #   Server-side web security (browser, no SSH)
  krypton/ leviathan/    #   Cryptography; first steps in reverse engineering
  narnia/ behemoth/      #   Binary exploitation, with and without source
  utumno/ maze/ ...      #   Harder binary exploitation
  manpage/ vortex/ ...   #   Code auditing and advanced mixed games (drifter, formulaone)
  semtex/ blacksun/      #   Offline / down games kept as reference
  abraxas/ hes2010/ ...  #   Downloadable conference games (kishi, monxla)
_config.yml              # Jekyll config (remote_theme, defaults, excludes)
_data/                   # games.yml (homepage cards), authors.yml, navigation/main.yml (top navbar)
                         #   — the games sidebar is auto-built from page URLs
zer0.install.yml         # Installer config that scaffolds the framework
scripts/docs-aggregator/ # Upstream content sync pipeline
tools/                   # unwrap-prose.py (lint) and carry-study-guides.py (re-sync helper)
```

## Regenerating from upstream

The `scripts/docs-aggregator/` pipeline clones the OverTheWire repo, extracts the wargames markdown, and rewrites frontmatter with provenance metadata.

```bash
pip install -r scripts/docs-aggregator/requirements.txt
./scripts/docs-aggregator/aggregate_docs.sh
```

Sources are registered in `scripts/docs-aggregator/docs_config.yml`.

The pipeline stages its output under `pages/_docs/wargames/overthewire/` rather than rewriting `overthewire/**` in place, so refreshing the site is a short manual process:

```bash
./scripts/docs-aggregator/aggregate_docs.sh
STAGED=pages/_docs/wargames/overthewire
python3 ../../tools/unwrap-prose.py --write $STAGED      # the repo keeps one paragraph per line; fresh upstream text is soft-wrapped
python3 tools/carry-study-guides.py $STAGED        # re-attach the study guides and the site-owned front matter
diff -r $STAGED overthewire                         # review what changed upstream
cp -R $STAGED/. overthewire/                        # move the refreshed pages over
rm -rf pages work                                   # staging areas; Jekyll would otherwise build duplicates
```

`carry-study-guides.py` keeps each current page's study guide and its site-owned front matter (`description`, `excerpt`, `title`, `author`, `draft`, `keywords`, the game category, `date`) and takes the provenance keys (`source_*`, `permalink`, `nav_order`, …) from the fresh page. It keeps `lastmod` when the upstream text did not change, so a re-sync with no upstream changes produces **no diff**; any page that does differ is a real upstream change worth reviewing. It lists pages it could not match, such as a level newly added upstream, which need a guide (and the site-owned front matter) written for them.

## Using this content

The pages are plain Markdown with YAML frontmatter (Jekyll-compatible). They can be served as a standalone Jekyll site, embedded in another docs system, or read as-is on GitHub.

## Development

Full commands, conventions and gotchas for humans and AI agents live in [AGENTS.md](AGENTS.md).

## Contributing

Contributions are welcome via pull request. Use [Conventional Commits](https://www.conventionalcommits.org/) and keep the CI checks green. The fleet-wide workflow is described in the hub's [CONTRIBUTING.md](https://github.com/bamr87/bamr87/blob/main/CONTRIBUTING.md). AI agents should start with [AGENTS.md](AGENTS.md) (with [CLAUDE.md](CLAUDE.md) for Claude Code).

## Changelog

Notable changes are recorded in [CHANGELOG.md](CHANGELOG.md); the full record is in the [commit history](https://github.com/bamr87/wargames/commits/main).

## License

The repository is released under the [MIT License](LICENSE). The challenge content is aggregated from OverTheWire under its own MIT license; see [Source & license](#source--license).

---

<!-- bamr87-portfolio-footer -->
Part of the [bamr87 portfolio](https://github.com/bamr87) — browse every project on [Amr's GitHub profile](https://github.com/bamr87).
