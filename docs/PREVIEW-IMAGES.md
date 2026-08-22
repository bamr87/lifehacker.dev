# Preview images

How lifehacker.dev makes cover art. Philosophy: [TRACE-BLOOM.md](TRACE-BLOOM.md). Explorer: [`docs/preview-lab.html`](preview-lab.html) (open it in a browser).

```bash
node scripts/preview/generate.mjs -f pages/_posts/hacks/2026-08-07-thing.md  # one article
node scripts/preview/generate.mjs --changed        # every git-new/modified article
node scripts/preview/generate.mjs --all            # every article missing current art
node scripts/preview/generate.mjs --all --force    # re-skin the whole site
ruby scripts/ci/lint_preview.rb                    # the gate
node scripts/preview/build-lab.mjs                 # rebuild the explorer after editing lib/
```

No gem. No API key. No rasterizer. No network. Node and nothing else.

The one exception, and it is opt-in per article: `illustrate.mjs` asks Claude to draw the article's **subject** once, commits the drawing, and hands it to the same offline renderer. See [the illustration layer](#the-illustration-layer).

---

## Why the old pipeline was replaced

`_config.yml` used to describe an art department: five renderers, a Claude prompt engine, a Claude vision reviewer, per-section art direction. What it actually shipped, measured on the day of the rewrite:

| | |
|---|---|
| Articles | 243 |
| Distinct preview images among them | **43** |
| Articles wearing one of **four** shared section wallpapers | **200** (82%) |
| Banners containing any text at all | **0** |
| `<title>` on a generated banner | the truncated slug — `"Preview banner: order-your-dockerfile-so-the-layer-cache-does-its-"` |

The cause was structural, not a bug in any one script. The wrapper resolved a *capability ladder* — raster API key → Claude SVG companion → the gem's offline `local` template. Every rung could fail, and the bottom rung always succeeded: it stamped a generic gradient, wrote the front matter, and exited 0. **A fallback that reports success is indistinguishable from the thing working.** The site had already published a field note about it (`the-art-director-i-built-and-never-called`) and still nobody could see it in CI, because green is green.

The second structural mistake: the one rung that *was* Claude asked a language model to one-shot a raw SVG document — the single worst way to get vector art out of a model, with no feedback loop and no visual check, so it produced nothing usable and fell through to the template anyway.

## What replaced it

Split the job in two, and give each half to whichever is actually good at it.

- **The algorithm decides composition.** A seeded generative system (Trace Bloom)
lays down a lattice, probes it, propagates wavefronts along the graph, and blooms where they interfere. Coordinates, contrast, density, and focal points come out of math that was swept for bad seeds — not out of a model guessing path data.
- **Deterministic code owns everything that must never be wrong.** Typography,
wrapping, the safe band, palettes, accessibility, and the animation contract are ordinary code with ordinary tests. The floor is high by construction.
- **The article is the seed.** `fnv1a(slug)` fixes the composition; the section
fixes the substrate and palette; the article's own language tilts `decay` (failure reads urgent, architecture reads settled). One article → one portrait, forever. Two articles → never the same picture.

There is **no fallback rung**. If the generator cannot make art it fails loudly, because that is the only thing the old design got wrong that mattered.

```
article.md ──► deriveParams ──► buildScene ──► renderSVG ──► <slug>.svg
   title            seed          lattice        type            +
   tags             section       probes         blooms      preview: stamp
   body             tone          interference   motion
                                  bloom/decay
```

