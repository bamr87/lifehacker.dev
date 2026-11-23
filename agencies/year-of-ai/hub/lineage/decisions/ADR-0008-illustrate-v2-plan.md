# Illustrate v2 — closing the loop on year-of-ai banner art

**Scope:** year-of-ai hub (`year-of-ai.github.io`), the 11 year repos, and the engine they consume (`bamr87/zer0-image-generator`). **Status:** proposed · 2026-10-19 **Companion ADR:** ADR-0008 (draft text at the end of this document)

---

## 1. What the review found

### The org, in one paragraph

The hub is the growth engine for a federated set of year repos (1776–1778, 2005–2012). Daily, `orchestrate.yml` picks the 4 stalest members and runs `grow-lineage.yml` against each: a 3-tier model escalation (Haiku → Sonnet → Opus) writes content, then a deterministic **Illustrate** step gives every new article an SVG preview banner, then the tick publishes. Art direction lives in `lineage/policy.yml` under `preview:` (one prose style string, "retro pixel art…"). Banners are committed as `assets/images/previews/<slug>.svg` and stamped into `preview:` front matter; the zer0-mistakes theme renders them as cover art and `og:image`.

### Where the banners come from today

```
grow-lineage.yml ─▶ Illustrate step
                      │
                      ├─ Claude credential?  ──▶ scripts/claude_svg_banner.py   (hub-vendored)
                      │                            one Messages call, Sonnet, effort=low
                      │                            allows <text>, asks for headline text
                      │                            no render, no review, no lint
                      │
                      └─ no credential       ──▶ engine `local` provider (deterministic template)
```

Meanwhile the engine (0.9.0, released Oct 7) carries a **second, better** Claude path that production never calls:

| Engine capability (zer0-image-generator) | Since | Used by the grow tick? |
| --- | --- | --- |
| Native `claude` SVG provider + `auto` capability ladder | 0.8.0 | No — hub still vendors its own companion script |
| `svg/lint.rb` (viewBox, dangling refs, rasters, precision, size) | 0.6.0 | No |
| Vision review (`complete_vision` + `REVIEWER_SYSTEM`) | 0.5.0 | No — gated to `kind in (png, jpg)`; fleet runs `rasterizer: none` |
| `.claude/workflows/svg-forge.js` — parallel drafts → critic → refine rounds → strict lint | 0.6.0 | No — interactive Claude Code workflow, hard-codes `/Users/bamr87/...` |
| Style cards (`tools/svg/library/styles/retro-pixel.md`, flat-geometric, mono-line) | 0.6.0 | No — policy carries a prose string instead |
| `pixel_kit` (ASCII-map sprites, integer grid, 6-token palettes, CRT veil) | 0.6.0 | No |
| Design tokens (`zer0-tokens.css`) | 0.9.0 | No |

