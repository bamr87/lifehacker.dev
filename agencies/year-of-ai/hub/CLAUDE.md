# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

## What this repo is

`year-of-ai.github.io` is the **organization root site** for the `year-of-ai` org — a landing page plus a **content hub** that presents every other repo in the org (the year knowledge bases: 1776–1778 and 2005–2012, and growing).

It is a **thin `remote_theme` consumer**, not a theme. It vendors **no** theme files: layouts, includes, sass, compiled CSS, JS, and vendored assets all come from [`bamr87/zer0-mistakes`](https://github.com/bamr87/zer0-mistakes) at build time via `remote_theme` (set in `_config.yml`). Production builds on **native GitHub Pages** ("deploy from branch": `main`, `/`), which runs only the whitelisted plugins — there are no custom `_plugins/` here.

> If you need to change a layout, include, or stylesheet, that lives in the
> **theme repo** (`bamr87/zer0-mistakes`), not here. This repo only holds
> content, data, config, and the org hub tooling.

**[`ARCHITECTURE.md`](ARCHITECTURE.md) is the complete system reference** — rendering pipeline, tick anatomy, fleet, genome, failure modes, runbook, and invariants. This file is the operational quick-guide; when they disagree, read the architecture doc and fix the drift.

## Repository map

- `_config.yml` — production config. `remote_theme` is **untagged by policy** (`bamr87/zer0-mistakes`) — all 12 org sites track the theme's latest `main`, so a theme fix reaches production without a bump PR in nine repos. Keep it tag-free here, in `_config_dev.yml`, and in `_data/hub.yml pages.theme_repo` (the value `provision-org-sites.rb` stamps into every member). Supersedes ADR-0006 decision 5.
- `_config_dev.yml` — local-dev overrides (localhost, `unpublished: true`, analytics off, a slimmer `plugins:`/`collections:` set, `limit_posts`). It **also carries its own `remote_theme:` pin**, and Jekyll layers this file last, so *its* tag is the one local previews and the CI build gate actually render against — keep it identical to `_config.yml`'s or you are validating a different theme than production serves.
- `pages/` — all content collections + standalone pages (`home.md`, `hub.md`, …).
- `_data/` — data the theme reads (`navigation/`, `ui-text.yml`, `theme_skins.yml`, `theme_backgrounds.yml`, `authors.yml`, `landing.yml`, …) **plus** the hub: `hub.yml` (registry, source of truth) and the generated `hub_index.yml` + `navigation/hub.yml`.
- `scripts/` — hub tooling (`sync-hub-metadata.rb`, `provision-org-sites.rb`, `lib/hub.rb`), the lineage ledger refresher (`sync-lineage-state.rb`), the new-era planter (`plant-lineage.rb` — resumes an interrupted plant at any stage: an existing repo is refilled when its every file belongs to the plant surface (repo-template skeleton + the provisioner's scaffold) and refused when it has real content; run in CI after `gh auth setup-git` and with a git identity configured so its pushes and the provisioner's scaffold commit authenticate), the PR reviewer (`content-review.rb`), the docs-coverage engine (`docs-warden.rb`), the fleet-health digest (`fleet-health.rb`), the front-matter date normalizer (`normalize-front-matter-dates.rb` — the grow tick's publish gate and the fleet repair tool), the **news-layout migrator** (`migrate-to-news-structure.rb` — one-time conversion of a flat year repo to the theme's `news`/`section`/`article` layout: taxonomy categories become `/news/<slug>/` sections, topic files become posts, and post `tags` become each section's sub-topics; see `--help`), the **banner set** (ADR-0008 — the illustration loop itself lives in the `zer0-image-generator` gem, released from bamr87/zer0-CMS; the hub only calls it: `lib/banners.rb` maps `lineage/policy.yml` `preview:` onto engine flags, resolves each member's era palette and reads banner/v1 telemetry; `banner-quality.rb` is the weekly watcher; `reillustrate.rb` plans and runs the worst-first backfill; `generate-preview-images.sh` is a 10-line engine locator for the hub's own pages), and the **favicon minter** (`generate-favicon.rb` — writes a member's `favicon.ico` + `assets/images/favicon.svg` from its label, in pure stdlib Ruby because no runner in the fleet has a rasterizer. The theme's `core/favicon.html` links `/<repo>/favicon.ico` on every page and `remote_theme` ships only `_layouts`/`_includes`/`_sass`/`assets`, so a member that carries no favicon of its own 404s on it. Called by `provision-org-sites.rb` and `migrate-to-news-structure.rb`), and the **banner audit** (`audit-banners.rb` — ADR-0008 Phase 0: shallow-clones every member, strict-lints each preview banner through the engine's `--inspect`, renders 600px/120px contact sheets, vision-critiques a seeded sample, and writes `_reports/banners-baseline.md` + its JSON twin; needs zer0-image-generator ≥ 0.10 via `--engine`).
- `lineage/` — the **centralized growth source of truth** (see below): `seeds/<year>.md` (each year's concept + Evolution Log), `seed-package/` (bootstrap kit), `repo-template/` (the year-repo skeleton the planter drops), `policy.yml` (model tiers + cadence), `framework/` (the canonical agent toolkit staged into a year repo per tick), and `decisions/` (ADR-0001…0008). Excluded from the Jekyll build.
- `genome/` — the **abstracted org-model DNA** (ADR-0004): `genome.yml` (concept manifest) + `schema.json` + `manifest.yml` (transplant inventory) + `bin/` (`render.rb`/`plant.rb`/`verify.rb`) + `GENOME.md`. Replant the whole model in a new org for a new concept. Excluded from the Jekyll build.
- `telemetry/` — the hub **evolution ledger** (`evolution.jsonl`, one record per grow run), the **banner ledger** (`banners.jsonl`, one banner/v1 record per committed banner, ADR-0008) + its `README.md`. Excluded from the Jekyll build.
- `templates/org-site/` — scaffold the provisioner writes into org repos.
- `templates/org-profile/` — the org profile README, staged for the `year-of-ai/.github` repo (publish commands in its header comment).
- `templates/deploy/chat-proxy/` — Cloudflare Worker for the AI-chat widget (deploy secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, `ANTHROPIC_API_KEY`). The widget is `ai_chat.enabled: false` until this proxy is actually deployed.
- `.github/workflows/` — content/site: `build-validation.yml` (the **pre-merge Jekyll build gate** — compiles the site with `'_config.yml,_config_dev.yml'` on any PR touching content/data/config/assets, plus the front-matter date check; read-only, so it is exempt from the kill-switch and has no deploy step — Pages owns publishing), `hub-sync.yml`, `ai-content-review.yml`, `deploy-chat-proxy.yml`; the **growth engine** `orchestrate.yml` (daily scheduler) + `grow-lineage.yml` (grows one year repo per dispatch) + `plant-lineage.yml` (spawns ONE new tangential-era repo; the DECIDE output is validated — incidental non-seed edits are discarded, the §8 heading normalized — before planting; auto mode is maturity-gated by `lineage/policy.yml` `spawn:` and dispatched by orchestrate, ADR-0007; manual mode keeps the ADR-0002 two-key confirm); and the **banner backfill** `reillustrate.yml` (ADR-0008: re-illustrates one member's worst banners per dispatch, serialized on `repo-write-<repo>`; dispatched by orchestrate's `backfill` job, off until `REILLUSTRATE_ENABLED` is `true`); and the **self-improvement fleet** (ADR-0003) `telemetry-ledger.yml` (evolution + banner ledgers), `framework-pr-reviewer.yml` (gates framework PRs), `docs-warden.yml` (doc coverage; the weekly sweep files one drift issue and closes it once the census is clean), `pages-deploy-sentinel.yml` (Pages build + liveness for the hub's own site **and** every member), `secret-expiry-watch.yml` (daily auth-credential probe), `fleet-health-watch.yml` (daily ledger health digest), `genome-sync.yml` (genome drift gate), `codeql.yml` (security scan), `site-quality-scan.yml` (weekly live-site quality scan of the hub **and** every member: calls the bamr87 hub's reusable `site-quality.yml@v2` in `mode: url` per site, graded by the report-only `.github/site-quality.yml`, and keeps exactly one fingerprinted issue per site, using the sentinel's jq title/marker lookup); and the **fleet-kit thin callers**, seeded by the bamr87 hub's kits and owned there — change them in the kit, not here, or the next kit upgrade skips or overwrites the copy: `ci.yml` (the hub's `standard-ci.yml@v2` on every PR and push to `main`), `claude.yml` (the `@claude` mention handler, agent-context kit), `conformance.yml` (the hub's Universal Project Standard check, advisory with `gate: false`), `release.yml` (release-please through the hub's `release-please.yml@v2`; it is what writes `CHANGELOG.md`), and `verify.yml` (fleet-verify, verify kit: validates `features/features.yml`, runs `verify/scenarios/*.yml` per `verify/verify.yml` and uploads the evidence; advisory with `gate: false`).
- `.github/config/` — reviewer configs: `content_review.yml`, `content_rules.yml`, `frontmatter_schema.yml`, `environment.yml`, `docs_warden.yml` (doc-coverage map).
- `_data/fleet_pause.yml` — the global growth **kill-switch** (ADR-0003).
- `assets/data/` — site-owned data: `wiki-index.json` (Obsidian `[[wiki-links]]` index, a Liquid file built at render time) and notebook CSVs.

## The lineage growth engine

The hub is the **central orchestrator** for the org's self-growing knowledge bases. The year repos (`1776`–`1778`, `2005`–`2012`) hold **only** their content + a GitHub Pages `_config.yml` + `.claude/` + `telemetry/`. Everything that *grows* them lives here in the hub:

- **Seeds** are centralized — `lineage/seeds/<year>.md` holds each year's concept (subject, taxonomy, sources, conventions) and its **Evolution Log** (§8, the tick clock). The year repos no longer carry a `seed.md`.
- **Policy** is centralized — `lineage/policy.yml` sets the 3-tier model escalation, the perpetual-growth rules, and the **spawn gate** (`spawn:` — enabled/frontier_ticks/max_members). Every tick is a grow tick: repos are **never** consolidated, archived, or deleted; new eras spawn tangentially from the frontier — automatically, once every member has logged `spawn.frontier_ticks` growth cycles and the roster is under `spawn.max_members` (ADR-0007; orchestrate dispatches `plant-lineage.yml`, whose DECIDE pass authors the tangential seed and whose planter creates the repo).
- **The framework** is centralized — `lineage/framework/` is the canonical agent toolkit (`prompts/`, `skills/`, `agents/`, `scripts/`, a reference `workflows/grow.yml`) staged into a cloned year repo at tick time, then stripped before publish so the year repo stays clean.

How a tick runs:

1. `orchestrate.yml` (daily cron `30 5 * * *`) refreshes `_data/lineage.yml` from the seeds via `sync-lineage-state.rb`, then dispatches `grow-lineage.yml` for the **`cadence.repos_per_run` stalest members** (from `lineage/policy.yml`; 0 = every member every day).
2. `grow-lineage.yml` first runs a **gate job** (fleet kill-switch + input validation), then checks out the target year repo, stages `lineage/framework/*` (minus the dead peer-to-peer surfaces) + `lineage/seeds/<repo>.md`, and runs the **3-tier escalation** (`claude-haiku-5-5` draft → `claude-sonnet-5-5` expand → `claude-opus-5-5` enhance). An **API-key fallback** pass fires if the OAuth passes produce no content changes or report `is_error`.
3. The **Illustrate** step banners each new article through the `zer0-image-generator` engine's illustration loop (ADR-0008: plan → author → shape → look at 1536px + 120px → critique → edit; style card, rounds, era palette and cost cap from `lineage/policy.yml` `preview:`). A banner the loop cannot make strict-clean ships the engine's deterministic `local` art; it never blocks a publish, and each banner appends a banner/v1 record to the member's `telemetry/banners.jsonl`. Engines before 0.10 run one-shot until the gem is upgraded. The updated seed §8 is persisted back to `lineage/seeds/<repo>.md`; the staged framework/seed are stripped, front-matter dates are normalized to ISO (`scripts/normalize-front-matter-dates.rb` — an unparseable `date:` fails a member's whole Pages build), and **only** new content + telemetry are pushed to the year repo. A tick that publishes nothing fails loudly (auth/setup failure vs stalled growth).

**Auth (org secrets):** `CLAUDE_CODE_OAUTH_TOKEN` (primary model auth), `ANTHROPIC_API_KEY` (fallback), `LIFECYCLE_PAT` (cross-repo push + workflow dispatch). The model values come from `lineage/policy.yml`, not the workflow — change tiers there. Use authoritative model IDs (`claude-haiku-5-5`, `claude-sonnet-5-5`, `claude-opus-5-5`).

**Fleet harness standard (2026-11-13):** the five workflows that reach a model (`grow-lineage`, `plant-lineage`, `secret-expiry-watch`, `ai-content-review`, `framework-pr-reviewer`) are built to the bamr87 fleet's harness standard (`harnesses.standard` in bamr87/bamr87 `_data/fleet.yml`). The credential order is the `CLAUDE_AUTH_ORDER` repository variable; unset means `oauth,api_key`, the primary and fallback named above. The three `claude-code-action` workflows choose the credential with the hub's `claude-auth` step, and the two PR reviewers call the hub's `claude-run` action, which also retries a refused credential on the next method. The grow tick's fallback pass takes the next method the order names, so a method the order leaves out is never spent, and `secret-expiry-watch` probes the credential the order selects and names it in its report. Every model call has a dollar cap (`--max-budget-usd`) beside its turn cap: 15, 15 and 20 for the three tiers, 25 for the fallback pass, 10 for the DECIDE pass, the probe and each reviewer. Every model job has `timeout-minutes`: 120 for the grow job, 30 for the planter, 10 for the probe, and the 15 and 12 the reviewers already had. Three repository variables are off switches, on while unset: `AI_CONTENT_REVIEW_ENABLED` and `FRAMEWORK_PR_REVIEWER_ENABLED` stop the model pass of their PR check when set to `false` (the deterministic checks keep running), and `SECRET_EXPIRY_WATCH_ENABLED` stops the scheduled probe (a manual dispatch still runs).

## Common commands

```bash
# Local preview (fetches the theme over the network — set a token to avoid limits)
export JEKYLL_GITHUB_TOKEN=$(gh auth token)
docker compose up                       # http://localhost:4000, live reload
bundle exec jekyll serve --config '_config.yml,_config_dev.yml'   # non-Docker

# Validate a build (theme is remote, so a network fetch happens).
# This is exactly what .github/workflows/build-validation.yml runs on every PR.
bundle exec jekyll build --config '_config.yml,_config_dev.yml'
# Sandboxed / minimal shells: system-gem installs need BUNDLE_PATH=<scratch>/bundle,
# and SassC needs a UTF-8 locale — export LC_ALL=en_US.UTF-8 (or C.UTF-8 where
# en_US is not generated; without it SassC dies on the theme's UTF-8 SCSS).
# The Gemfile pins github-pages to the release Pages runs; leaving it unpinned
# resolves back to liquid 4.0.3, which crashes on Ruby >= 3.2 (`tainted?`).

# Content hub
ruby scripts/sync-hub-metadata.rb            # refresh dashboard data from _data/hub.yml
ruby scripts/sync-hub-metadata.rb --check    # CI gate (no writes)
ruby scripts/provision-org-sites.rb          # scaffold/enable Pages on org repos

# Lineage growth engine
ruby scripts/sync-lineage-state.rb           # refresh _data/lineage.yml from lineage/seeds/*
ruby scripts/sync-lineage-state.rb --check   # CI gate (no writes)

# News-layout migration (one-time, per year repo — pilot: 2005). The enrichment
# YAML (per-section icon/description/featured + per-article tags) lives in
# lineage/news-migration/<year>.yml; author one per member before migrating.
ruby scripts/migrate-to-news-structure.rb --repo <year-repo> --enrichment lineage/news-migration/2005.yml --year 2005 --dry-run
ruby scripts/migrate-to-news-structure.rb --repo <year-repo> --enrichment lineage/news-migration/2005.yml --year 2005

# Fleet repair / metadata
ruby scripts/normalize-front-matter-dates.rb --check <dir>  # find unparseable/bad front-matter dates
ruby scripts/normalize-front-matter-dates.rb --fix <dir>    # normalize to ISO (the grow tick's publish gate)
ruby scripts/sync-member-metadata.rb                        # dry-run member GitHub metadata vs the registry
ruby scripts/sync-member-metadata.rb --apply                # push description/homepage/topics to members
ruby scripts/generate-favicon.rb --repo <year-repo> --label <year> --dry-run
ruby scripts/generate-favicon.rb --repo <year-repo> --label <year>   # mint favicon.ico + favicon.svg

# Banner quality (ADR-0008) — needs zer0-image-generator >= 0.10 (--inspect)
ruby scripts/audit-banners.rb --engine <path>/preview_generator.py              # baseline: lint + renders + 20-banner critic
ruby scripts/audit-banners.rb --engine <path>/preview_generator.py --members 2008 --critic 0 --no-render   # quick lint-only pass
ruby scripts/banner-quality.rb                 # the weekly watcher's digest over telemetry/banners.jsonl
ruby scripts/reillustrate.rb --plan            # next backfill batch (worst first) + backlog size

# Lint
yamllint -c .github/config/.yamllint.yml _config.yml _config_dev.yml _data
ruby scripts/content-review.rb --help        # the PR content reviewer
```

## Conventions

1. **Make minimal, surgical changes.** This is a content site; match existing front-matter and Liquid patterns in `pages/`.
2. **Don't add theme files.** No `_layouts/`, `_includes/`, `_sass/`, or `_plugins/` belong here — change the theme upstream, release it, then bump the pinned `remote_theme` tag (in `_config.yml` AND `_data/hub.yml` together). Never float the theme on `HEAD`.
3. **`_data/` is the theme's runtime contract.** `remote_theme` does not supply `_data`; the theme's layouts/includes read `site.data.*` (navigation, `ui-text`, skins, …). Don't delete these.
4. **Hub data is generated.** Edit `_data/hub.yml` (the registry); never hand-edit `_data/hub_index.yml` or `_data/navigation/hub.yml` — regenerate them. Likewise `_data/lineage.yml` is generated from `lineage/seeds/*` — edit the seeds (and `lineage/policy.yml` for model tiers/cadence), then regenerate.
5. **Root docs are excluded from the build** (`README.md`, `ARCHITECTURE.md`, `CLAUDE.md`, `CHANGELOG.md`) — the homepage is `pages/home.md`; keep README from colliding at `/`. The exclude list is duplicated in `_config_dev.yml` (Jekyll replaces, not merges, `exclude:`).
6. **Front-matter `date:` values are single plain ISO dates** (`YYYY-MM-DD`) — never ranges, bare years, or prose. One bad date fails a member's whole Pages build (this took the 1777 site down for six days). `scripts/normalize-front-matter-dates.rb` is the gate and the repair tool.
7. **Validate before declaring done.** Run a Jekyll build for any content/config change; run `scripts/sync-hub-metadata.rb --check` for hub changes, `sync-lineage-state.rb --check` for lineage changes, and `ruby genome/bin/verify.rb` after adding files (every concept-bearing tracked file must be classified in `genome/manifest.yml`).
8. **Serialize writers (ADR-0003 repo-write-serializer).** Any new workflow/agent that writes a **year repo's `main`** must use `concurrency.group: repo-write-<repo>` (the group `grow-lineage.yml` holds), so two writers never race the branch. Every dispatching/mutating workflow reads `_data/fleet_pause.yml` first (the kill-switch) — `orchestrate`, `grow-lineage` (gate job), `hub-sync`, and the fleet watchers all do; keep that true for anything new. Hub-`main` pushers must retry with rebase (seed persists, the telemetry ledger, and the dashboards all commit to hub main). `framework-mutation` / `policy-mutation` concurrency groups are the *convention* for any future workflow that mutates those surfaces via PR — no current workflow writes them, so the groups exist only as doctrine. **Read-only workflows are exempt from the kill-switch** — `build-validation` compiles and discards, mutating nothing, and a paused fleet still wants its PRs checked. The exemption is "writes nothing anywhere", not "feels safe".

## Known gaps (recorded, not fixed)

Standing drift a maintainer owns. Update or delete an entry when it is resolved — a stale gap list is worse than none.

- **A planted member can miss the registry entirely.** `2013` exists in the org, publishes at `/2013/`, and has `lineage/seeds/2013.md` — but it is absent from `_data/hub.yml members`, so the hub dashboards never list it and `provision-org-sites.rb` never touches it. `_data/lineage.yml` *does* know it (that file is generated from the seeds), which is why the growth engine keeps feeding it while the hub stays blind. Adding the row and regenerating (`ruby scripts/sync-hub-metadata.rb`) fixes this instance; nothing yet *prevents* the next planted repo from drifting the same way — a check that diffs the org's repo list against `members` would.
- **Nothing builds against the theme on a schedule.** With no pin, an upstream regression reaches production on a member's next build, and the `build-validation` gate only fires on PRs touching this repo — so a theme-only break is invisible until it ships. lifehacker.dev's `nightly.yml` (daily rebuild against a fresh, uncached theme clone) is the fleet's proven pattern and is worth copying here.
- **A member's preview art can reference files that do not exist.** The article hero is guarded on `page.preview` being *set*, not on the file being *there*, so a stale path renders a broken full-width image rather than nothing. Four posts across 2006 and 2011 referenced article SVGs the Illustrate step never produced, and 2013 had six section placeholders written to `images/previews/` at the repo root instead of `assets/images/previews/` — front matter omits the `/assets` prefix and the theme restores it, so those nine posts resolved to nothing. All are repointed to their section placeholder, but nothing checks this: a member-side gate that resolves every `preview:` against the filesystem (the way `normalize-front-matter-dates.rb` gates dates) would catch it at the tick that introduces it.
- **Share cards still declare `summary`.** The theme's `content/seo.html` emits a landscape `twitter:image` from `page.preview`, but jekyll-seo-tag only reaches its `summary_large_image` branch when `page.image` is set, so it hardcodes `twitter:card: summary` and X/Twitter crops the 800×400 banner to a square thumbnail. `site.twitter.card` is never consulted on that path — setting it in a member config is inert. The fix belongs upstream in `bamr87/zer0-mistakes` (`content/seo.html` should emit `twitter:card` alongside the `twitter:image` it already writes), not here.
- **No CODEOWNERS anywhere.** The fleet's bots push straight to member repos and to this hub's `main`, and nothing routes review by path — an edit to `lineage/policy.yml`, `lineage/framework/`, or the workflows requests the same (i.e. no) reviewers as a prose fix. Ownership is a maintainer decision, so this file makes no claim about who should own what; adding `.github/CODEOWNERS` would give the mutating surfaces a named human, and branch protection would give it teeth.

## Governance

Read [`docs/constitution.md`](docs/constitution.md) before changing anything: it is the highest-precedence rule set here and wins over this file when they disagree. It changes only through a numbered record in [`docs/amendments/`](docs/amendments/), ratified by the maintainer merging the PR; agents propose, never merge. Every user-facing feature has a stable id in [`features/features.yml`](features/features.yml) with `status`, location and the PRD requirement ids it serves; the PRD's "Feature catalog" block is generated from it (`python3 <bamr87/bamr87>/tools/governance_lint.py prd-sync . --write`; check with `… check .`). Never hand-edit that block or `CHANGELOG.md`.
