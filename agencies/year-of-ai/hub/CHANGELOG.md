# Changelog

All notable changes to **year-of-ai.github.io** (the org root site) are
documented here. The zer0-mistakes theme keeps its own changelog upstream at
[bamr87/zer0-mistakes](https://github.com/bamr87/zer0-mistakes).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- **Looped, engine-native banners (ADR-0008, Phases 2–4)**: the grow tick's
  Illustrate step is now ONE `zer0-image-generator` engine call over the
  tick's new content. From engine 0.10 the `claude` provider plans a scene
  graph, authors from the `retro-pixel` style card in the member's era
  palette (`lineage/policy.yml` `preview.palettes` — parchment for 1776–1778,
  CRT neon for 2005–2014), outlines the headline with a bundled font,
  strict-lints, looks at the banner at 1536px and 120px through resvg, and
  lets a vision critic drive up to `preview.rounds` edits; a banner that cannot
  be made clean ships the engine's `local` art. Older engines run one-shot.
  Every banner appends a banner/v1 record to the member's
  `telemetry/banners.jsonl`; `telemetry-ledger.yml` collects them into the
  hub's `telemetry/banners.jsonl`, `_data/lineage.yml` gains `banner_quality`
  per member, `site-quality-scan.yml` grows a weekly `banners` job (contact
  sheet + one auto-closing "Banner quality" issue against `preview.watch`), and
  `reillustrate.yml` + `scripts/reillustrate.rb` backfill the worst banners a
  few per day (orchestrate's `backfill` job, off until `REILLUSTRATE_ENABLED`).
  `scripts/lib/banners.rb` is the shared policy→engine map.
- **Banner baseline audit (ADR-0008 Phase 0)**: `scripts/audit-banners.rb`
  strict-lints every member's banners through the engine's `--inspect`,
  renders 600px/120px contact sheets, vision-critiques a seeded sample, and
  writes `_reports/banners-baseline.md` + JSON — the before picture every later
  phase is measured against.

### Removed
- `scripts/claude_svg_banner.py` (the hub-vendored banner companion) and the
  provider ladder in `scripts/generate-preview-images.sh` (now a 10-line engine
  locator): the engine carries both natively, as the zer0 stack contract
  requires. lifehacker.dev and the ai-world-view hub vendor the same copies and
  follow once engine 0.10 is published.

- **Weekly live-site quality scan (`.github/workflows/site-quality-scan.yml`)**:
  every Monday (and on demand) it scans the hub's own site and every member's
  live URL from `_data/lineage.yml` with the bamr87 hub's reusable
  `site-quality.yml@v1` in `mode: url` (Lighthouse CI, axe-core at 390 and
  1366 px, pa11y contrast). The config, `.github/site-quality.yml`, is
  report-only (`schema: site-quality/v1`), so no finding fails a scan. The
  workflow keeps exactly one issue per site, fingerprinted by a hidden marker
  and found with the same jq title/marker lookup the Pages sentinel uses since
  its duplicate-issue fix, over a paginated listing of every issue. It updates or
  reopens the issue while findings remain and closes it when the scan is
  clean. It honours the `_data/fleet_pause.yml` kill-switch. Both files are
  genome `transplant` (the workflow is in `default_plant_exclude`).
- **Pre-merge Jekyll build gate (`.github/workflows/build-validation.yml`)** —
  the repo had no workflow that compiled the site at all. Production publishes
  via native GitHub Pages "deploy from branch", so a broken Liquid template, an
  unparseable front-matter `date:`, or a bad `remote_theme` reference reached
  production with the hourly, after-the-fact `pages-deploy-sentinel` as the only
  signal. On any PR touching `pages/`, `_data/`, `_config*.yml`, `Gemfile*`,
  `assets/`, or the root content files, this runs
  `normalize-front-matter-dates.rb --check pages` and then
  `bundle exec jekyll build --config '_config.yml,_config_dev.yml'` with
  `JEKYLL_GITHUB_TOKEN` set (the remote theme is fetched through the GitHub API).
  Read-only: it compiles and discards, so it is exempt from the
  `_data/fleet_pause.yml` kill-switch and has no deploy step.
- **Maturity-gated automatic spawning (ADR-0007)** — the lineage now widens on
  its own, closing ADR-0002's deferred automation: when every member's
  Evolution Log shows at least `spawn.frontier_ticks` growth cycles (so the
  newest member has itself matured — stateless and self-regulating) and the
  roster is under `spawn.max_members`, the daily orchestrate run dispatches
  the new `plant-lineage.yml`. Its DECIDE pass (policy `distill` model)
  authors ONE tangential-era seed; the workflow accepts the model output only
  if it is exactly one valid new `lineage/seeds/<id>.md` and nothing else;
  the idempotent planter (`plant-lineage.rb`) creates the repo + Pages
  scaffold; the seed is committed to hub main only after the repo exists.
  Kill-switch honored; the gate is re-verified inside the workflow from a
  fresh checkout; the ADR-0002 manual two-key path is unchanged. The
  ai-world-view hub adopts the identical machinery with a country-tangent
  DECIDE prompt (its next member country will be planted automatically once
  `japan` and any siblings pass the gate). New `spawn:` block in
  `lineage/policy.yml`.

### Fixed
- **Deploy chat proxy no longer fails main when Cloudflare isn't set up**:
  `deploy-chat-proxy.yml` now checks for `CLOUDFLARE_API_TOKEN` and
  `CLOUDFLARE_ACCOUNT_ID` first and skips the Worker deploy with a notice when
  either is missing. Every run so far failed for that reason (only
  `ANTHROPIC_API_KEY` is set), while the AI-chat widget is disabled anyway.
- **Adversarial-review fixes for illustrated growth** (confirmed with executed
  reproductions): `claude_svg_banner.py` now re-illustrates a NEW article whose
  stamp is the shared section placeholder (previously the placeholder's
  existence skipped exactly the articles the Illustrate step exists for),
  skips no-front-matter files (README/TIMELINE/INDEX) before spending a model
  call, discovers articles inside brand-new directories (`--porcelain -uall`),
  survives non-ASCII filenames, and detects `role=` accessibly-quoted;
  `generate-preview-images.sh` refuses to route `--enhance` to the local
  provider's fake-success no-op and forwards style/output flags to the claude
  rung; `grow-lineage.yml`'s loud-failure gate now consults the `is_error`
  signal (an expired OAuth token was misdiagnosed as "growth stalled"), and
  its local-SVG fallback honours the policy output dir; the date gate covers
  `.markdown` files; the lineage dashboard's Ticks button points at the hub's
  grow-lineage runs (member repos carry no workflows under the central
  model); dangling theme-repo references removed from
  `content_review.yml`/`content-reviewer.md`.
- **The local/CI toolchain could not build the site at all.** `github-pages` was
  unpinned, and the explicit `jekyll-remote-theme` / `jekyll-include-cache` lines
  dragged resolution down to github-pages 222 (jekyll 3.9.0, liquid 4.0.3);
  liquid 4.0.3 calls `tainted?`, removed in Ruby 3.2, so every build on the
  documented Ruby 3.3 toolchain (`docker-compose.yml`) died with
  `undefined method 'tainted?' for false`. The Gemfile now pins
  `github-pages ~> 232` — the release GitHub Pages itself runs (jekyll 3.10.0,
  liquid 4.0.4) — and the build passes on Ruby 3.3.
- **`pages-deploy-sentinel.yml` never watched the hub's own site.** It iterated
  `_data/lineage.yml` members, and the hub is not a member, so the one workflow
  that answers "did the Pages build succeed and is the site live" was blind to
  the site it runs in. It now checks the hub first, derived from
  `$GITHUB_REPOSITORY` + `_config.yml` `url`/`baseurl` (never hard-coded), and
  requests `pages: read` so `github.token` can read the hub's own build status
  when `LIFECYCLE_PAT` is absent.
- **`_config_dev.yml` floated the theme on `HEAD`** (`bamr87/zer0-mistakes`,
  untagged) while `_config.yml` and `_data/hub.yml` pinned `@v1.26.0`. Jekyll
  layers the dev config last, so local previews — and the new build gate —
  rendered against a different theme than production serves. Now pinned to the
  same tag. Also removed a dead, unpinned `# remote_theme` comment left under
  `_config.yml`'s Style Settings, ~650 lines below the real declaration.
- `pages/contact.md`'s `date:` was a full ISO-8601 timestamp, which convention
  #6's gate (`normalize-front-matter-dates.rb`) reports as UNFIXABLE; normalized
  to a plain ISO date so the new gate starts green.

### Changed (comment noise)
- **PR review comments only speak when they have something to say**: the
  docs-warden and deterministic content-review stickies are no longer created
  on clean runs (they still flip an existing sticky to ✅ so a reported
  problem visibly resolves); the Claude content-reviewer runs **delta
  reviews** against its previous sticky (new/unresolved findings only, a
  one-line "no new findings" update otherwise) and never posts raw API/billing
  errors to the PR.

### Added
- **Illustrated growth — Claude-authored SVG preview banners** (fleet
  alignment with lifehacker.dev and the ai-world-view hub). The grow tick
  gained a deterministic **Illustrate** step (`grow-lineage.yml`): every
  new/changed article is bannered with a content-aware vector drawing that
  Claude authors via the new `scripts/claude_svg_banner.py` — a companion
  that imports the `zer0-image-generator` gem engine as a library and reuses
  its credential chain, SVG sanitizer, and front-matter writers. Art
  direction + authoring model live in `lineage/policy.yml` `preview:`
  (policy-over-workflow, like the model tiers); keyless runs degrade to the
  engine's deterministic `local` SVG; failures never block a publish. The
  hub's own pages get the same treatment via the new fleet-standard wrapper
  `scripts/generate-preview-images.sh` (resolves the `provider: auto`
  capability ladder the published engine doesn't know yet) and the
  `zer0-image-generator` gem in the `Gemfile`; `_config.yml preview_images:`
  now pins `rasterizer: none` (SVG-only) + `provider: auto`.

### Changed
- **`grow-lineage.yml` hardening back-ported from the ai-world-view hub**:
  the hub-owned-path exclusion is factored into one `HUB_OWNED_EXCLUDE_RE`
  env (was inlined twice), and a loud-failure gate now fails the run when a
  tick publishes nothing — distinguishing an auth/setup failure (all OAuth
  passes errored) from stalled growth — instead of reporting an empty tick
  GREEN.
- **Converted from a theme fork to a `remote_theme` consumer.** The repo no
  longer vendors the zer0-mistakes theme; it renders via
  `remote_theme: "bamr87/zer0-mistakes"` on the existing native GitHub Pages
  build. Deleted the entire vendored theme layer (`_layouts/`, `_includes/`,
  `_sass/`, `_plugins/`, and the theme `assets/` — ~296 MB, mostly generated
  preview images) plus the gem/Docker/test/installer toolchain, theme docs, and
  theme-CI workflows — the repo shrank from ~310 MB to ~3 MB. Verified the
  theme's `assets/css/main.css` still compiles and home/hub/search/wiki-links
  render identically under `remote_theme`.
  - `_config.yml` / `_config_dev.yml`: `remote_theme: false` → `bamr87/zer0-mistakes`;
    removed the local `gem`/`theme` keys (and the dangling `&gem` anchor);
    `README.md` excluded from the build in both configs.
  - `Gemfile`: reduced to the consumer set (`github-pages` + `jekyll-remote-theme`
    + `jekyll-include-cache` + `webrick`); `Gemfile.lock` is now generated
    locally, not committed.
  - `docker-compose.yml`: lean local-dev setup on a stock Ruby image that fetches
    the theme over the network.
  - Kept: all content (`pages/`, `index.html`, `404.html`, `favicon.ico`,
    `search.json`), the full `_data/` theme contract, `assets/data/`
    (`wiki-index.json` + notebook CSVs), the org hub tooling, the AI content
    reviewer, and the AI-chat proxy.
- **Repointed the org theme source.** `_data/hub.yml` `theme_repo` now points at
  `bamr87/zer0-mistakes`, so newly provisioned org year-sites consume the theme
  from upstream instead of from this repo.

### Added
- **Org Content Hub (federated).** A `/hub/` dashboard and home-page year grid
  that present every repo in the org, driven by the `_data/hub.yml` registry and
  the generated `_data/hub_index.yml` + `_data/navigation/hub.yml`
  (`scripts/sync-hub-metadata.rb`, daily `hub-sync` workflow).
- **Hub source-link fallback.** While a repo's Pages site is pending, the
  dashboard and home page link its sections and key pages to the GitHub source,
  auto-upgrading to the live site once Pages is enabled.

### Fixed
- **Org landing page shadowed by the theme README.** Removed the stale
  `permalink: /` from `README.md` and excluded it from the build so `/` reliably
  serves `pages/home.md`.
- **Hub listed the site itself as a content repo.** Corrected `exclude_repos` in
  `_data/hub.yml` (the fork is named `year-of-ai.github.io`, not `zer0-mistakes`);
  the dashboard now presents only the other org repos.
