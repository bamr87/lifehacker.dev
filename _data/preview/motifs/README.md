# _data/preview/motifs

One file per illustrated article: `<slug>.svg`, the drawing of what that article is **about**. Claude authors it once; the renderer composites it into the article's banner every time thereafter.

- **How it gets here:** `node scripts/preview/illustrate.mjs -f <article.md>`
- **What it is:** [`docs/PREVIEW-IMAGES.md`](../../../docs/PREVIEW-IMAGES.md#the-illustration-layer)
- **The contract it must satisfy:** [`scripts/preview/lib/motif.mjs`](../../../scripts/preview/lib/motif.mjs)
- **The gate:** `ruby scripts/ci/lint_preview.rb` (rules `invalid-motif`,
  `stale-motif`, `orphan-motif`, `motif-selftest`)

## Why the files live here and not in `assets/`

A motif is a **source** the renderer reads, not an image the site serves. Nothing links to these files; the banner in `assets/images/previews/<slug>.svg` is what ships.

They are invisible to Jekyll: `DataReader#read_data_to` globs `*.{yaml,yml,json,csv,tsv}` plus directories, so an `.svg` (or this `.md`) under `_data/` is neither parsed as data nor copied to `_site`. `site.data.preview.motifs` is simply an empty hash. That is the whole reason a directory of SVGs can live here without a single `exclude:` line.

## What is in one

A standalone 1000×1000 SVG document you can open in a browser, holding:

| | |
|---|---|
| `<title>` | the concept sentence — it becomes part of the banner's `<desc>`, so it is the accessible description of the artwork |
| `data-model` | which model drew it |
| `data-attempts` | how many validation rounds it took |
| `data-digest` | the artwork's identity; the composited banner carries the same value as `data-motif`, which is how the generator spots a banner that has not caught up |
| `<style>` | **preview only.** It binds the palette tokens to one section's colours so the file renders on its own. The compositor throws it away and resolves the tokens against the article's real section palette. |

Colours are **tokens**, never hex: `fill="cool"`, `stroke="ink"`. That is what lets `_data/preview/design.json` re-skin every illustration on the site at once.

## Editing one by hand

Allowed, and re-validated on read — an edit that breaks the contract fails the gate instead of reaching a banner. After editing, re-render the article's cover:

```bash
node scripts/preview/generate.mjs -f <article.md>
```

Deleting a motif is also fine: the article falls back to its computed Trace Bloom banner (its own, never a shared placeholder). Re-render afterwards, or the gate's `stale-motif` rule will point out that the banner still carries the old drawing.