| File | Job |
|---|---|
| `_data/preview/design.json` | Palettes, type scale, safe band, closed parameter bounds. **Edit this to re-skin the site.** |
| `scripts/preview/lib/core.mjs` | Hash, PRNG, noise, lattices, relaxation, propagation, interference |
| `scripts/preview/lib/svg.mjs` | Typography, layout, blooms, the animation contract |
| `scripts/preview/lib/article.mjs` | Front-matter read + `preview:` stamp + motif load |
| `scripts/preview/lib/motif.mjs` | The illustration contract: whitelist, geometry checks, re-serialize, composite |
| `scripts/preview/generate.mjs` | CLI |
| `scripts/preview/illustrate.mjs` | The Claude rung: brief → validate → retry → commit → re-render |
| `scripts/preview/build-lab.mjs` | Builds the explorer by **inlining** the renderer |
| `scripts/ci/lint_preview.rb` | The gate |

## The illustration layer

A Trace Bloom banner is a **portrait of an article** — its slug fixes the composition, its section fixes the palette, its language tilts the mood. What it never was is a *picture of the subject*. Two hacks about completely different things look like siblings, because they are: same lattice, same blooms, different seed. The reader gets the title and the description, drawn beautifully, and learns nothing else.

The illustration layer adds the missing half. **Claude draws one motif per article — the actual apparatus the piece is about — and the renderer composites it into the art side of the banner.**

```
article.md ──► illustrate.mjs ──► motif.mjs ──► _data/preview/motifs/<slug>.svg
   title          the brief         parse             (committed, reviewable)
   description    the model          whitelist                 │
   tags           the retry loop     geometry                  ▼
   body           ↑______________________│         generate.mjs ──► banner
                     violations fed back              composite     with the
                     as the next instruction                        drawing in it
```

```bash
node scripts/preview/illustrate.mjs -f <article.md>   # draw, validate, commit, re-render
node scripts/preview/illustrate.mjs --changed         # every git-new/modified article
node scripts/preview/illustrate.mjs --all --batch 5   # backfill five at a time
node scripts/preview/illustrate.mjs --force -f <f>    # redraw one that came out wrong
node scripts/preview/illustrate.mjs --self-test       # the fixtures; offline, no model call
```

### This is the rung that was buried. What is different?

The pipeline this framework replaced had a Claude rung, and the autopsy above is blunt about it: *"asked a language model to one-shot a raw SVG document — the single worst way to get vector art out of a model, with no feedback loop and no visual check, so it produced nothing usable and fell through to the template anyway."* Every clause in that sentence is a design requirement, and this layer answers them one at a time.

| The old rung | This one |
|---|---|
| The model wrote **the whole document** — typography, layout, accessibility, colours | The model writes **one `<g>`** inside a fixed 1000×1000 box. Typography, the safe band, the palette, the animation contract, and every byte on disk stay with deterministic code |
| Output was **sanitised and passed through** | Output is parsed, whitelisted, and **re-serialized by our code**. Nothing the model emitted is ever copied through verbatim, so an unsafe banner cannot be produced even from a hostile response |
| **No feedback loop** — one shot, take it or leave it | Vocabulary and geometry are checked, and each violation is written as an instruction and handed back as the next turn (`--attempts`, default 3) |
| **No check at all** on the result | Coordinates are walked — paths included — so a drawing that hides in a corner, drifts out of frame, hairlines itself into invisibility, or drops a full-bleed plate over the field is rejected before anyone sees it |
| Failure **fell through to a template** and exited 0 | Failure exits non-zero and says why. The article keeps the banner Trace Bloom already computed for it — **its own picture, never a shared one** — so nothing degrades and nobody is told art was made when it was not |

That last row is the one that matters. "No fallback rung" is still the rule; what makes an additive layer legal here is that the thing underneath it was never the pathology. The old ladder's bottom rung was four wallpapers shared by 200 articles. This one's floor is the per-article banner the site already ships.

What none of this gives you is a **visual** check — there is no rasterizer and no vision pass, so the validator can prove a drawing is safe, on-palette, well-composed, and legible at card size, and still not know whether it is any good. That judgement is a human's, at the PR, which is where every other content decision in this repo is made too.

### The contract a drawing has to satisfy

