# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Irony Works** — a self-growing encyclopedia of irony and, since September 2026, of paradox (two genera, one pipeline), in two halves:

- `vault/` — an Obsidian vault of Markdown entries; the source of truth for all content
- `engine/` — a Node.js pipeline (five irony prompts, three paradox prompts, three scripts) that drafts new entries via the Claude API

The vault publishes as a Jekyll site through the `bamr87/zer0-mistakes` remote theme, with a thin **theme layer** of five local files over it (see [Theme layer](#theme-layer)). `2026-08-06-planting-irony-works-*.md` at the root is a draft design-notes post documenting the founding session (excluded from the site). The project's pre-rebrand state ("Ironicon") is preserved in the founding commit.

## Commands

There is no package.json, test suite, or linter. Scripts are plain Node ESM with one dependency installed ad hoc:

```sh
npm i js-yaml --no-save    # lib.mjs loads it via createRequire

# Full germination cycle: scout → alanis gate → scribe → nursery/compost
# (uses the local claude CLI's OAuth by default; ANTHROPIC_API_KEY only as fallback)
node engine/scripts/germinate.mjs [batch]

# Score entry files against the gate of their genus (the PR check); routes by `type:` frontmatter
node engine/scripts/gate.mjs vault/nursery/some-entry.md vault/paradoxes/the-liar.md

# Convert vault → _entries/ Jekyll collection (wikilinks → permalinks); no credentials needed
node engine/scripts/transplant.mjs
```

`germinate.mjs` picks its rotation slot by `GITHUB_RUN_NUMBER % domains.length` (unset locally, cycle 0 → first entry). A rotation entry is a bare irony domain or a `paradox:`-prefixed family; `GERMINATE_DOMAIN=paradox:time-and-physics` overrides the slot for one run. All tunables — model, batch size, per-genus template, prompts, gate threshold and ledger (`genera:`), domain rotation, writable paths — live in `engine/seed.config.yml`.

## Architecture

**The schema is the classifier.** Irony is defined structurally, not in prose: every entry must state `expectation` and `reversal` as frontmatter fields. If a candidate can't fill both, it isn't irony and goes to compost. Entries also carry `status` (seed → sapling → canon → petrified), `veracity` (attested | contested | legend | speculative), and `alanis` (gate score, threshold 7/10). `vault/templates/` defines the exact shape; the Scribe prompt requires conformance to `entry.md`.

**Two genera, one pipeline.** Paradoxes (`type: paradox`, filed in `vault/paradoxes/` or as mirrors) state `premises`, `inference`, `conclusion`, and `collision`; the collision predicts Quine's `kind` (veridical | falsidical | antinomy), `standing` (resolved | contested | open) records the debate, and a `hypothesis` field, present only when the paradox rides on a counterfactual, marks it hypothetical — that is how "old, new, debated, hypothetical" is encoded as fields rather than folders. `vault/templates/paradox.md` is the shape; `vault/the-anatomy-of-a-paradox.md` is the framework the prompts assume; the three ways have form-style notes in `vault/forms/`. The genus has its own prompts under `engine/prompts/paradox/` and its own adversary, the Epimenides Gate (axes: plausibility, validity, collision, cost, specificity; verdicts MERELY-SURPRISING, EQUIVOCATION, TRANSPARENT-FALLACY, DILEMMA, ANOMALY, NOT-EVEN-WRONG), whose rejects go to `vault/compost/the-merely-puzzling.md`. Its score field is `epimenides:`, not `alanis:`. `seed.config.yml → genera` declares template, prompts, threshold, and ledger per genus; `genusOf()` / `parseDomain()` in `lib.mjs` resolve them.

**Pipeline** (`engine/scripts/germinate.mjs`): the genus's Scout proposes candidates for the cycle's domain → the genus's gate (`engine/prompts/alanis-gate.md` for ironies, scoring reversal, commentary, inevitability, specificity, non-substitutability; `engine/prompts/paradox/epimenides-gate.md` for paradoxes) scores each 0–10 on five axes → passes are drafted by the genus's Scribe into `vault/nursery/`; failures are appended as rows to the genus's ledger with a verdict. Merging the nursery PR is the only path to canon — the machine proposes, the human disposes.

**Guardrails are enforced, not advisory.** `assertWritable()` in `engine/scripts/lib.mjs` restricts engine writes to exactly `vault/nursery/` and the two compost ledgers (`seed.config.yml → guardrails.writable`). The engine never modifies canon entries, its own prompts, workflows, or config; any automation you add must write through `writeVaultFile()`/`appendCompost(row, ledger)` so the whitelist applies. Edits made at the direct request of the human maintainer are a different channel — that's the "human hand" the governance requires.

**Harness swap point:** `harness()` in `lib.mjs` defaults to running prompts through the Claude Code CLI (`claude -p`), which authenticates via OAuth — keychain locally, `CLAUDE_CODE_OAUTH_TOKEN` in CI (`claude setup-token` generates one). If the CLI is missing or errors, it falls back to the Anthropic Messages API with `ANTHROPIC_API_KEY`; `harness.provider: anthropic` forces API-only. `harness.provider: lifehacker` hits a deliberate stub marked `// HARNESS ADAPTER` for routing through lifehacker.dev instead. Prompts are the contract; keep them wire-agnostic.

**Publishing:** `transplant.mjs` indexes every note's `title:` frontmatter (regex-matched — every note needs one), rewrites `[[wikilinks]]` (resolved case-insensitively by title or filename slug) into `/entries/<slug>/` permalinks, and emits everything except `vault/templates/` into `_entries/`. A note whose frontmatter is not valid YAML (an unquoted value containing `: `, say) stops the transplant with its file and line, before any entry is written; it used to publish silently with no frontmatter — its slug for a title and, having no date, Jekyll's build time for one. Jekyll builds that collection with the remote theme; `vault/`, `engine/`, and the root docs are excluded from the site. The landing page dates an entry by its `planted:` (which transplant copies into `date`), never by `date` alone: Jekyll gives a collection document without one the build's clock, so the vault index and the compost ledgers would otherwise read as planted on every build day.

## Theme layer

The site is a `remote_theme` consumer of `bamr87/zer0-mistakes`, unpinned. Five local files sit over it. Three **shadow** a theme file (declared in `.theme-overrides.yml` at the repo root, which is what keeps the theme's `scripts/bin/audit-consumer` honest — without it all three read as unjustified drift); two shadow nothing.

| File | Kind | Why it exists |
|---|---|---|
| `_layouts/section.html` | override (~55 lines vs the theme's ~618) | The theme's `section` layout is a news/magazine view built entirely on `site.posts`, tags, and categories. This site has **zero posts** — its content is the custom `entries` collection — so the theme's version renders nothing. Ours filters `site.entries | where: "section", page.section` and shows an irony's `expectation` / `reversal` or a paradox's `premises` / `conclusion`, with the gate score, `kind`, `standing`, `veracity`, `status`. Consumed by the nine branch pages: `forms`, `works`, `figures`, `instances`, `paradoxes`, `mirrors`, `futures`, `nursery`, `compost`. |
| `_includes/components/cookie-consent.html` | override (deliberately empty) | The theme's banner claims the site "analyzes traffic" and "provides personalized content" via cookies. This site sets no analytics and no cookies, so the banner would be a false statement occupying a third of the mobile viewport. **If analytics are ever added, delete this file** — the theme's banner returns on its own, and it should. |
| `_includes/custom/head.html` | override (extension point) | The theme ships this file as an intentionally **empty stub** whose own header comment tells consumers to shadow it. Ours adds one `<link>` to `/assets/css/sections.css` — the branch palette Jekyll generates at build time from `_data/sections.yml`. This is the hook working as designed, not drift. |
| `_includes/home/card.html` | ours (shadows nothing) | Magazine card for `index.md`; teases with the entry's payload — an irony's `reversal`, a paradox's `conclusion` — not a generic excerpt. |
| `_includes/home/cover.html` | ours (shadows nothing) | Cover art for that card, falling back to a branch-coloured gradient. |

The theme has no `_includes/home/` directory at all, so the last two are net-new — **not** overrides, and deliberately absent from `.theme-overrides.yml`.

**Theme data contract (known gap, currently inert).** `remote_theme` does not ship `_data`, so consumers supply their own; this repo has only `_data/navigation/main.yml` and `_data/sections.yml`, and lacks `ui-text.yml`, `theme_skins.yml`, `theme_backgrounds.yml`, and `authors.yml` — with no visible effect today, because every one of the theme's ~43 `ui.*` reads carries an inline English `| default:`, `site.data.authors` is only indexed when a page sets `author:` (no entry or page does), `theme_skins`/`theme_backgrounds` are read only by `theme-controls-bar.html` / `theme-customizer.html` which no layout in this site's chain includes, and breadcrumbs are gated on an unset `site.breadcrumbs`. Add a data file when a component actually renders degraded without it — not preemptively.

**The Obsidian plugin is a non-issue.** The theme's `_plugins/obsidian_links.rb` is not needed here and must not be vendored in: `transplant.mjs` (`link()`) resolves every `[[wikilink]]` into a plain markdown link `[label](/entries/<slug>/)` — or into plain text plus a reported dead link — *before* Jekyll ever runs (`publish.yml` runs transplant, then `actions/jekyll-build-pages`). By build time there are no wikilinks left to convert. The theme's auditor lists it as an informational `OPTIONAL_PLUGIN`; earlier versions flagged it as missing. Either way, ignore it.

**Local preview.** There is none, by design-so-far: no `Gemfile`, no `docker-compose.yml`, no local bundle. CI builds with `actions/jekyll-build-pages` (the github-pages image, which bundles `jekyll-remote-theme`), so the only current way to see a themed change rendered is to push and let `publish.yml` run — or, in zer0-CMS, `python3 ../../tools/jekyll_theme.py build irony-works --repository bamr87/irony-works`, which runs the same transplant and the same image on a copy of the site, with Docker. Content and engine work does not need it — `node engine/scripts/transplant.mjs` runs with no credentials and shows exactly what Jekyll will be handed. Adding a local preview stack is a maintainer decision, not a papercut to patch around.

## The zer0 stack

Irony Works is a consumer of the zer0 stack: the `bamr87/zer0-mistakes` theme (the unpinned `remote_theme` above, with its three deliberate forks named in `.theme-overrides.yml`), the `zer0-image-generator` preview engine, and zer0-CMS. The `preview_images:` block in `_config.yml` uses the gem's documented keys to describe the plates `engine/scripts/preview.mjs` already renders (provider `local`, SVG-only, `assets/images/previews/`, front-matter key `preview`). The gem itself is not installed: there is no Gemfile by design, the Pages build could not load it, and `preview.mjs` stays the renderer of record. `zer0.json` at the root is the zer0-CMS content model. It registers the vault folders (the source of truth) and the root pages, with one content type per `vault/templates/` shape, and it leaves out `_entries/` on purpose, because that folder is gitignored transplant output that the next publish overwrites. To check alignment, dispatch `.github/workflows/zer0-doctor.yml` (report-only, also weekly) or run `ruby -I rails/lib rails/bin/zer0-cms doctor /path/to/irony-works` from a zer0-CMS checkout.

## Content conventions

- One entry per file, kebab-case filename; the filename is the permalink slug.
- One genus per entry. A paradox carries `type: paradox` and the four paradox fields, never `expectation`/`reversal` beside them; it crosses the aisle with `Rhymes with:`. Never sharpen a paradox past its canonical formulation (Epimenides is not the Liar); where the kind is contested, pick one and say who disagrees.
- Wikilink generously, but only to targets that exist — a broken wikilink is a promise the vault must keep or delete.
- Prefer one verified irony to five plausible ones. Thin sources → downgrade `veracity` and say so in the body; never sharpen a story past its evidence.
- Rejected candidates are logged in compost, never deleted; history occasionally files an appeal.
- `vault/mirrors/` documents this repository's own ironies — self-exemption would fail the vault's own gate.

## Workflows

- `.github/workflows/germinate.yml` — weekly cron (Mon 06:00 UTC) + manual dispatch with `count` and `domain` inputs (`domain: paradox:time-and-physics` targets a genus for one run); runs the engine and opens a PR from `vault/nursery/` changes. Needs the `CLAUDE_CODE_OAUTH_TOKEN` repo secret (or `ANTHROPIC_API_KEY` as fallback).
- `.github/workflows/alanis-gate.yml` — advisory PR check on `vault/**` changes; scores changed entries (excluding templates and compost) against the gate of their `type:` — Alanis for ironies, Epimenides for paradoxes; notes with neither `expectation` nor `premises` are reported UNGATED — and posts the report as a PR comment and step summary. Never blocks — the gates score, humans merge.
- `.github/workflows/publish.yml` — on push to main: transplant → Jekyll build (github-pages image bundles `jekyll-remote-theme`) → deploy to GitHub Pages.
- `.github/workflows/zer0-doctor.yml` — weekly (Fri 05:53 UTC) + manual dispatch; a thin, report-only caller of zer0-CMS's reusable `zer0 doctor` (see [The zer0 stack](#the-zer0-stack)). No model call, no secret, never on a pull request, `fail-on-error: false`.

## Fleet context

This repo is one of ~40 managed by the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87) (registry: `_data/projects.yml`; tiered baseline: `docs/STANDARDS.md`). It is vendored there as a git submodule: commit and push changes **here** first — the hub only bumps its pointer afterwards. Shared CI, release, schema, and agent kits are seeded from the hub's `templates/`; prefer adopting those over hand-rolling equivalents.

## Standard deviations

- **No `package.json`, test suite, or linter — by design.** Already documented under [Commands](#commands): the engine is plain Node ESM with `js-yaml` installed ad hoc (`npm i js-yaml --no-save`), and the schema-as-classifier plus the Alanis Gate are the quality controls. Do not scaffold a package manifest or a test runner to satisfy a fleet baseline check; the deviation is deliberate.
- **No local preview stack — by design.** See [Theme layer → Local preview](#theme-layer): no `Gemfile`, no `docker-compose.yml`; `publish.yml` is the only build. Adding one is a maintainer decision.
