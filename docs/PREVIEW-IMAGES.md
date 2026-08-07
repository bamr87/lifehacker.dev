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
| `scripts/preview/lib/article.mjs` | Front-matter read + `preview:` stamp |
| `scripts/preview/generate.mjs` | CLI |
| `scripts/preview/build-lab.mjs` | Builds the explorer by **inlining** the renderer |
| `scripts/ci/lint_preview.rb` | The gate |

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
| `shared-preview` | error >2, warn 2 | one image doing duty for many articles |
| `textless-banner` | error | no headline — unreadable at 300px |
| `unsafe-svg` | error | script / foreignObject / external reference |
| `preview-outside-safe-band` | warning | type the card crop cuts off |
| `orphan-preview` | warning | art nothing references |

Two `shared-preview` warnings are expected and correct: two grandfathered pairs of legacy posts share a photo apiece.

## The explorer

`docs/preview-lab.html` sweeps the seed space with live sliders for every parameter, a section switch, and PNG/SVG export. It **inlines the production renderer** at build time rather than reimplementing it in p5 — an explorer carrying its own copy of the algorithm drifts within a week and then quietly lies to whoever is tuning it. Re-run `node scripts/preview/build-lab.mjs` after editing `lib/`.

## Gotcha we already paid for

`String.prototype.replace` with a **string** replacement expands `$1`, `$&`, `` $` `` and `$'`. Front matter is prose. The first run of the stamper hit an article whose description read *"the `$1` capture syntax"* and spliced the entire front-matter block into itself. Every replacement in `article.mjs` is a **function** for that reason. Do not change them back.
