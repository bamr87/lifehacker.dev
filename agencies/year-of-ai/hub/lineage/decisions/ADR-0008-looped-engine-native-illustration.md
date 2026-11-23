# ADR-0008: Looped, engine-native banner illustration

**Status:** Proposed **Date:** 2026-10-19 **Deciders:** Repo owner (@bamr87) **Plan:** [ADR-0008-illustrate-v2-plan.md](ADR-0008-illustrate-v2-plan.md) (the review, design and phases this decision comes from) **Depends on:** [ADR-0003](ADR-0003-self-improving-agent-fleet.md) (the self-improvement fleet that watches the telemetry), [ADR-0006](ADR-0006-operational-hardening-and-cadence.md) (degrade-never-block publish gates)

## Context

The grow tick's Illustrate step authors SVG banners one-shot with no render, lint, or review, through a hub-vendored script (`scripts/claude_svg_banner.py` + the `generate-preview-images.sh` ladder) that contradicts the engine's own authoring rules (the hub brief asks for headline `<text>`, the engine's provider forbids it) and violates the zer0 stack contract ("no copied Python or bash generators"). The engine, `zer0-image-generator`, has carried a complete authoring loop since 0.6.0 and a native `claude` provider since 0.8.0, used only interactively. The baseline audit ([`_reports/banners-baseline.md`](../../_reports/banners-baseline.md), `scripts/audit-banners.rb`) measures the cost of that: the defects are exactly the ones a perception loop catches on the first pass — fonts that resolve differently per viewer, mid-word manual wraps, infographics that turn to mush at card size, filters committed unrendered, and no quality signal for the fleet to watch.

## Decision

The engine's `claude` provider becomes a **plan → author → shape → look → critique** loop with policy-controlled rounds and a strict-lint gate; text is authored as `<text>` and converted to paths at commit; style cards and era palettes replace the prose style string; each banner emits a telemetry record the self-improvement fleet watches. The hub consumes this through the gem only and deletes its vendored companion.

1. **D1 — the engine owns the loop; the hub only calls it.** The hub's Illustrate step becomes one engine invocation (`--changed --provider auto`), its policy keys mapped onto the engine's `preview_images` settings. `claude_svg_banner.py` and the ladder in `generate-preview-images.sh` are deleted; lifehacker.dev and the ai-world-view hub follow.
2. **D2 — text is allowed in, converted on the way out**, with fonts bundled in the gem (Press Start 2P for `retro-pixel`, Inter otherwise; OFL). Strict lint keeps its no-`<text>` rule; the committed file is font-independent.
3. **D3 — style cards replace the prose style string** (`preview.style_card`); the prose `style` stays as fallback and modifiers.
4. **D4 — era palettes are policy** (`preview.palettes`, year ranges → six tokens), resolved per member by the grow tick.
5. **D5 — sprite mode** (`author_mode: sprite`, the generator assembles Claude's sprite sheet) ships after the loop, not with it.
6. **D6 — banners get telemetry** (`telemetry/banners.jsonl`, schema `banner/v1`), and `site-quality-scan` watches it.
7. **D7 — degrade, never block, but never ship broken.** Strict lint gates the *banner*, not the tick: a banner that fails after its fix round is replaced by the `local` generator's output.

## Consequences

- ~3–4× model calls per banner at `rounds: 1` (plan, author, critique, at most one edit + re-critique), bounded by `preview.cost_cap_usd_per_tick` (the engine's run-wide `claude_budget_usd`, shared across workers).
- A rasterizer on the runner (`npm i -g @resvg/resvg-js-cli`), used to LOOK — the hub keeps committing SVG (`rasterizer: none`); the loop's `look_rasterizer` is independent of the output format.
- Banners that are font-independent, lint-clean, and seen at thumbnail size before they ship; one code path for dev and prod, so the two cannot drift again.
- **Rollback** is `preview.rounds: 0` (one authored draft, shaped and linted, never rendered or reviewed) without a code change, and `preview.enabled: false` returns to the `local` art.

## Implementation notes (where the build departs from the plan's draft)

Recorded so a later reader does not mistake a deliberate change for drift.

- **Where the engine lives.** zer0-CMS [ADR 0002](https://github.com/bamr87/zer0-CMS) (2026-10-19) made the zer0-CMS monorepo the only home of the zer0 stack and archived `bamr87/zer0-image-generator`; the engine is `packages/zer0-image-generator`, released from zer0-CMS with a component-prefixed tag. Phase 1 is a zer0-CMS PR, not a PR in the archived repo.
- **No fontTools.** The engine is stdlib-only by policy and its Ruby port is byte-pinned, so text→paths uses a ~250-line stdlib TrueType reader (cmap 4, glyf/loca simple + composite, hmtx) in both languages. fontTools is only a dev-time tool for regenerating the Inter subsets. Press Start 2P ships unmodified: its OFL reserves the font name, so it is not subset.
- **Headline layout is computed, not guessed.** Before authoring, `fit_headline` breaks the title at word boundaries with the real font metrics (never mid-word), caps the block at 30% of the frame, and gives the author exact lines, size and baselines; an overlong line is scaled to fit at conversion time.
- **Edit rounds revise the pre-outline source.** Each shaped draft keeps its sanitized source with live `<text>`; the editor revises that, not glyph paths (found in the first live run, where the critic's "make the title readable at 120px" could only be answered by scaling a path soup).
- **Telemetry goes to a file** (`--telemetry PATH`, `-` for stdout), not interleaved with the engine's log on stdout.
- **No svgo in `finish_svg`.** A deterministic precision pass (`round_svg_precision`) does the size work svgo would, without a network fetch per banner; svgo stays an option in the dev forge.
- **Two new engine verbs** serve the hub tooling and the dev loop: `--inspect SVG [--critic]` (the loop's strict lint and critic over an existing banner — what `audit-banners.rb` and `reillustrate.rb` call) and `--shape SVG` (the loop's SHAPE step in place — what `svg-forge.js` finalizes through).
