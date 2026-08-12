# scripts/media

In-body media for the weekly epic (the Top Story). Where `scripts/preview/` makes an article's **cover**, this directory makes the **exhibits inside** it: figures computed from the week's real publications, plus an opt-in AI-painted illustration.

- **The routine that uses these:** [`.claude/skills/weekly-epic/SKILL.md`](../../.claude/skills/weekly-epic/SKILL.md)
- **The framework + rules:** [`docs/PREVIEW-IMAGES.md`](../../docs/PREVIEW-IMAGES.md) (safe-SVG contract, animation contract)
- **The aesthetic + tokens:** [`docs/TRACE-BLOOM.md`](../../docs/TRACE-BLOOM.md), [`_data/preview/design.json`](../../_data/preview/design.json) — figures read the same palette file as the banners, so a re-skin reaches both.

```bash
# 1. The week, as data (deterministic; commit it next to the figures it feeds)
ruby scripts/content/weekly_digest.rb --days 7 --out assets/images/figures/<slug>/digest.json

# 2. Figures computed from the digest (offline, zero-dep, deterministic, animated)
node scripts/media/figures.mjs constellation --digest <digest.json> --slug <slug>
node scripts/media/figures.mjs timeline      --digest <digest.json> --slug <slug>
node scripts/media/figures.mjs gauge         --slug <slug> --value 87.3 --label "Irony Saturation" --sublabel "*the joke walks itself back here"

# 3. OPTIONAL: one painted hero image via the OpenAI Images API (paid, opt-in)
OPENAI_API_KEY=sk-… node scripts/media/openai_image.mjs --prompt "…" --out assets/images/figures/<slug>/hero.png
```

| File | Job |
|---|---|
| `figures.mjs` | Digest → inert, animated SVG figures (`constellation`, `timeline`, `gauge`), seeded by slug + window |
| `openai_image.mjs` | Prompt → one PNG via OpenAI `gpt-image-1` + a `.prompt.json` provenance sidecar. Needs `OPENAI_API_KEY`; **never** falls back |

Output lands in `assets/images/figures/<slug>/`; articles embed it with ordinary `![caption](/assets/images/figures/<slug>/constellation.svg)` lines.

## Rules that are not style preferences

1. **The algorithm draws; the model narrates.** A language model never one-shots
   SVG path data here — that is the exact failure `docs/PREVIEW-IMAGES.md` documents. The agent's inputs are the digest, a slug, and (for the gauge) a number + a joke; the code owns every coordinate.
2. **Inert SVG only.** No `<script>`, `<foreignObject>`, `<image>`, or external
   `href`/`src` — `scripts/ci/lint_preview.rb` scans this directory's SVGs with the same `unsafe-svg` rule as the banners.
3. **Motion is never load-bearing.** Frame 0 is complete; everything stops under
   `prefers-reduced-motion: reduce`. The moving version is a gift; the frozen version is the work.
4. **Deterministic where possible, disclosed where not.** `figures.mjs` output is
   byte-identical for the same digest + slug (no wall-clock, no unseeded random — commit the digest and the art is reproducible). `openai_image.mjs` is inherently non-deterministic, which is why it writes a provenance sidecar and why its captions must say "AI-generated".
5. **No fallback rung.** A missing digest, an empty week, a bad value, an absent
   API key: each fails loudly with a non-zero exit. The *skill* chooses between the offline and the OpenAI path, explicitly; no script degrades silently.
