// Trace Bloom — scene → SVG.
//
// Emits a self-contained, sanitiser-safe banner: no <script>, no <foreignObject>,
// no <image>, no external references of any kind. Everything the browser needs is
// inside the document, which is why it is safe to serve straight from `<img src>`.
//
// Two jobs the old pipeline never did:
//   1. TYPOGRAPHY. The headline is rendered, wrapped, and fitted, so the card is
//      legible at 300px. A banner nobody can read is a decoration, not a preview.
//   2. MOTION AS INFORMATION. The reveal sweep plays in arrival order, so the
//      animation shows propagation rather than wiggling for its own sake — and it
//      stops dead under prefers-reduced-motion, resting on the composed frame.

import { mix, clamp } from './core.mjs';
import { renderMotifLayer, motifStamp } from './motif.mjs';

// Stamped onto every banner's root element. The generator regenerates any file
// that does not carry the CURRENT version, which is what lets a design change
// (or a fix like the safe-band layout) actually reach art that already exists
// under the right filename. Bump on any change to the visual contract.
export const GENERATOR = 'trace-bloom/1';

// ── text metrics ─────────────────────────────────────────────────────────────
// Helvetica/Arial Bold advance widths (per 1000 em). We cannot measure text
// without a browser, and shipping a banner whose headline overflows the plate is
// worse than shipping none — so we carry the table.
const ADV = {
  ' ': 278, '!': 333, '"': 474, '#': 556, $: 556, '%': 889, '&': 722, "'": 238,
  '(': 333, ')': 333, '*': 389, '+': 584, ',': 278, '-': 333, '.': 278, '/': 278,
  ':': 333, ';': 333, '<': 584, '=': 584, '>': 584, '?': 611, '@': 975,
  '[': 333, '\\': 278, ']': 333, '^': 584, _: 556, '`': 333,
  '{': 389, '|': 280, '}': 389, '~': 584,
  A: 722, B: 722, C: 722, D: 722, E: 667, F: 611, G: 778, H: 722, I: 278,
  J: 556, K: 722, L: 611, M: 833, N: 722, O: 778, P: 667, Q: 778, R: 722,
  S: 667, T: 611, U: 722, V: 667, W: 944, X: 667, Y: 667, Z: 611,
  a: 556, b: 611, c: 556, d: 611, e: 556, f: 333, g: 611, h: 611, i: 278,
  j: 278, k: 556, l: 278, m: 889, n: 611, o: 611, p: 611, q: 611, r: 389,
  s: 556, t: 333, u: 611, v: 556, w: 778, x: 556, y: 556, z: 500,
};
const DIGIT = 556;

export function textWidth(str, size, tracking = 0) {
  let w = 0;
  for (const ch of str) {
    w += (ADV[ch] ?? (ch >= '0' && ch <= '9' ? DIGIT : 600)) / 1000;
  }
  return w * size + tracking * Math.max(0, str.length - 1);
}

/** Greedy wrap, then shrink-to-fit, then (last resort) ellipsis. */
export function fitHeadline(text, { maxWidth, maxLines, size, minSize = 52, tracking = 0 }) {
  const words = String(text).trim().split(/\s+/).filter(Boolean);
  for (let s = size; s >= minSize; s -= 4) {
    const lines = [];
    let line = '';
    let overflowed = false;
    for (const word of words) {
      const probe = line ? `${line} ${word}` : word;
      if (textWidth(probe, s, tracking) <= maxWidth) { line = probe; continue; }
      if (line) lines.push(line);
      line = word;
      if (textWidth(word, s, tracking) > maxWidth) overflowed = true;  // unbreakable
    }
    if (line) lines.push(line);
    if (lines.length <= maxLines && !overflowed) return { lines, size: s };
  }
  // Could not fit cleanly: clip at maxLines and ellipsise the last one.
  const s = minSize;
  const lines = [];
  let line = '';
  for (const word of words) {
    const probe = line ? `${line} ${word}` : word;
    if (textWidth(probe, s, tracking) <= maxWidth) { line = probe; continue; }
    if (line) lines.push(line);
    if (lines.length >= maxLines) { line = ''; break; }
    line = word;
  }
  if (line && lines.length < maxLines) lines.push(line);
  if (lines.length === maxLines) {
    let last = lines[maxLines - 1];
    while (last.length > 4 && textWidth(`${last}…`, s, tracking) > maxWidth) last = last.slice(0, -1);
    lines[maxLines - 1] = `${last.replace(/[\s,;:.-]+$/, '')}…`;
  }
  return { lines, size: s };
}