The July svg-art-kit was adopted into the engine for the *development* loop (editing the engine's own generators). The *production* loop — the one that illustrates ~12 articles a day across the fleet — is still one-shot and blind.

### What that produces (sample: year-of-ai/2008, 35 banners)

Rendered four at full size and at 120px and read them:

- **Fonts are a coin flip.** 368 `<text>` elements across 35 files. The hub brief *asks* for headline text; the engine's own `claude` provider *forbids* it ("fonts will not resolve"). The two paths contradict each other. Result: "**B**EAR STEARNS" with a stray leading glyph overlapping the box; "CHAN-/DRAYA/AN-1" broken mid-syllable by manual wrapping.
- **The thumbnail test fails.** Chandrayaan-1 is an infographic — eleven lines of 9px mission stats. At card size it is a smear. Nothing in the pipeline ever looked at it small.
- **Filters are committed unrendered.** 24/35 banners use `<filter>` primitives; 34/35 use gradients. Nobody has verified how those render outside the browser the author happened to test in, because nothing renders them.
- **Quality is invisible to the fleet.** `telemetry/evolution.jsonl` records growth ticks. There is no record of banner quality, cost, or failures, so there is nothing for the self-improvement fleet (ADR-0003) to watch.

The honest summary: the banners are *good for one-shot*. The pixel aesthetic is consistent and the subject matter is specific. The defects are exactly the ones a perception loop catches on the first pass.

### Stack-contract drift

`docs/ZER0-STACK.md` (engine, decided 2026-09-14): a content repo consumes the engine through the gem and one `preview_images:` block — "no vendored `_plugins/preview_*` forks, no copied Python or bash generators." The hub's `scripts/claude_svg_banner.py` and `generate-preview-images.sh` ladder are that drift, with a note in their own docstrings saying to remove them once the engine grows native `auto` support. It did, in 0.8.0.

---

## 2. Design

### Principle

Keep what works (deterministic step, policy-over-workflow, degrade-never-block) and change one thing: **the model sees the banner before the tick commits it.**

```
article.md
   │
   ▼
[1] PLAN      Claude → JSON scene graph (palette tokens, focal point, 3-4 layers w/ roles)
   │
   ▼
[2] AUTHOR    Claude → SVG from plan + style card          (text allowed as <text>)
   │
   ▼
[3] SHAPE     engine: text→paths · sanitize · lint strict  (deterministic, no model)
   │   └─ lint fails ──▶ one targeted fix round, then fall back to `local`
   ▼
[4] LOOK      engine: rasterize 1536px + 120px (resvg)
   │
   ▼
[5] CRITIQUE  Claude vision → {works, fails[], next_change, overall, thumbnail_holds}
   │   └─ overall < threshold or !thumbnail_holds ──▶ [2'] edit round with critique (max N)
   ▼
[6] COMMIT    best-of by score · stamp front matter · emit telemetry record
```

Steps 3, 4, 6 are deterministic. Steps 1, 2, 5 are model calls. One banner at the default `rounds: 1` costs three calls (plan, author, critique) plus at most one edit round — roughly 3–4× today's single call, all on Sonnet. Policy caps it.

### Decisions

**D1 — The engine owns the loop; the hub only calls it.** Everything in the diagram lands in `zer0-image-generator`'s `claude` provider behind settings. The hub deletes its companion script and the bash ladder. lifehacker.dev and ai-world-view (which vendor identical copies) follow.

**D2 — Text is allowed in, converted on the way out.** Claude lays out text far better with `<text>` than by hand-authoring glyph paths, and the article title on the banner is the single most useful thing on it. So: authoring permits `<text>`; a new engine step converts every `<text>` to `<path>` using `fontTools` and a font *bundled in the gem* (one per style card — Press Start 2P for retro-pixel, Inter for flat-geometric, both OFL). Strict lint then holds its no-`<text>` rule and the committed file is font-independent. This resolves the contradiction between the two briefs instead of picking a side.

**D3 — Style cards replace the prose style string.** `preview.style_card: retro-pixel` resolves to the gem's `tools/svg/library/styles/retro-pixel.md` (constraints + seed recipes + palette tokens). The prose `style:` remains as a fallback and as free-text modifiers. Cards are what make eleven repos look like one org.

**D4 — Era palettes are policy, not prompt luck.** `preview.palettes:` in `lineage/policy.yml` maps year ranges to named token sets (1776–1778: parchment / iron-gall / vermilion; 2005–2012: the current CRT neon). The plan stage receives the palette for the member being grown. Later this becomes a Claude-Design-generated design system read from `zer0-tokens.css`; the key shape is the same.

**D5 — The deterministic generators scaffold; Claude draws the subject.** For the retro-pixel card, `pixel_kit` already does integer grids, ASCII-map sprites, and the CRT veil. The author step is changed so that Claude returns a *sprite sheet* (ASCII maps + a 6-token palette + a layout hint) and the generator assembles the banner. Overlap bugs, off-grid pixels, and misregistered frames disappear because the layout is code. This is the "generators for anything with math; hand-draw only the subject" rule applied to production. Ship it as an opt-in `author_mode: sprite` after the loop lands, not before.

**D6 — Banners get telemetry, and the fleet watches it.** Every banner appends one record to `telemetry/banners.jsonl` in the member repo (slug, model, rounds used, lint result, critic `overall`, `thumbnail_holds`, KB, tokens). `site-quality-scan` renders the week's banners into one contact sheet, posts it as a workflow artifact, and opens an issue when the rolling mean drops.

**D7 — Degrade, never block, but never ship broken.** Strict lint becomes a hard gate on the *banner*, not the tick: a banner that fails after its fix round is replaced by the `local` generator's output. A tick never publishes a banner with a dangling `url(#…)` or a raster payload.

---

## 3. Phases

### Phase 0 — Baseline (1 day, hub only)

- `scripts/audit-banners.rb --org year-of-ai`: clone each member shallow, render every banner at 600px and 120px (resvg via `npx @resvg/resvg-js-cli`; no gem changes needed), montage per repo, run the engine's `lint.rb --strict`, write `_reports/banners-baseline.md` with: count, % with `<text>`, % strict-clean, median KB, filter usage, plus a 20-banner critic sample scored by the engine's `complete_vision` with the forge `CRITIQUE_SCHEMA`.
- This is the before picture every later phase is measured against. KPIs: strict-clean %, mean critic `overall`, `thumbnail_holds` %, cost/banner.

### Phase 1 — The loop, engine side (engine PR, ~1 week)

`lib/zer0_image_generator/preview_generator.py` (Python oracle) and the Ruby port, byte-pinned as the repo requires:

1. `claude` provider: add `plan` stage (JSON scene graph; schema shipped as `svg/plan.schema.json`), author stage consumes it. Settings:
   `claude_plan: true|false`.
2. `svg/text_to_paths.py` + `.rb`: fontTools-based `<text>` → `<path>`; fonts bundled under `lib/zer0_image_generator/fonts/` with licenses. Setting
   `svg_text: paths|keep|forbid` (default `paths`).
3. Review gate: extend from `kind in (png, jpg)` to `svg` by rasterizing first; add a thumbnail render; replace `REVIEWER_SYSTEM`'s approve/revise with the forge `CRITIQUE_SCHEMA` for SVG (the raster providers keep the old prompt). Settings: `claude_rounds` (default 1), `claude_min_score` (default 7), `claude_require_thumbnail` (default true).
4. Edit round: on a failing critique, send the *current SVG* plus the critique and ask for a targeted edit, not a regeneration. Best-of by score across rounds.
5. Lint strict as a gate inside `finish_svg`; fallback to `local` on failure.
6. `svg-forge.js`: drop the hard-coded `ROOT`; make it call the same provider code path so dev and prod loops cannot drift again.
7. Tests: fixture article → plan JSON validates → authored SVG passes strict → critique JSON validates → telemetry record shape. Rasterizer in CI via `npx @resvg/resvg-js-cli` (Node is already on the runners).

Release as `0.10.0`.

### Phase 2 — Hub cutover (hub PR, 1–2 days after 0.10.0 ships)

1. Delete `scripts/claude_svg_banner.py`; strip the ladder from `generate-preview-images.sh` (it becomes a 10-line passthrough or goes).
2. `grow-lineage.yml` Illustrate step → `python3 "$ENGINE" --changed --provider auto --rasterizer auto` plus `npm i -g @resvg/resvg-js-cli` in the runner setup. Keep `continue-on-error: true` and the `.md.bak` sweep.
3. `lineage/policy.yml` `preview:` grows: `style_card`, `palettes`, `rounds`, `min_score`, `require_thumbnail`, `text: paths`, `cost_cap_usd_per_tick`. The workflow reads them with the existing Ruby one-liner pattern.
4. `templates/org-site/_config.yml.template`: `preview_images:` block gains the same keys; re-roll members with `provision-org-sites.rb`.
5. Mirror the deletion in lifehacker.dev and the ai-world-view hub (the docstring already names them as identical copies).
6. `CLAUDE.md` / `ARCHITECTURE.md` / `README.md`: Illustrate section rewritten; ADR-0008 added under `lineage/decisions/`.

### Phase 3 — Telemetry and the watcher (hub, ~2 days)

1. Engine emits one JSON line per banner on stdout with `--telemetry`; the Illustrate step appends it to `telemetry/banners.jsonl` in the member checkout (published with the tick like `evolution.jsonl`).
2. `telemetry-ledger.yml` learns the new file; `_data/lineage.yml` gets `banner_quality` per member for the hub dashboard.
3. `site-quality-scan.yml` (weekly): contact sheet of the week's banners as an artifact; opens/updates a "Banner quality" issue when 7-day mean `overall` < 6.5 or strict-clean < 95%.

### Phase 4 — Backfill (hub, runs over ~2 weeks unattended)

- `scripts/reillustrate.rb --worst-first --per-run 6`: from the Phase 0 audit and `banners.jsonl`, re-run the loop on banners that fail strict lint or score < 6, six per daily orchestrate run, as a separate job so it never competes with growth for the tick's budget. Stops itself when the backlog is empty.
- Per-year palettes land here (D4), so backfilled 1776–1778 banners stop wearing 2008's neon.

### Phase 5 — Sprite mode and the design system (engine + hub, later)

- D5 `author_mode: sprite` for the retro-pixel card.
- Claude Design: generate a design system from `zer0-mistakes` + `zer0-tokens.css`; export palette tokens into `preview.palettes`.
- Genome: add the `preview:` policy keys to `genome/schema.json` so a replanted org inherits looped illustration by default.

---

## 4. Cost and risk

| | Today | After (rounds: 1) |
| --- | --- | --- |
| Model calls / banner | 1 (Sonnet, effort low) | 3 + ≤1 edit (Sonnet; plan on Haiku is an option) |
| Vision input | none | 2 images (1536px + 120px) |
| Runner time / banner | ~10 s | ~45–70 s (two rasterizes + calls) |
| Banners / day (fleet) | ~8–15 | same; `cost_cap_usd_per_tick` guards |

- **Rasterizer parity.** resvg is the closest headless match to browsers and has an npx path; cairosvg mis-renders `feTurbulence`. Use resvg in CI; name it in the policy so a swap is a one-line change.
- **Text→paths file growth.** A titled banner grows ~20–60 KB. Raise the lint budget to 300 KB; run `svgo` in `finish_svg`.
- **Ruby port parity.** Every Python change has a byte-pinned Ruby twin; that is the engine's rule and the main reason Phase 1 is a week, not a day.
- **Rollback.** `preview.rounds: 0` returns to one-shot without a code change; `preview.enabled: false` returns to `local`.

---

## 5. Sequencing and ownership

1. Phase 0 can start now; it touches nothing that ships.
2. Phase 1 is the critical path and lives in the engine repo (release-please cuts 0.10.0).
3. Phases 2–3 are one hub PR each, behind the engine release.
4. Phase 4 is a scheduled job; Phase 5 is the next quarter.

A reasonable first PR to open today: Phase 0's audit script plus ADR-0008 as *proposed*, so the baseline numbers and the decision land together.

---

## Appendix — ADR-0008 (draft)

**Title:** Looped, engine-native banner illustration **Status:** Proposed · 2026-10-19 **Context:** The grow tick's Illustrate step authors SVG banners one-shot with no render, lint, or review, through a hub-vendored script that contradicts the engine's own authoring rules and violates the zer0 stack contract. The engine has carried a complete authoring loop since 0.6.0 and a native `claude` provider since 0.8.0, used only interactively. **Decision:** The engine's `claude` provider becomes a plan → author → shape → look → critique loop with policy-controlled rounds and a strict-lint gate; text is authored as `<text>` and converted to paths at commit; style cards and era palettes replace the prose style string; each banner emits a telemetry record the self-improvement fleet watches. The hub consumes this through the gem only and deletes its vendored companion. **Consequences:** ~3–4× model calls per banner, bounded by policy; a rasterizer on the runner; banners that are font-independent, lint-clean, and seen at thumbnail size before they ship; one code path for dev and prod so the two cannot drift again. Rollback is `preview.rounds: 0`.
