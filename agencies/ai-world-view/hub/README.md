# ai-world-view.github.io

The organization root site for [**ai-world-view**](https://github.com/ai-world-view) — a federated network of self-growing, country-by-country knowledge bases (`china`, `japan`, `north-korea`, `south-korea`, and growing): an atlas written from the AI's **own world view**. This repo is two things at once:

1. the **landing page + content hub** that presents and links every site in the org, and
2. the **central growth engine** that grows every country repo (the country repos hold only content — everything that grows them lives here).

It was **planted from the organizational genome** maintained in the reference implementation, [`year-of-ai/year-of-ai.github.io`](https://github.com/year-of-ai/year-of-ai.github.io) — the same model, transplanted to a new concept: countries instead of years.

🔗 **Live:** https://ai-world-view.github.io/ · **How it grows:** [/orchestration/](https://ai-world-view.github.io/orchestration/) · **Self-improvement fleet:** [/self-improvement/](https://ai-world-view.github.io/self-improvement/)

## How the site works

This is a thin Jekyll site. It **vendors no theme files** — it renders with the shared [zer0-mistakes](https://github.com/bamr87/zer0-mistakes) theme pulled in over [`remote_theme`](https://github.com/benbalter/jekyll-remote-theme):

```yaml
# _config.yml
remote_theme: "bamr87/zer0-mistakes"   # untagged — every org site tracks latest
```

Leaving it untagged is deliberate: every site in the fleet tracks the theme's latest `main`, so a theme fix reaches production without a bump PR in nine repos. The trade is that an upstream regression also arrives immediately — so theme bugs go **upstream** rather than getting pinned around, and the safety net is the `build-validation` gate on PRs plus `pages-deploy-sentinel` after deploy. `_data/hub.yml` (`pages.theme_repo`) carries the same untagged value; re-roll member configs with `scripts/provision-org-sites.rb` to propagate it.

Production builds on **native GitHub Pages** ("deploy from branch" — `main`, `/`).

## How the org grows

The hub is the central orchestrator: the country repos hold only their content + a Pages `_config.yml` + `.claude/` + `telemetry/`. Daily, `orchestrate.yml` refreshes the lineage ledger and dispatches `grow-lineage.yml` for the stalest members (cadence set in `lineage/policy.yml`); each tick stages the canonical framework + that country's seed into a checkout of the country repo, runs the 3-tier model escalation (Haiku draft → Sonnet expand → Opus enhance, with an API-key fallback), banners each new article with a Claude-authored SVG preview (the **Illustrate** step, `scripts/claude_svg_banner.py`), then publishes only new content + telemetry back.

The defining difference from the reference implementation: content is written from the model's **own knowledge** — the growth passes do no web research, fetching, or searching. What is published is the AI's own world view of each country.

A self-improvement fleet of watcher workflows monitors builds, credentials, docs coverage, and the evolution ledger. Full explainer: [/orchestration/](https://ai-world-view.github.io/orchestration/); the design decisions (ADRs) live in the reference hub's [`lineage/decisions/`](https://github.com/year-of-ai/year-of-ai.github.io/tree/main/lineage/decisions).

## Kill switches

Autonomy is gated in two layers, and a scheduled run needs both to permit it. `_data/fleet_pause.yml` is the in-tree **emergency stop**: it defaults to running, and setting `paused: true` halts every mutating lane at once (growth dispatch, hub sync, the watchers) without touching a workflow. The `*_ENABLED` **repository variables** are the opt-in **arming** switches: they default to off, so a fresh clone's crons idle until a human sets one; a manual `workflow_dispatch` always runs, and the bot token cannot set variables, so no loop can arm itself.

```bash
gh variable set ORCHESTRATE_ENABLED --body true          # the daily orchestrate cron, and through it every grow-lineage / plant-lineage dispatch
gh variable set SECRET_EXPIRY_WATCH_ENABLED --body true  # the daily credential probe
```

Pure PR checks (`ai-content-review`, `framework-pr-reviewer`, `build-validation`, the `docs-warden` gate) deliberately carry no arming switch — a paused fleet must still be able to validate a human's pull request. The two that call a model have an **off** switch for that model pass alone (fleet harness standard, 2026-11-13): `AI_CONTENT_REVIEW_ENABLED` and `FRAMEWORK_PR_REVIEWER_ENABLED` are on while unset, and setting one to `false` stops the Claude tier while the deterministic checks keep running.

## Layout

| Path | What it is |
|---|---|
| `_config.yml` / `_config_dev.yml` | Production / local-dev configuration |
| `pages/` | Site content (home, hub + lineage dashboards, orchestration + self-improvement explainers, …) |
| `_data/` | Theme data (navigation, `ui-text`, skins, authors) + the hub registry (`hub.yml`, auto-discovery) and generated dashboards (`hub_index.yml`, `lineage.yml`) + the fleet kill-switch (`fleet_pause.yml`) |
| `lineage/` | **Growth source of truth**: `seeds/<country>.md` (today: `china.md`, `japan.md`, `north-korea.md`, `south-korea.md`), `policy.yml` (models + cadence + preview art direction), `framework/` (staged agent toolkit), `repo-template/`, `seed-package/` |
| `telemetry/` | Hub evolution ledger (`evolution.jsonl`, one record per grow run) |
| `scripts/` | Hub tooling — dashboards (`sync-hub-metadata.rb`, `sync-lineage-state.rb`), provisioning (`provision-org-sites.rb`), the planter (`plant-lineage.rb`), fleet health (`fleet-health.rb`), docs coverage (`docs-warden.rb`), content review (`content-review.rb`), front-matter repair (`normalize-front-matter-dates.rb`), preview banners (`claude_svg_banner.py` + `generate-preview-images.sh`) |
| `templates/org-site/` | Scaffold the provisioner writes into each org repo |
| `templates/deploy/chat-proxy/` | Cloudflare Worker for the AI-chat widget (disabled until deployed) |
| `fleet.manifest.yml` | This repo's AI lanes in the shared `fleet/v1` vocabulary (`provenance: derived`; each lane's `switch:` names its arming variable) |
| `.claude/` | The `content-reviewer` agent behind `ai-content-review` + `settings.json`, a read-only `git`/`gh` permission allowlist |
| `.github/workflows/` | The growth engine (`orchestrate`, `grow-lineage`), the fleet (`telemetry-ledger`, `fleet-health-watch`, `pages-deploy-sentinel`, `secret-expiry-watch`, `framework-pr-reviewer`, `docs-warden`), content/site automation (`hub-sync`, `ai-content-review`, `codeql`, the weekly `site-quality-scan`), and the fleet-kit thin callers owned by the bamr87/bamr87 kits (`ci`, `conformance`, `verify`, `release`, `claude`) — change those in the hub, not here |

Everything the theme provides (`_layouts`, `_includes`, `_sass`, `assets/css`, JS, vendored Bootstrap, images) comes from `remote_theme` at build time and is not stored here.

## The content hub

`_data/hub.yml` is the registry of org repos — members self-register via `auto_discover` (there is no manual repo list). The dashboard at [`/hub/`](https://ai-world-view.github.io/hub/) and the country grid on the home page are generated from it:

```bash
ruby scripts/sync-hub-metadata.rb          # refresh _data/hub_index.yml + navigation/hub.yml
ruby scripts/sync-hub-metadata.rb --check  # CI gate (validate only)
ruby scripts/sync-lineage-state.rb         # refresh _data/lineage.yml from lineage/seeds/*
ruby scripts/provision-org-sites.rb        # scaffold/enable Pages on org repos
```

The daily `hub-sync` workflow runs the sync and commits only when the org changed.

## Local development

```bash
export JEKYLL_GITHUB_TOKEN=$(gh auth token)   # avoids theme-download rate limits
docker compose up                             # http://localhost:4000 (live reload)
# or, without Docker:
bundle install && bundle exec jekyll serve --config '_config.yml,_config_dev.yml'
```

Local dev fetches the theme over the network, exactly like production. To work against a local theme checkout instead, point `remote_theme` at a sibling clone or use `bundle config local.jekyll-theme-zer0 ../zer0-mistakes`.

## License

No `LICENSE` file yet. The reference implementation is MIT, but this repo has not committed a license of its own, so nothing here grants reuse rights until one lands. The zer0-mistakes theme is maintained at [bamr87/zer0-mistakes](https://github.com/bamr87/zer0-mistakes) under its own license.