Lives in [`scripts/preview/lib/motif.mjs`](../scripts/preview/lib/motif.mjs), enforced identically when authoring and when loading:

- **The frame.** 1000×1000, coordinates inside it, composed to fill ≥42% of both axes and centred near (500, 500). Scaled into `design.json`'s `motif.box` — inside the safe band, clear of the headline plate.
- **The vocabulary.** `g, path, circle, ellipse, rect, line, polyline, polygon`, plus `defs`/gradients. Everything else — `text`, `image`, `use`, `script`, `foreignObject`, `filter`, the animation elements — is absent from the whitelist rather than banned by a rule, which is the difference between a door that is locked and a wall.
- **The palette.** Tokens only: `ink cool warm accent grid muted bg0 bg1`, resolved to the article's **section** palette at render time. Raw hex is refused. Re-skinning `design.json` therefore reaches every illustration on the site, and a drawing made for a hack still looks right if the piece moves to the wire.
- **The weight.** 6–200 shapes, at least two tokens, no stroke thinner than 4 units — a hairline is nothing once the card crop is done with it.

### Cost

One Claude Code call per article, **once, ever**. The drawing is committed, so re-skins, `GENERATOR` bumps, CI re-runs, and `--all --force` all re-render from the committed file and never call a model again. Auth and model selection go through `scripts/ai/run.sh` and `_data/ai.yml` (`illustrator_model`) like every other AI call in the repo — subscription auth via `CLAUDE_CODE_OAUTH_TOKEN`, no image API, no per-image dollar cost, and the call is metered into the usage ledger like everything else. Bulk runs are capped at 4 articles unless you pass `--batch`.

### Staleness, and why `GENERATOR` did not move

An un-illustrated banner renders **byte-identically** to what it rendered before this layer existed, so bumping `GENERATOR` would have re-rolled 274 files to change none of them. Instead an illustrated banner carries `data-motif="<digest>"`, and the generator treats a banner whose digest does not match its motif — or that carries one when the motif is gone — as stale. Draw, redraw, or delete a motif and the next `generate.mjs` run picks it up; the two staleness signals are orthogonal and neither hides the other.

### The gate

`lint_preview.rb` shells out to `illustrate.mjs --check` (offline; no model call) and folds the result into the same report as the banner rules — one validator, not two that drift:

| Rule | Severity | Catches |
|---|---|---|
| `invalid-motif` | error | a committed drawing the renderer would refuse — a banner that cannot be built |
| `stale-motif` | error | a drawing that exists but has not been composited; the article still shows its un-illustrated cover |
| `orphan-motif` | warning | a drawing whose slug matches no article |
| `motif-selftest` | error | the whitelist itself regressed — the fixtures prove `<script>`, `<image>`, raw hex, and a background plate are still refused |

## Three contracts worth knowing before you change anything

**1. The safe band.** The theme renders cards as `background-size: cover` at 120–150px (`_includes/home/cover.html`). A 3:2 banner centre-cropped to 2.5:1 keeps only the **middle 60%** of its height. Every glyph must sit inside `safeTop..safeBottom`; the lint fails art that does not. This is why the type block is centred in the band rather than bottom-anchored, which looks better at full size and loses the byline in the grid.

**2. Motion is never load-bearing.** Social scrapers, PDF exports, and any rasterizer capture frame 0. So the reveal sweep animates `opacity: .3 → 1` — a power-on, never a fade-in-from-nothing — and the type is not animated at all. `prefers-reduced-motion: reduce` stops everything and rests on the composed frame. **The still frame is the work; the motion is a gift.**

**3. Seed order is a contract.** `deriveParams` samples the parameter space in a fixed order. Inserting a `pick()` above an existing one re-rolls every banner on the site. Append, don't insert.

## Regenerating existing art

Every banner carries `data-generator="trace-bloom/N"`. The generator refreshes any article whose art is missing, shared, broken, or from an older generation — so a design change actually reaches the archive. Bump `GENERATOR` in `lib/svg.mjs` when you change the visual contract, then `--all`.

