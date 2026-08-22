# scripts/preview

The Trace Bloom preview-banner renderer. Dependency-free JavaScript (Node ≥ 18, zero npm packages) — it runs on a bare CI runner, on a laptop with no bundle, and inside a browser.

- **What it is and why:** [`docs/PREVIEW-IMAGES.md`](../../docs/PREVIEW-IMAGES.md)
- **The aesthetic:** [`docs/TRACE-BLOOM.md`](../../docs/TRACE-BLOOM.md)
- **Design tokens (edit here to re-skin):** [`_data/preview/design.json`](../../_data/preview/design.json)
- **Sibling — in-body figures for the weekly epic:** [`scripts/media/`](../media/README.md) (same tokens, same contracts, exhibits instead of covers)

```bash
node scripts/preview/generate.mjs -f <article.md>   # one article
node scripts/preview/generate.mjs --changed         # git-new/modified articles
node scripts/preview/generate.mjs --all             # anything missing current art
node scripts/preview/generate.mjs --all --force     # re-skin everything
node scripts/preview/generate.mjs --scene -f <f>    # dump the scene as JSON
node scripts/preview/build-lab.mjs                  # rebuild docs/preview-lab.html
ruby scripts/ci/lint_preview.rb                     # the gate

node scripts/preview/illustrate.mjs -f <article.md> # Claude draws the subject, then re-renders
node scripts/preview/illustrate.mjs --self-test     # the whitelist fixtures (offline)
node scripts/preview/illustrate.mjs --check         # validate committed motifs (what the gate runs)
```

The generator is offline and free. The **illustrator** is the one part that calls a model — once per article, ever, through `scripts/ai/run.sh` (subscription auth, model from `_data/ai.yml illustrator_model`). Its output is committed to `_data/preview/motifs/<slug>.svg`, so every later render is offline again.

| File | Job |
|---|---|
| `lib/core.mjs` | Hash, PRNG, value noise, lattices, relaxation, Dijkstra propagation, interference → a scene |
| `lib/svg.mjs` | Scene → SVG: text metrics, headline fitting, safe-band layout, blooms, the animation contract |
| `lib/motif.mjs` | The illustration contract: parse, whitelist, geometry checks, re-serialize, composite |
| `lib/article.mjs` | Front-matter read, slug, section, `preview:` stamp, motif load |
| `generate.mjs` | CLI + the skip/refresh policy |
| `illustrate.mjs` | The Claude rung: brief → validate → retry → commit the motif → re-render |
| `build-lab.mjs` | Inlines `lib/` into the interactive explorer |

## Rules that are not style preferences

1. **Seed order is a contract.** `deriveParams` samples the parameter space in a
fixed order; inserting a `pick()` above an existing one re-rolls every banner on the site. Append, never insert.
2. **Bump `GENERATOR` in `lib/svg.mjs`** whenever the visual contract changes.
   That version is what makes `--all` refresh existing art instead of skipping it.
3. **Never use a string replacement on front matter.** `$1`/`$&` expand. See the
   gotcha section in `docs/PREVIEW-IMAGES.md` — it corrupted a real article once.
4. **Motion is never load-bearing.** Frame 0 must be a complete image, because
   that is the frame every social scraper captures.
5. **No fallback rung.** If art cannot be made, fail loudly. A pipeline that
   silently degrades to a generic gradient is exactly what this replaced.

After changing `lib/` or `design.json`: re-run `build-lab.mjs`, regenerate with `--all --force`, and eyeball a contact sheet before committing.
