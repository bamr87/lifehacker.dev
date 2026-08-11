#!/usr/bin/env node
// =============================================================================
// scripts/media/openai_image.mjs — OPT-IN AI raster art for the weekly epic
// -----------------------------------------------------------------------------
// The weekly-epic routine illustrates the Top Story with deterministic SVG
// figures (figures.mjs) by default. THIS script is the optional extra: one
// painted hero illustration via the OpenAI Images API, for owners who set the
// key. It is a paid, non-deterministic, network call — everything the default
// path deliberately is not — so it is opt-in twice over (the workflow only
// exports OPENAI_API_KEY when the owner also set OPENAI_IMAGES_ENABLED) and it
// NEVER falls back: no key → exit 2 with a pointer to figures.mjs. A fallback
// that reports success is indistinguishable from the thing working
// (docs/PREVIEW-IMAGES.md); the CALLER chooses the offline path, this script
// doesn't choose it silently.
//
//   OPENAI_API_KEY=sk-… node scripts/media/openai_image.mjs \
//     --prompt "an oil-painted server room at dawn…" \
//     --out assets/images/figures/<slug>/hero.png \
//     [--model gpt-image-1] [--size 1536x1024] [--quality medium]
//
// Provenance: writes <out>.prompt.json next to the image (model, size, quality,
// the full prompt, the image's sha256) so the art is auditable forever, and the
// article can caption it honestly ("AI-generated illustration"). The epic's
// front matter and captions MUST disclose AI-generated rasters — the site's
// whole shtick is saying which robot did what.
//
// Cost (list-price estimates, printed per run): gpt-image-1 at 1536×1024 is
// roughly $0.016 low / $0.063 medium / $0.25 high per image. Estimated only —
// verify on the OpenAI usage dashboard; this repo's AI meter covers Claude
// calls, so THIS line in the run log is the OpenAI spend's paper trail.
// Zero npm packages; Node ≥ 18 (global fetch). Honors OPENAI_BASE_URL.
// =============================================================================
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const EST_USD = { // model → quality → per-image estimate at 1536×1024 / 1024×1536
  'gpt-image-1': { low: 0.016, medium: 0.063, high: 0.25, auto: 0.063 },
};
const SIZES = ['1024x1024', '1536x1024', '1024x1536', 'auto'];

function die(msg, code = 1) { console.error(`[openai-image] ERROR: ${msg}`); process.exit(code); }

function parseArgs(argv) {
  const args = { model: 'gpt-image-1', size: '1536x1024', quality: 'medium' };
  for (let i = 0; i < argv.length; i++) {
    if (!argv[i].startsWith('--')) die(`unexpected argument: ${argv[i]}`);
    args[argv[i].slice(2)] = argv[i + 1];
    i += 1;
  }
  return args;
}

async function generate({ key, base, model, prompt, size, quality }) {
  const url = `${base.replace(/\/$/, '')}/images/generations`;
  const body = JSON.stringify({ model, prompt, size, quality, n: 1 });
  for (let attempt = 1; ; attempt++) {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${key}` },
      body,
    });
    if (res.ok) return res.json();
    const text = await res.text().catch(() => '');
    const retryable = res.status === 429 || res.status >= 500;
    if (retryable && attempt === 1) {
      console.error(`[openai-image] ${res.status} from the API — retrying once in 5s…`);
      await new Promise((r) => setTimeout(r, 5000));
      continue;
    }
    die(`images API returned ${res.status}: ${text.slice(0, 400)}`);
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.prompt || !args.prompt.trim()) die('--prompt is required');
  if (!args.out) die('--out <file.png> is required');
  if (!SIZES.includes(args.size)) die(`--size must be one of ${SIZES.join(', ')}`);

  const key = process.env.OPENAI_API_KEY;
  if (!key) {
    die('OPENAI_API_KEY is not set. This path is OPT-IN and never falls back — '
      + 'use the offline figure renderer instead: node scripts/media/figures.mjs', 2);
  }
  const base = process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1';

  const est = (EST_USD[args.model] || {})[args.quality];
  console.error(`[openai-image] requesting ${args.model} ${args.size} quality=${args.quality}`
    + (est ? ` (~$${est} list-price estimate — verify on the OpenAI dashboard)` : ''));

  const json = await generate({ key, base, model: args.model, prompt: args.prompt, size: args.size, quality: args.quality });
  const b64 = json && json.data && json.data[0] && json.data[0].b64_json;
  if (!b64) die(`API response carried no image data: ${JSON.stringify(json).slice(0, 300)}`);

  const png = Buffer.from(b64, 'base64');
  fs.mkdirSync(path.dirname(args.out), { recursive: true });
  fs.writeFileSync(args.out, png);

  const sidecar = {
    source: 'openai',
    model: args.model,
    size: args.size,
    quality: args.quality,
    prompt: args.prompt,
    sha256: crypto.createHash('sha256').update(png).digest('hex'),
    generated: new Date().toISOString().slice(0, 10),
    estimated_cost_usd: est ?? null,
    note: 'AI-generated raster. The embedding article must caption it as such.',
  };
  fs.writeFileSync(`${args.out}.prompt.json`, `${JSON.stringify(sidecar, null, 2)}\n`);
  console.log(`[openai-image] ✓ ${args.out} (${(png.length / 1024).toFixed(0)} kB) + provenance sidecar`);
}

main().catch((e) => die(e && e.stack ? e.stack : String(e)));