What it will **not** touch: bespoke art. An article pointing at a hand-picked screenshot or one of the grandfathered AI-rendered PNGs keeps it. Only `--force` overrides that.

## The gate

`ruby scripts/ci/lint_preview.rb`, wired into `scripts/ci/run-all.sh`. Each rule is a fossil of the old failure:

| Rule | Severity | Catches |
|---|---|---|
| `missing-preview-file` | error | stamp resolves to nothing — card renders blank |
| `missing-body-image` | error | an article embeds preview art that isn't there |
| `shared-preview` | error >2, warn 2 | one image doing duty for many articles |
| `textless-banner` | error | cover art with no headline — unreadable at 300px |
| `unsafe-svg` | error | script / foreignObject / external reference |
| `preview-outside-safe-band` | warning | type the card crop cuts off |
| `orphan-preview` | warning | art nothing references, in front matter or body |
| `orphan-figure` | warning | weekly-epic figure art (`assets/images/figures/`) no article body embeds |

Two `shared-preview` warnings are expected and correct: two grandfathered pairs of legacy posts share a photo apiece.

**Cover art vs. exhibits.** `textless-banner` and `preview-outside-safe-band` apply only to art an article stamps as `preview:` — that is what has to survive a 300px card. Art embedded in a *body* is an exhibit and is held to `unsafe-svg` only: `docs/the-plugin-that-isnt-a-plugin` deliberately displays the retired pipeline's textless template output as evidence of what it produced. The first version of this lint called that file an orphan, it got deleted, and the page shipped a broken image — which is why `orphan-preview` now counts body mentions and `missing-body-image` exists. Note the deliberate asymmetry: `missing-body-image` matches only real `![](…)` / `<img>` embeds outside code fences, because these articles are *about* the preview pipeline and their code blocks are full of example paths; `orphan-preview` treats a mention *anywhere*, code fences included, as reason enough never to delete the file.

## In-body figures (the weekly epic's exhibits)

The weekly Top Story (`.claude/skills/weekly-epic`) embeds figures, and they follow this framework's philosophy with a second generator: **`scripts/media/figures.mjs`** (see `scripts/media/README.md`). Same split of labor — the agent supplies data (the committed weekly digest, a slug, a number for the gauge) and deterministic code owns every coordinate; same design tokens (`_data/preview/design.json`), same animation contract, same determinism promise (commit the digest, and the art regenerates byte-identical). Figures live in `assets/images/figures/<slug>/` and are exhibits, not cover art: the lint holds them to `unsafe-svg` + `missing-body-image` + `orphan-figure`, never to the headline/safe-band rules.

The one deliberate exception to "offline and deterministic": `scripts/media/openai_image.mjs` can paint a single raster hero per epic via the OpenAI Images API. It is double-gated (`OPENAI_IMAGES_ENABLED` repo var **and** `OPENAI_API_KEY` secret), never used as a fallback, captioned as AI-generated in the article, and audited by a committed `.prompt.json` sidecar. If the gate is closed, the SVG figures aren't a downgrade — they're the default.

## The explorer

`docs/preview-lab.html` sweeps the seed space with live sliders for every parameter, a section switch, and PNG/SVG export. It **inlines the production renderer** at build time rather than reimplementing it in p5 — an explorer carrying its own copy of the algorithm drifts within a week and then quietly lies to whoever is tuning it. Re-run `node scripts/preview/build-lab.mjs` after editing `lib/`.

## Gotcha we already paid for

`String.prototype.replace` with a **string** replacement expands `$1`, `$&`, `` $` `` and `$'`. Front matter is prose. The first run of the stamper hit an article whose description read *"the `$1` capture syntax"* and spliced the entire front-matter block into itself. Every replacement in `article.mjs` is a **function** for that reason. Do not change them back.
