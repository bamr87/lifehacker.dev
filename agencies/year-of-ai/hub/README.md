# year-of-ai.github.io

The organization root site for [**year-of-ai**](https://github.com/year-of-ai) — a federated network of self-growing, year-by-year knowledge bases (1776–1778 and 2005–2012, and growing). This repo is three things at once:

1. the **landing page + content hub** that presents and links every site in the org,
2. the **central growth engine** that grows every year repo (the year repos hold only content — everything that grows them lives here), and
3. the **organizational genome** — the whole model, abstracted so it can be replanted in a new org for a new concept.

🔗 **Live:** https://year-of-ai.github.io/ · **How it grows:** [/orchestration/](https://year-of-ai.github.io/orchestration/) · **Self-improvement fleet:** [/self-improvement/](https://year-of-ai.github.io/self-improvement/) · **Full reference:** [ARCHITECTURE.md](ARCHITECTURE.md)

## How the site works

This is a thin Jekyll site. It **vendors no theme files** — it renders with the shared [zer0-mistakes](https://github.com/bamr87/zer0-mistakes) theme pulled in over [`remote_theme`](https://github.com/benbalter/jekyll-remote-theme):

```yaml
# _config.yml
remote_theme: "bamr87/zer0-mistakes"   # untagged — all 12 org sites track latest
```

Leaving it untagged is deliberate: every org site tracks the theme's latest `main`, so a theme fix reaches production without a bump PR in nine repos. The trade is that an upstream regression arrives just as fast — so theme bugs go **upstream** rather than getting pinned around. `_data/hub.yml` (`pages.theme_repo`) carries the same untagged value; re-roll member configs with `scripts/provision-org-sites.rb` to propagate it.

Production builds on **native GitHub Pages** ("deploy from branch" — `main`, `/`).

## How the org grows

The hub is the central orchestrator (ADR-0001): the year repos hold only their content + a Pages `_config.yml` + `.claude/` + `telemetry/`. Daily, `orchestrate.yml` refreshes the lineage ledger and dispatches `grow-lineage.yml` for the stalest members (cadence set in `lineage/policy.yml`); each tick stages the canonical framework + that year's seed into a checkout of the year repo, runs the 3-tier model escalation (Haiku draft → Sonnet expand → Opus enhance, with an API-key fallback), then publishes only new content + telemetry back. A self-improvement fleet (ADR-0003) of watcher workflows monitors builds, credentials, docs coverage, and the evolution ledger. Full explainer: [/orchestration/](https://year-of-ai.github.io/orchestration/); decisions: [`lineage/decisions/`](lineage/decisions/).

## Layout

| Path | What it is |
|---|---|
| `_config.yml` / `_config_dev.yml` | Production / local-dev configuration |
| `pages/` | Site content (home, hub + lineage dashboards, orchestration + self-improvement explainers, …) |
| `_data/` | Theme data (navigation, `ui-text`, skins, authors) + the hub registry (`hub.yml`) and generated dashboards (`hub_index.yml`, `lineage.yml`) + the fleet kill-switch (`fleet_pause.yml`) |
| `lineage/` | **Growth source of truth**: `seeds/<year>.md`, `policy.yml` (models + cadence), `framework/` (staged agent toolkit), `repo-template/`, `decisions/` (ADRs) |
| `genome/` | The org-model DNA (ADR-0004): manifest, schema, render/plant/verify tooling |
| `telemetry/` | Hub evolution ledger (`evolution.jsonl`, one record per grow run) |
| `scripts/` | Hub tooling — dashboards (`sync-hub-metadata.rb`, `sync-lineage-state.rb`), provisioning (`provision-org-sites.rb`), the planter (`plant-lineage.rb`), fleet health (`fleet-health.rb`), docs coverage (`docs-warden.rb`), content review (`content-review.rb`), front-matter repair (`normalize-front-matter-dates.rb`) |
| `templates/org-site/` | Scaffold the provisioner writes into each org repo |
| `templates/org-profile/` | The org profile README, staged for the `year-of-ai/.github` repo |
| `.github/workflows/` | The growth engine (`orchestrate`, `grow-lineage`), the fleet (`telemetry-ledger`, `fleet-health-watch`, `pages-deploy-sentinel`, `secret-expiry-watch`, `framework-pr-reviewer`, `docs-warden`, `genome-sync`), and content/site automation (`build-validation`, `hub-sync`, `ai-content-review`, `deploy-chat-proxy`, `codeql`, the weekly `site-quality-scan`) |

Everything the theme provides (`_layouts`, `_includes`, `_sass`, `assets/css`, JS, vendored Bootstrap, images) comes from `remote_theme` at build time and is not stored here.

## The content hub

`_data/hub.yml` is the registry of org repos. The dashboard at [`/hub/`](https://year-of-ai.github.io/hub/) and the year grid on the home page are generated from it:

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

[MIT](LICENSE). The zer0-mistakes theme is maintained at [bamr87/zer0-mistakes](https://github.com/bamr87/zer0-mistakes).