const esc = (s) => String(s)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;');

// ── renderer ─────────────────────────────────────────────────────────────────

export function renderSVG(scene, meta, design) {
  const { w, h, palette: P, params } = scene;
  const L = design.layout, T = design.type, M = design.motion;
  const out = [];
  const push = (s) => out.push(s);

  const plateEdge = w * L.plateWidth;
  const textLeft = L.margin;
  const textMax = plateEdge - L.margin * 1.1;

  // ---- typography (fitted before anything is drawn, so layout can react) -----
  // Fit to the SAFE BAND, not just to the plate width. A four-line headline at
  // full size overflows the 120px card crop and eats its own byline, so we trade
  // lines for size until the whole block fits the band with breathing room.
  const GAP_EYEBROW = 44, GAP_RULE = 52, RULE_H = 4, GAP_BYLINE = 42;
  const band = h * (L.safeBottom - L.safeTop) * 0.93;
  const blockHeight = (lines, size) => T.eyebrow.size + GAP_EYEBROW
    + (lines - 1) * size * T.headline.leading + size
    + GAP_RULE + RULE_H + GAP_BYLINE + T.byline.size;

  let head = null;
  for (const maxLines of [T.headline.maxLines, T.headline.maxLines - 1]) {
    const candidate = fitHeadline(meta.title || '', {
      maxWidth: textMax, maxLines,
      size: T.headline.size, tracking: T.headline.tracking,
    });
    if (blockHeight(candidate.lines.length, candidate.size) <= band) { head = candidate; break; }
    head = head || candidate;
  }
  while (blockHeight(head.lines.length, head.size) > band && head.size > 44) {
    head = fitHeadline(meta.title || '', {
      maxWidth: textMax, maxLines: head.lines.length,
      size: head.size - 6, minSize: 44, tracking: T.headline.tracking,
    });
  }
  // Lay the block out inside the SAFE BAND and centre it there. Bottom-anchoring
  // reads better at full size but loses the byline the moment the homepage crops
  // a card to 120px — and the card grid is where most people meet this image.
  const lineH = head.size * T.headline.leading;
  const blockH = blockHeight(head.lines.length, head.size);
  const safeMid = h * (L.safeTop + L.safeBottom) / 2;
  const top = safeMid - blockH / 2;

  const eyebrowY = top + T.eyebrow.size;
  const firstBase = eyebrowY + GAP_EYEBROW + head.size;
  const ruleY = firstBase + (head.lines.length - 1) * lineH + GAP_RULE;
  const bylineY = ruleY + RULE_H + GAP_BYLINE + T.byline.size * 0.5;

  // A MOTIF is the article's subject, drawn by Claude inside a fixed box and
  // validated by lib/motif.mjs. It is optional and additive: without one this
  // renderer emits exactly the bytes it always did, which is why adding the
  // layer did not need a GENERATOR bump. Staleness is tracked separately, by
  // the digest stamped below (see generate.mjs).
  const motif = meta.motif || null;
  const motifLayer = motif ? renderMotifLayer(motif, design, P, { bucket: Math.round(M.buckets * 0.45) }) : null;

  push(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}" role="img" aria-labelledby="t d" data-generator="${GENERATOR}" data-seed="${params.seed}"${motif ? ` data-motif="${motifStamp(motif)}"` : ''}>`);
  push(`<title id="t">${esc(meta.title || 'Preview banner')}</title>`);
  push(`<desc id="d">${esc(
    (motif && motif.concept ? `${motif.concept.replace(/\s+$/, '')} ` : '') +
    `Trace Bloom generative banner for “${meta.title}”. A ${params.lattice} lattice probed by ` +
    `${params.probes} emitters; interference blooms mark where the wavefronts meet. Seed ${params.seed}.`
  )}</desc>`);

  // ---- motion --------------------------------------------------------------
  const delays = [];
  for (let i = 0; i < M.buckets; i++) {
    delays.push(`.b${i}{animation-delay:${(i / M.buckets * M.sweepSeconds).toFixed(2)}s}`);
  }
  // MOTION MUST NEVER BE LOAD-BEARING. A social-card scraper, a PDF export, or
  // any rasterizer that captures frame 0 sees the `from` state — so `from` is a
  // dimmed-but-complete frame, never an empty one, and the type is not animated
  // at all. The sweep is a power-on, not a reveal. (TRACE-BLOOM.md: "the moving
  // version is a gift; the frozen version is the work.")
  push(`<style>
@keyframes tb-sweep{from{opacity:.3}to{opacity:1}}
@keyframes tb-breathe{0%,100%{opacity:.68}50%{opacity:1}}
@keyframes tb-probe{0%,100%{opacity:.6}50%{opacity:1}}
.sig{animation:tb-sweep .7s cubic-bezier(.2,.7,.3,1) both}
${delays.join('')}
.bloom{animation:tb-breathe ${M.breatheSeconds}s ease-in-out infinite}
.probe{animation:tb-probe ${(M.breatheSeconds * 0.6).toFixed(1)}s ease-in-out infinite}${motif ? `
@keyframes tb-motif{from{opacity:.72}to{opacity:1}}
.motif{animation:tb-motif .9s cubic-bezier(.2,.7,.3,1) both;animation-delay:${(M.sweepSeconds * 0.34).toFixed(2)}s}` : ''}
@media (prefers-reduced-motion:reduce){
.sig,.bloom,.probe,.motif{animation:none!important;opacity:1!important}
}</style>`);

  // ---- defs ----------------------------------------------------------------
  push('<defs>');
  push(`<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="${P.bg0}"/><stop offset="1" stop-color="${P.bg1}"/></linearGradient>`);
  // Scrim: guarantees headline contrast no matter what the field does behind it.
  // It must clear the art quickly — a scrim that reaches the right edge dims the
  // entire composition, which is how a lit field turns into fog on black.
  push(`<linearGradient id="scrim" x1="0" y1="0" x2="1" y2="0">
<stop offset="0" stop-color="${P.bg0}" stop-opacity="0.94"/>
<stop offset="0.38" stop-color="${P.bg0}" stop-opacity="0.8"/>
<stop offset="${L.scrimStop}" stop-color="${P.bg0}" stop-opacity="0.12"/>
<stop offset="0.9" stop-color="${P.bg0}" stop-opacity="0"/></linearGradient>`);
  push(`<linearGradient id="floor" x1="0" y1="1" x2="0" y2="0">
<stop offset="0" stop-color="${P.bg0}" stop-opacity="0.5"/>
<stop offset="0.46" stop-color="${P.bg0}" stop-opacity="0"/></linearGradient>`);
  // Blooms as layered radial gradients — cheaper and more portable than filters.
  // Tight falloff: a bloom is a hot NODE on the lattice, not atmosphere.
  for (const [id, col] of [['bc', P.cool], ['bw', P.warm]]) {
    push(`<radialGradient id="${id}">
<stop offset="0" stop-color="${col}" stop-opacity="0.95"/>
<stop offset="0.18" stop-color="${col}" stop-opacity="0.5"/>
<stop offset="0.5" stop-color="${col}" stop-opacity="0.14"/>
<stop offset="1" stop-color="${col}" stop-opacity="0"/></radialGradient>`);
  }
  push(`<pattern id="scan" width="4" height="4" patternUnits="userSpaceOnUse">
<rect width="4" height="1" fill="${P.bg0}" opacity="0.22"/></pattern>`);
  if (motifLayer) push(motifLayer.defs);
  push('</defs>');

  push(`<rect width="${w}" height="${h}" fill="url(#bg)"/>`);

  // ---- substrate: every edge, dim, in ONE path ------------------------------
  const sub = scene.edges.map((e) => `M${e.x1} ${e.y1}L${e.x2} ${e.y2}`).join('');
  push(`<path d="${sub}" stroke="${P.grid}" stroke-width="1.5" fill="none" stroke-opacity="0.95"/>`);

  // ---- signal: lit edges, grouped by arrival bucket → sign → width tier ------
  // Grouping keeps the element count near 80 instead of near 800: same picture,
  // a fraction of the bytes, and the bucket IS the animation delay.
  const TIERS = [
    { min: 0.78, width: 4.4, opacity: 1 },
    { min: 0.46, width: 2.6, opacity: 0.85 },
    { min: 0.18, width: 1.7, opacity: 0.6 },
  ];
  const groups = new Map();
  for (const e of scene.edges) {
    const tier = TIERS.findIndex((t) => e.lit >= t.min);
    if (tier === -1) continue;
    const key = `${e.bucket}|${e.sign}|${tier}`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(`M${e.x1} ${e.y1}L${e.x2} ${e.y2}`);
  }
  const keys = [...groups.keys()].sort((a, b) => {
    const [ab, , at] = a.split('|').map(Number), [bb, , bt] = b.split('|').map(Number);
    return ab - bb || at - bt;
  });
  for (const key of keys) {
    const [bucket, sign, tier] = key.split('|').map(Number);
    const t = TIERS[tier];
    // Constructive interference runs cool, destructive runs warm; both are
    // pulled a little toward the grid colour at low tiers so nothing shouts.
    const base = sign > 0 ? P.cool : P.warm;
    const col = mix(P.grid, base, clamp(0.55 + (2 - tier) * 0.22, 0, 1));
    push(`<path class="sig b${bucket}" d="${groups.get(key).join('')}" stroke="${col}" stroke-width="${t.width}" stroke-opacity="${t.opacity}" fill="none" stroke-linecap="round"/>`);
  }

  // ---- blooms --------------------------------------------------------------
  // With a motif in the frame the blooms stop being the subject and become
  // weather. Left at full strength they compete with the drawing for the same
  // eye, and the article's own picture loses.
  const bloomDim = motif ? (design.motif?.fieldDim ?? 0.55) : 1;
  if (motif) push(`<g opacity="${bloomDim}">`);
  for (const b of scene.blooms) {
    push(`<circle class="sig bloom b${b.bucket}" cx="${b.x}" cy="${b.y}" r="${b.r}" fill="url(#${b.sign > 0 ? 'bc' : 'bw'})"/>`);
  }
  for (const b of scene.blooms.slice(0, 6)) {
    const col = b.sign > 0 ? P.cool : P.warm;
    push(`<circle class="sig b${b.bucket}" cx="${b.x}" cy="${b.y}" r="${Math.max(3, b.r * 0.07).toFixed(1)}" fill="${col}" fill-opacity="0.9"/>`);
  }

  if (motif) push('</g>');

  // ---- probes --------------------------------------------------------------
  for (const p of scene.probes) {
    push(`<g class="sig probe b0"><circle cx="${p.x}" cy="${p.y}" r="15" fill="none" stroke="${P.ink}" stroke-width="2.2" stroke-opacity="0.75"/><circle cx="${p.x}" cy="${p.y}" r="4.5" fill="${P.ink}" fill-opacity="0.9"/></g>`);
  }
  // The observer: a receiver, drawn open and never the brightest thing here.
  if (scene.observer) {
    const o = scene.observer;
    push(`<g class="sig b${M.buckets - 1}" opacity="0.6"><circle cx="${o.x}" cy="${o.y}" r="26" fill="none" stroke="${P.muted}" stroke-width="1.6" stroke-dasharray="5 7"/><circle cx="${o.x}" cy="${o.y}" r="3" fill="${P.muted}"/></g>`);
  }

  // ---- the motif -----------------------------------------------------------
  // Above the field (it is the subject) and BELOW the scrims (so the same scan
  // lines, floor, and headline scrim fall across it — an illustration pasted on
  // top of the grain reads as a sticker, not as part of the picture).
  if (motifLayer) push(motifLayer.layer);

  // ---- scrims + grain ------------------------------------------------------
  push(`<rect width="${w}" height="${h}" fill="url(#scan)" opacity="0.5"/>`);
  push(`<rect width="${w}" height="${h}" fill="url(#floor)"/>`);
  push(`<rect width="${w}" height="${h}" fill="url(#scrim)"/>`);

  // ---- type ----------------------------------------------------------------
  push('<g class="type">');
  const eyebrow = [meta.sectionLabel || scene.sectionLabel, meta.date].filter(Boolean).join('   ·   ').toUpperCase();
  push(`<text x="${textLeft}" y="${eyebrowY}" font-family="${esc(T.mono)}" font-size="${T.eyebrow.size}" font-weight="${T.eyebrow.weight}" letter-spacing="${T.eyebrow.tracking}" fill="${P.accent}">${esc(eyebrow)}</text>`);

  head.lines.forEach((line, i) => {
    push(`<text x="${textLeft}" y="${(firstBase + i * lineH).toFixed(1)}" font-family="${esc(T.sans)}" font-size="${head.size}" font-weight="${T.headline.weight}" letter-spacing="${T.headline.tracking}" fill="${P.ink}">${esc(line)}</text>`);
  });

  push(`<rect x="${textLeft}" y="${ruleY}" width="112" height="4" fill="${P.accent}" opacity="0.9"/>`);
  const byline = [meta.author && `by ${meta.author}`, meta.site || 'lifehacker.dev'].filter(Boolean).join('   ·   ');
  push(`<text x="${textLeft}" y="${bylineY}" font-family="${esc(T.mono)}" font-size="${T.byline.size}" font-weight="${T.byline.weight}" letter-spacing="${T.byline.tracking}" fill="${P.muted}">${esc(byline)}</text>`);
  push('</g>');

  push('</svg>');
  return out.join('\n');
}
