# CLAUDE.md

<!-- kit: agent-context v0.4.0 -->

Guidance for AI coding agents (Claude Code, Copilot, Cursor) working in **ai-world-view.github.io**.

## What this repo is

`ai-world-view.github.io` is the **organization root site** for the `ai-world-view` org — a landing page plus a **content hub** that presents every other repo in the org (the country knowledge bases: `china`, `japan`, `north-korea`, `south-korea`, and growing — `_data/lineage.yml` is the live roster). The org's defining trait: content is written from the model's **own knowledge** — the AI's own world view — with **no web research** in the growth passes.

It is a **thin `remote_theme` consumer**, not a theme. It vendors **no** theme files: layouts, includes, sass, compiled CSS, JS, and vendored assets all come from [`bamr87/zer0-mistakes`](https://github.com/bamr87/zer0-mistakes) at build time via `remote_theme` (set in `_config.yml`). Production builds on **native GitHub Pages** ("deploy from branch": `main`, `/`), which runs only the whitelisted plugins — there are no custom `_plugins/` here.

> If you need to change a layout, include, or stylesheet, that lives in the
> **theme repo** (`bamr87/zer0-mistakes`), not here. This repo only holds
> content, data, config, and the org hub tooling.

This org was **planted from the organizational genome** maintained in the reference implementation, [`year-of-ai/year-of-ai.github.io`](https://github.com/year-of-ai/year-of-ai.github.io) (concept: years; 11 members). The genome tooling, the ADRs, and the complete architecture reference live **there**, not here — when the model itself is in question, consult the reference hub and keep this replant aligned with it.

## Theme + org context

This site is a `bamr87/zer0-mistakes` **remote-theme consumer** on a **floating pin** — `remote_theme: "bamr87/zer0-mistakes"` with no tag, in `_config.yml`, `_config_dev.yml`, and `_data/hub.yml` alike — so theme fixes land on the next build and theme bugs are fixed **upstream**, never patched or pinned around here (details under Layout, `_config.yml`). It is the **root site and central orchestrator of the `ai-world-view` GitHub org**: the country repos hold only content, and everything that grows them (seeds, policy, framework, the workflows) lives in this repo. It is **not** managed by the bamr87/bamr87 hub dash — there is no `_data/projects.yml` registry entry or submodule pointer to keep in step; its baseline files are the fleet kit's `CLAUDE.md` stamp above, `.claude/settings.json` (a read-only `git`/`gh` permission allowlist), and `fleet.manifest.yml` (this repo's AI lanes in the shared `fleet/v1` vocabulary; `provenance: derived`). Autonomy is gated in **two layers**, and both must permit a scheduled run: `_data/fleet_pause.yml` is the in-tree **emergency stop** (default running — `paused: true` halts every mutating lane at once), and the `*_ENABLED` **repository variables** are the opt-in **arming** switches (default off — the cron idles until a human sets one; the bot token cannot set variables, so no loop can arm itself; a `workflow_dispatch` always runs). Today's variables: `ORCHESTRATE_ENABLED` (the daily `orchestrate.yml` cron, and through it every `grow-lineage` / `plant-lineage` dispatch) and `SECRET_EXPIRY_WATCH_ENABLED` (the daily credential probe). Pure PR checks (`ai-content-review`, `framework-pr-reviewer`, `build-validation`, `docs-warden`'s gate) carry no arming switch on purpose — a paused fleet must still validate a human's PR. The two that call a model carry an **off** switch for the model pass alone (fleet harness standard, 2026-11-13): `AI_CONTENT_REVIEW_ENABLED` and `FRAMEWORK_PR_REVIEWER_ENABLED` are on while unset, and `false` stops the Claude tier while the deterministic checks keep running.

## The zer0 stack

This site consumes the zer0 stack: the `bamr87/zer0-mistakes` theme over `remote_theme` (floating, above), the `zer0-image-generator` gem for preview banners (`Gemfile`, `~> 0.4`, resolving 0.6.0) configured by the single `preview_images:` block in `_config.yml`, and zer0-CMS, which reads the root `zer0.json` (console dialect, `$schema` pointer). `zer0.json` lists one content folder, the loose `pages/*.md`, because none of the nine collections `_config.yml` declares exists on disk, and its required keys mirror `.github/config/frontmatter_schema.yml` `pages`. `.theme-overrides.yml` declares the theme files this repo forks (none). `scripts/generate-preview-images.sh` stays in front of the gem until a released gem resolves `provider: auto` itself (0.6.0 knows only openai, xai, stability, gemini and local). To check the contract, run `ruby -I rails/lib rails/bin/zer0-cms doctor /path/to/ai-world-view.github.io` from a zer0-CMS checkout, or dispatch `.github/workflows/zer0-doctor.yml` (weekly, report-only, `fail-on-error: false`; a thin caller of zer0-CMS's reusable workflow, inert until that workflow lands on zer0-CMS `main`).

## Layout

- `_config.yml` — production config. `remote_theme` is **unpinned by policy**
(`bamr87/zer0-mistakes`, no tag): every site in the fleet tracks the theme's latest `main`, so a theme fix reaches production without a bump PR in nine repos. There is no tag to maintain here, in `_config_dev.yml`, or in `_data/hub.yml pages.theme_repo` — keep all three tag-free. The trade is explicit: an upstream regression lands immediately, so the safety net is the `build-validation` gate on PRs plus `pages-deploy-sentinel` after deploy, and theme bugs go **upstream** rather than getting pinned around.
- `_config_dev.yml` — local-dev overrides (localhost, `unpublished: true`,
analytics off). It does **not** disable `remote_theme` — no theme files are vendored here to fall back to — it re-declares it, also untagged, so local previews and the `build-validation` gate render the same latest theme production serves.
- `pages/` — all content collections + standalone pages (`home.md`, `hub.md`, …).
- `_data/` — data the theme reads (`navigation/`, `ui-text.yml`, `theme_skins.yml`,
`theme_backgrounds.yml`, `authors.yml`, `landing.yml`, …) **plus** the hub: `hub.yml` (registry — members join via `auto_discover`; there is deliberately no manual repos list) and the generated `hub_index.yml` + `navigation/hub.yml`.
- `scripts/` — hub tooling (`sync-hub-metadata.rb`, `provision-org-sites.rb`,
`lib/hub.rb`), the lineage ledger refresher (`sync-lineage-state.rb`), the new-country planter (`plant-lineage.rb` — resumes an interrupted plant at any stage: an existing repo is refilled when its every file belongs to the plant surface (repo-template skeleton + the provisioner's scaffold) and refused when it has real content; run in CI after `gh auth setup-git` and with a git identity configured so its pushes and the provisioner's scaffold commit authenticate), the PR reviewer (`content-review.rb`), the docs-coverage engine (`docs-warden.rb`), the fleet-health digest (`fleet-health.rb`), the front-matter date normalizer (`normalize-front-matter-dates.rb` — the grow tick's publish gate and the fleet repair tool), and the **preview-banner pair** (`claude_svg_banner.py` — Claude authors a content-aware SVG banner per article, reusing the `zer0-image-generator` engine's sanitizer/writers; and `generate-preview-images.sh` — the fleet-standard wrapper that resolves the `preview_images.provider: auto` capability ladder. Both are vendored identically in the other fleet repos (lifehacker.dev, the year-of-ai hub) — keep the copies in sync).
- `lineage/` — the **centralized growth source of truth** (see below):
`seeds/<country>.md` (each country's concept + Evolution Log; today: `china.md`, `japan.md`, `north-korea.md`, `south-korea.md`), `seed-package/` (bootstrap kit), `repo-template/` (the country-repo skeleton the planter drops), `policy.yml` (model tiers + cadence
  + preview art direction), and `framework/` (the canonical agent toolkit staged
into a country repo per tick). Excluded from the Jekyll build. The design decisions (ADR-0001…0006) live in the reference hub's `lineage/decisions/`.
- `telemetry/` — the hub **evolution ledger** (`evolution.jsonl`, one record per grow run) + its `README.md`. Excluded from the Jekyll build.
- `templates/org-site/` — scaffold the provisioner writes into org repos.
- `templates/deploy/chat-proxy/` — Cloudflare Worker for the AI-chat widget.
There is no deploy workflow for it here yet; the widget is `ai_chat.enabled: false` until the proxy is actually deployed.
- `.github/workflows/` — content/site: `hub-sync.yml`, `ai-content-review.yml`,
`build-validation.yml` (the **pre-merge Jekyll build gate**: on PRs touching `pages/**`, `_data/**`, `_config*.yml`, `Gemfile*`, `assets/**` or `404.html` it runs the front-matter date check then `bundle exec jekyll build --config '_config.yml,_config_dev.yml'`. Read-only — it publishes nothing, so it deliberately carries **no** `fleet_pause` kill-switch: a paused fleet must still be able to validate a human's PR. It needs `JEKYLL_GITHUB_TOKEN` for the `remote_theme` download and `LANG: C.UTF-8` for the theme's SCSS); the **growth engine** `orchestrate.yml` (daily scheduler) + `grow-lineage.yml` (grows one country repo per dispatch, including the **Illustrate** SVG-banner step) + `plant-lineage.yml` (spawns ONE new tangential country repo; the DECIDE output is validated — incidental non-seed edits are discarded, the §8 heading normalized — before planting; auto mode is maturity-gated by `lineage/policy.yml` `spawn:` and dispatched by orchestrate; manual mode keeps the two-key confirm); and the **self-improvement fleet** (ADR-0003 doctrine, see the reference hub) `telemetry-ledger.yml` (evolution ledger), `framework-pr-reviewer.yml` (gates framework PRs), `docs-warden.yml` (doc coverage), `pages-deploy-sentinel.yml` (member site liveness), `secret-expiry-watch.yml` (daily auth-credential probe), `fleet-health-watch.yml` (daily ledger health digest), `codeql.yml` (security scan); plus the report-only `zer0-doctor.yml` (the weekly zer0 stack contract check — see The zer0 stack) and `site-quality-scan.yml` (the weekly live-site quality scan of the hub **and** every member: it calls the bamr87 hub's reusable `site-quality.yml@v2` in `mode: url` per site, graded by the report-only `.github/site-quality.yml`, and keeps exactly one fingerprinted issue per site, found with the same jq title/marker lookup as `pages-deploy-sentinel`; it reads the `fleet_pause` kill-switch because it writes issues); and the **fleet-kit thin callers**, seeded from and owned by the bamr87/bamr87 hub's kits (`templates/`) — change them there, never in the copy here: `ci.yml` (the hub's standard CI: stack auto-detect, which here means the Jekyll build), `conformance.yml` (Universal Project Standard conformance, advisory), `verify.yml` (validates `features/features.yml` and runs `verify/scenarios/` with an evidence bundle; the `verify` label adds an optional Claude Code pass), `release.yml` (release-please, which writes `CHANGELOG.md`) and `claude.yml` (the `@claude` mention handler from the agent-context kit).
- `.github/config/` — reviewer configs: `content_review.yml`, `content_rules.yml`, `frontmatter_schema.yml`, `environment.yml`, `docs_warden.yml` (doc-coverage map).
- `_data/fleet_pause.yml` — the global growth **kill-switch** (the in-tree emergency stop; the opt-in arming layer is the `*_ENABLED` repository variables — see Theme + org context).
- `fleet.manifest.yml` — this repo's AI-lane inventory in the shared `fleet/v1` vocabulary (`provenance: derived`; each lane's `switch:` names its arming variable). `.claude/settings.json` — the fleet-kit read-only permission allowlist; `.claude/agents/content-reviewer.md` — the `ai-content-review` tier-2 agent.

## The lineage growth engine

The hub is the **central orchestrator** for the org's self-growing knowledge bases. The country repos (`china`, `japan`, `north-korea`, `south-korea`, and growing) hold **only** their content + a GitHub Pages `_config.yml` + `.claude/` + `telemetry/`. Everything that *grows* them lives here in the hub:

- **Seeds** are centralized — `lineage/seeds/<country>.md` holds each country's
concept (subject, taxonomy, conventions) and its **Evolution Log** (§8, the tick clock). The country repos do not carry their own `seed.md` source of truth. Every seed's `source_strategy` is the org's defining rule: **write from the model's own knowledge — no web sources, no fetch, no search**.
- **Policy** is centralized — `lineage/policy.yml` sets the 3-tier model
escalation, the perpetual-growth rules, the `preview:` art direction for the SVG banners, and the **spawn gate** (`spawn:` — enabled/frontier_ticks/max_members). Every tick is a grow tick: repos are **never** consolidated, archived, or deleted; new countries spawn tangentially from the frontier — **automatically** (year-of-ai ADR-0007): once every member has logged `spawn.frontier_ticks` growth cycles and the roster is under `spawn.max_members`, orchestrate dispatches `plant-lineage.yml`, whose DECIDE pass authors a tangential country seed (adjacent geography / strong ties, from the model's own knowledge — no web) and whose planter (`plant-lineage.rb`) creates the member repo. The manual two-key path (`--apply --confirm <id>`) remains as override/recovery.
- **The framework** is centralized — `lineage/framework/` is the canonical agent
toolkit (`prompts/`, `skills/`, `agents/`, `scripts/`, a reference `workflows/grow.yml`) staged into a cloned country repo at tick time, then stripped before publish so the country repo stays clean.

How a tick runs:

1. `orchestrate.yml` (daily cron `30 5 * * *`) refreshes `_data/lineage.yml` from
the seeds via `sync-lineage-state.rb`, then dispatches `grow-lineage.yml` for the **`cadence.repos_per_run` stalest members** (from `lineage/policy.yml`; 0 = every member every day).
2. `grow-lineage.yml` first runs a **gate job** (fleet kill-switch + input
validation), then checks out the target country repo, stages `lineage/framework/*` (minus the dead peer-to-peer surfaces) + `lineage/seeds/<repo>.md`, and runs the **3-tier escalation** (`claude-haiku-5-5` draft → `claude-sonnet-5-5` expand → `claude-opus-5-5` enhance) — every pass writing from the model's own world view, never the web. An **API-key fallback** pass fires if the OAuth passes produce no content changes or report `is_error`.
3. The **Illustrate** step banners each new article with a Claude-authored
SVG preview (`scripts/claude_svg_banner.py`; art direction + model from `lineage/policy.yml` `preview:`; degrades to the engine's deterministic `local` SVG without a credential, never blocks a publish). The updated seed §8 is persisted back to `lineage/seeds/<repo>.md`; the staged framework/seed are stripped, front-matter dates are normalized to ISO (`scripts/normalize-front-matter-dates.rb` — an unparseable `date:` fails a member's whole Pages build), and **only** new content + telemetry are pushed to the country repo. A tick that publishes nothing fails loudly (auth/setup failure vs stalled growth).

**Auth (org secrets):** `CLAUDE_CODE_OAUTH_TOKEN` (primary model auth), `ANTHROPIC_API_KEY` (fallback), `LIFECYCLE_PAT` (cross-repo push + workflow dispatch). Re-minting `CLAUDE_CODE_OAUTH_TOKEN` is the owner's job; the procedure and its log are [`docs/SECRET-ROTATION.md`](docs/SECRET-ROTATION.md). The model values come from `lineage/policy.yml`, not the workflow — change tiers there. Use authoritative model IDs (`claude-haiku-5-5`, `claude-sonnet-5-5`, `claude-opus-5-5`).

**Fleet harness standard (2026-11-13):** the five workflows that reach a model (`grow-lineage`, `plant-lineage`, `secret-expiry-watch`, `ai-content-review`, `framework-pr-reviewer`) are built to the bamr87 fleet's harness standard (`harnesses.standard` in bamr87/bamr87 `_data/fleet.yml`). The credential order is the `CLAUDE_AUTH_ORDER` repository variable; unset means `oauth,api_key`, the primary and fallback named above. The three `claude-code-action` workflows choose the credential with the hub's `claude-auth` step, and the two PR reviewers call the hub's `claude-run` action, which also retries a refused credential on the next method. The grow tick's fallback pass takes the next method the order names, so a method the order leaves out is never spent, and `secret-expiry-watch` probes the credential the order selects and names it in its report. Every model call has a dollar cap (`--max-budget-usd`) beside its turn cap: 15, 15 and 20 for the three tiers, 25 for the fallback pass, 10 for the DECIDE pass, the probe and each reviewer. Every model job has `timeout-minutes`: 120 for the grow job, 30 for the planter, 10 for the probe, and the 15 and 12 the reviewers already had. A cap is a guardrail: change it in the workflow that carries it, with a dated note.

## Stack & commands

```bash
# Local preview (fetches the theme over the network — set a token to avoid limits)
export JEKYLL_GITHUB_TOKEN=$(gh auth token)
docker compose up                       # http://localhost:4000, live reload
bundle exec jekyll serve --config '_config.yml,_config_dev.yml'   # non-Docker

# Validate a build (theme is remote, so a network fetch happens).
# This is exactly what .github/workflows/build-validation.yml runs on every PR.
bundle exec jekyll build --config '_config.yml,_config_dev.yml'
# Sandboxed / minimal shells: system-gem installs need BUNDLE_PATH=<scratch>/bundle,
# and the theme's SCSS needs a UTF-8 locale — export LC_ALL=C.UTF-8 (or
# en_US.UTF-8 where that locale is generated). Without it the build dies with
# `Invalid US-ASCII character "\xE2"` inside the theme's _sass.
# The Gemfile pins `github-pages "~> 232"` on purpose: unpinned, bundler resolves
# back to github-pages 222 (jekyll 3.9 + liquid 4.0.3), whose taint check raises
# `undefined method 'tainted?'` on Ruby >= 3.2 — the build cannot run at all.

# Content hub
ruby scripts/sync-hub-metadata.rb            # refresh dashboard data from _data/hub.yml
ruby scripts/sync-hub-metadata.rb --check    # CI gate (no writes)
ruby scripts/provision-org-sites.rb          # scaffold/enable Pages on org repos

# Lineage growth engine
ruby scripts/sync-lineage-state.rb           # refresh _data/lineage.yml from lineage/seeds/*
ruby scripts/sync-lineage-state.rb --check   # CI gate (no writes)

# Fleet repair
ruby scripts/normalize-front-matter-dates.rb --check <dir>  # find unparseable/bad front-matter dates
ruby scripts/normalize-front-matter-dates.rb --fix <dir>    # normalize to ISO (the grow tick's publish gate)

# Preview banners (the grow tick's Illustrate step, runnable by hand)
python3 scripts/claude_svg_banner.py --changed --dry-run    # preview banners for new/modified articles
./scripts/generate-preview-images.sh --list-missing         # the provider-ladder wrapper

# Lint
yamllint -c .github/config/.yamllint.yml _config.yml _config_dev.yml _data
ruby scripts/content-review.rb --help        # the PR content reviewer
```

## Conventions

- Conventional Commits: `type(scope): description`. This history is overwhelmingly the bots' `chore(<scope>)` (`chore(lineage)`, `chore(telemetry)`, `chore(hub)`), plus `feat` / `fix` from humans, `content:` for the grow tick's publish commit into a member repo, and `ci(deps)` from Dependabot. Nothing lints messages, so this list describes practice rather than gating it — keep it true when you add a lane.
- Default branch is `main` — branch from it and open a PR; never push to it directly. The bot lanes are the one documented exception (see Standard deviations).
- README-First, README-Last: read the nearest `README.md` before changing a directory, and update it after.
- Don't suppress type errors (`as any`, `@ts-ignore`, `# type: ignore`) or leave empty exception handlers; the workflows' `rescue nil` / `rescue {}` probes are deliberate fallbacks, not swallowed errors — keep them commented as such.
- Never weaken a guardrail as a drive-by: a kill-switch, `*_ENABLED` gate, gate job, concurrency group, two-key confirm, or the no-web rule changes only with a dated note in the file that carries it.

1. **Make minimal, surgical changes.** This is a content site; match existing front-matter and Liquid patterns in `pages/`.
2. **Don't add theme files.** No `_layouts/`, `_includes/`, `_sass/`, or
`_plugins/` belong here — change the theme upstream and it arrives here on its next build. **Never pin `remote_theme` to a tag**: the fleet tracks the theme's latest `main` by policy, in `_config.yml`, `_config_dev.yml`, and `_data/hub.yml` alike. A local fork or a pin to dodge an upstream bug is not a fix — file it upstream.
3. **`_data/` is the theme's runtime contract.** `remote_theme` does not supply
`_data`; the theme's layouts/includes read `site.data.*` (navigation, `ui-text`, skins, …). Don't delete these.
4. **Hub data is generated.** Edit `_data/hub.yml` (the registry — keep it on
`auto_discover`; don't add a manual repos list); never hand-edit `_data/hub_index.yml` or `_data/navigation/hub.yml` — regenerate them. Likewise `_data/lineage.yml` is generated from `lineage/seeds/*` — edit the seeds (and `lineage/policy.yml` for model tiers/cadence/preview), then regenerate.
5. **Root docs are excluded from the build** (`README.md`, `CLAUDE.md`) — the
homepage is `pages/home.md`; keep README from colliding at `/`. The exclude list is duplicated in `_config_dev.yml` (Jekyll replaces, not merges, `exclude:`).
6. **Front-matter `date:` values are single plain ISO dates** (`YYYY-MM-DD`) —
never ranges, bare years, or prose. One bad date fails a member's whole Pages build (this took a member site down for six days in the reference fleet). `scripts/normalize-front-matter-dates.rb` is the gate and the repair tool.
7. **Validate before declaring done.** Run a Jekyll build for any content/config
change; run `scripts/sync-hub-metadata.rb --check` for hub changes and `sync-lineage-state.rb --check` for lineage changes.
8. **Serialize writers (ADR-0003 kill-switch/serializer doctrine — see the
reference hub).** Any new workflow/agent that writes a **country repo's `main`** must use `concurrency.group: repo-write-<repo>` (the group `grow-lineage.yml` holds), so two writers never race the branch. Every dispatching/mutating workflow reads `_data/fleet_pause.yml` first (the kill-switch) — `orchestrate`, `grow-lineage` (gate job), `hub-sync`, and the fleet watchers all do; keep that true for anything new. Hub-`main` pushers must retry with rebase (seed persists, the telemetry ledger, and the dashboards all commit to hub main). `framework-mutation` / `policy-mutation` concurrency groups are the *convention* for any future workflow that mutates those surfaces via PR — no current workflow writes them, so the groups exist only as doctrine.
9. **The world view is the concept.** Growth passes write from the model's own
knowledge — never add web research, fetch, or search to the grow tick or the seeds' `source_strategy`. That constraint is the org's identity, not an implementation shortcut.
10. **The preview ladder is fleet-shared.** `scripts/generate-preview-images.sh` resolves the `preview_images.provider: auto` capability ladder and `scripts/claude_svg_banner.py` is its `claude` rung. Both files are vendored identically across the fleet repos — fix bugs in lockstep, never fork the copies.

## Standard deviations

- **Bot lanes commit to hub `main` directly** instead of branch + PR: `orchestrate.yml` (the lineage ledger), `hub-sync.yml` (dashboard data), `telemetry-ledger.yml` (the evolution ledger), `grow-lineage.yml` (each seed's Evolution Log) and `plant-lineage.yml` (a newly planted seed) all `git push origin HEAD:main` with rebase-retry. Deliberate: these are generated ledgers under the ADR-0003 serializer doctrine (Conventions rule 8), and a PR per tick would only add a human click to data no human edits. Human and agent changes still go through a PR.

## Known gaps and drift (audited 2026-08-18)

Recorded here on purpose: each is a real gap a future session should not have to re-discover. Fixing any of them is its own change, not a drive-by.

- **Members still carry the old pin until they are re-rolled.** The hub is now
tag-free in all three places, but `_data/hub.yml pages.theme_repo` is the value `provision-org-sites.rb` stamps into each member's `_config.yml` — so every member repo keeps whatever tag it was last provisioned with until the provisioner runs. Run `ruby scripts/provision-org-sites.rb` to propagate the untagged value, then watch `pages-deploy-sentinel` (it now checks the hub as well as every member) for the next hour.
- **Nothing here builds against the theme on a schedule.** With the pin gone, an
upstream regression reaches production on the member's next build. The `build-validation` gate only fires on PRs touching this repo, so a theme-only break is invisible until it ships. lifehacker.dev's `nightly.yml` — a daily rebuild against a fresh, uncached theme clone — is the fleet's proven pattern for this and is worth copying here.
- **No `CODEOWNERS` and no pull-request template.** Neither exists anywhere in
the repo (checked `/`, `.github/`, `docs/`). Nothing enforces review on the high-blast-radius surfaces — `lineage/policy.yml` (model tiers drive every tick), `lineage/framework/**` (staged into member repos), `_data/hub.yml` (re-rolls members), and `.github/workflows/**` (hold the org secrets). The fleet's own doctrine assumes a human gate on those; today it is convention only. Adding them is a governance decision for the org owner, so this note is the record, not a to-do executed silently.
