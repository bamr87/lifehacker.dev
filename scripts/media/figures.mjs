#!/usr/bin/env node
// =============================================================================
// scripts/media/figures.mjs — in-body figures for the weekly epic (Trace Figures)
// -----------------------------------------------------------------------------
// The weekly-epic routine (.claude/skills/weekly-epic) illustrates the Top
// Story with figures COMPUTED from the week itself, the same way Trace Bloom
// computes cover art from an article: the digest (scripts/content/
// weekly_digest.rb) is the input, the slug + window seed the composition, and
// the algorithm owns every coordinate — a language model never one-shots path
// data here (docs/PREVIEW-IMAGES.md explains why that rule exists).
//
//   node scripts/media/figures.mjs constellation --digest <digest.json> --slug <epic-slug> [--out <file>]
//   node scripts/media/figures.mjs timeline      --digest <digest.json> --slug <epic-slug> [--out <file>]
//   node scripts/media/figures.mjs gauge         --slug <epic-slug> --value 87.3 --label "Irony Saturation" [--sublabel "…"] [--out <file>]
//
// Defaults write to assets/images/figures/<slug>/<type>.svg. Zero npm packages,
// no network, Node ≥ 18 — the constraints that made Trace Bloom deployable.
//
// The output contract (enforced by scripts/ci/lint_preview.rb `unsafe-svg`):
//   * inert SVG only — no <script>, no <foreignObject>, no <image>, no external
//     href/src. Fonts are system stacks from _data/preview/design.json.
//   * motion is never load-bearing: frame 0 is a complete, balanced image and
//     `prefers-reduced-motion: reduce` stops everything (the house animation
//     contract from scripts/preview/lib/svg.mjs).
//   * deterministic: same digest + same slug → byte-identical SVG, forever.
//     No Date.now(), no unseeded randomness. A regenerated figure is a
//     readable diff or no diff at all.
//
// There is NO fallback rung. Bad input fails loudly with a non-zero exit —
// silently degrading art is the exact failure this repo already paid for once.
// =============================================================================
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { fnv1a, mulberry32, clamp } from '../preview/lib/core.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const DESIGN = JSON.parse(fs.readFileSync(path.join(ROOT, '_data', 'preview', 'design.json'), 'utf8'));
export const GENERATOR = 'trace-figures/1';

// Section palettes come from the SAME token file as the cover art, so a re-skin
// of the site re-skins the figures on the next regeneration. The epic itself is
// a Field Note, so figures sit on the field-notes substrate colors while each
// plotted article keeps its own section's accent.
const SECTIONS = ['hacks', 'tools', 'field-notes', 'wire', 'docs'];
const PAL = (s) => (DESIGN.sections[s] || DESIGN.sections['field-notes']).palette;
const BASE = PAL('field-notes');
const MONO = DESIGN.type.mono;
const SANS = DESIGN.type.sans;

const r1 = (v) => Math.round(v * 10) / 10;
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;')
  .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const trunc = (s, n) => (s.length <= n ? s : `${s.slice(0, n - 1).trimEnd()}…`);
const die = (msg) => { console.error(`[trace-figures] ERROR: ${msg}`); process.exit(1); };

// ---- shared chrome ----------------------------------------------------------
// Every figure opens with the same accessibility + provenance envelope the
// banners carry: role="img", a real <title>/<desc>, data-generator, data-seed.
function svgOpen({ w, h, title, desc, seed }) {
  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w} ${h}" width="${w}" height="${h}" role="img" aria-labelledby="t d" data-generator="${GENERATOR}" data-seed="${seed}">`,
    `<title id="t">${esc(title)}</title>`,
    `<desc id="d">${esc(desc)}</desc>`,
  ].join('\n');
}

// Frame 0 must be complete: `from` states are dimmed-but-present, never empty,
// and every animation dies under prefers-reduced-motion. Same contract, same
// class names shape, as the Trace Bloom banners.
function motionStyle(extra = '') {
  return `<style>
@keyframes tf-breathe{0%,100%{opacity:.62}50%{opacity:1}}
@keyframes tf-drift{to{stroke-dashoffset:-160}}
@keyframes tf-shimmer{0%,100%{opacity:.1}50%{opacity:.3}}
.tfb{animation:tf-breathe 7s ease-in-out infinite}
.tfe{animation:tf-drift 9s linear infinite}
.tfs{animation:tf-shimmer 8s ease-in-out infinite}
${extra}@media (prefers-reduced-motion:reduce){.tfb,.tfe,.tfs{animation:none!important;opacity:1!important}}
</style>`;
}

function bgDefs(w, h) {
  return `<defs>
<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="${BASE.bg0}"/><stop offset="1" stop-color="${BASE.bg1}"/></linearGradient>
${SECTIONS.map((s) => `<radialGradient id="halo-${s}">
<stop offset="0" stop-color="${PAL(s).accent}" stop-opacity="0.9"/>
<stop offset="0.35" stop-color="${PAL(s).accent}" stop-opacity="0.28"/>
<stop offset="1" stop-color="${PAL(s).accent}" stop-opacity="0"/></radialGradient>`).join('\n')}
</defs>
<rect width="${w}" height="${h}" fill="url(#bg)"/>`;
}

function caption(w, h, left, right) {
  return `<text x="48" y="${h - 34}" font-family="${MONO}" font-size="22" letter-spacing="2" fill="${BASE.muted}">${esc(left)}</text>
<text x="${w - 48}" y="${h - 34}" text-anchor="end" font-family="${MONO}" font-size="22" letter-spacing="2" fill="${BASE.muted}">${esc(right)}</text>`;
}

function legend(items, x, y) {
  let out = ''; let cx = x;
  for (const [section, count] of items) {
    if (!count) continue;
    const label = `${(DESIGN.sections[section] || {}).label || section} ×${count}`.toUpperCase();
    out += `<circle cx="${cx}" cy="${y - 7}" r="7" fill="${PAL(section).accent}"/>`
      + `<text x="${cx + 16}" y="${y}" font-family="${MONO}" font-size="21" letter-spacing="1" fill="${BASE.muted}">${esc(label)}</text>`;
    cx += 16 + label.length * 13 + 46;
  }
  return out;
}

function loadDigest(file) {
  if (!file) die('--digest <weekly_digest.rb output> is required for this figure');
  if (!fs.existsSync(file)) die(`digest not found: ${file}`);
  const d = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!d || !Array.isArray(d.items)) die(`digest has no items[] array: ${file}`);
  if (d.items.length === 0) die('digest is empty — there is no week to draw');
  for (const it of d.items) {
    if (!it.title || !it.section || !it.date) die(`digest item missing title/section/date: ${JSON.stringify(it)}`);
  }
  return d;
}

// ---- constellation: the week as a field ------------------------------------
// One node per published article, sized by its word count, colored by its
// section; an edge wherever two articles share a tag. The composition is the
// week's real topology — clustered when the fleet obsessed, scattered when it
// wandered. One receive-only node is dimmer than the rest and connected to
// nothing: the observer probe (docs/TRACE-BLOOM.md, "the conceptual seed").
function constellation(digest, slug) {
  const w = 1536; const h = 1024;
  const items = digest.items;
  const seed = fnv1a(`${slug}|constellation|${digest.window.since}|${digest.window.until}`);
  const rand = mulberry32(seed);

  // Seeded scatter inside the plot box, then a few repulsion passes so labels
  // breathe. The box leaves a header strip and a legend strip alone.
  const box = { x0: 120, y0: 170, x1: w - 150, y1: h - 170 };
  const nodes = items.map((it, i) => {
    const golden = (i * 2.399963) % (Math.PI * 2);
    const cx = (box.x0 + box.x1) / 2; const cy = (box.y0 + box.y1) / 2;
    const rr = (0.18 + 0.8 * rand()) * Math.min(box.x1 - cx, box.y1 - cy);
    return {
      it, i,
      x: clamp(cx + Math.cos(golden) * rr * 1.35, box.x0, box.x1),
      y: clamp(cy + Math.sin(golden) * rr, box.y0, box.y1),
      r: clamp(15 + Math.sqrt(it.word_count || 400) * 0.62, 17, 44),
    };
  });
  for (let pass = 0; pass < 60; pass++) {
    for (let a = 0; a < nodes.length; a++) {
      for (let b = a + 1; b < nodes.length; b++) {
        const A = nodes[a]; const B = nodes[b];
        const dx = B.x - A.x; const dy = B.y - A.y;
        const d = Math.hypot(dx, dy) || 1;
        const min = A.r + B.r + 96;
        if (d >= min) continue;
        const push = (min - d) / 2;
        const ux = dx / d; const uy = dy / d;
        A.x = clamp(A.x - ux * push, box.x0, box.x1); A.y = clamp(A.y - uy * push, box.y0, box.y1);
        B.x = clamp(B.x + ux * push, box.x0, box.x1); B.y = clamp(B.y + uy * push, box.y0, box.y1);
      }
    }
  }

  // Edges: shared tags, strongest first, at most 3 per node — a constellation,
  // not a hairball.
  const cand = [];
  for (let a = 0; a < nodes.length; a++) {
    for (let b = a + 1; b < nodes.length; b++) {
      const shared = (nodes[a].it.tags || []).filter((t) => (nodes[b].it.tags || []).includes(t));
      if (shared.length) cand.push({ a, b, wgt: shared.length, tag: shared[0] });
    }
  }
  cand.sort((p, q) => q.wgt - p.wgt || p.a - q.a || p.b - q.b);
  const degree = new Array(nodes.length).fill(0);
  const edges = cand.filter(({ a, b }) => {
    if (degree[a] >= 3 || degree[b] >= 3) return false;
    degree[a] += 1; degree[b] += 1; return true;
  });

  const out = [svgOpen({
    w, h, seed,
    title: `The week as a constellation — ${digest.window.since} to ${digest.window.until}`,
    desc: `${items.length} articles published this week, plotted as a field: node size is word count, ` +
      'color is section, and an edge means two articles share a tag. Computed from the committed weekly digest.',
  })];
  out.push(motionStyle());
  out.push(bgDefs(w, h));

  // Header strip.
  out.push(`<text x="48" y="76" font-family="${MONO}" font-size="26" font-weight="600" letter-spacing="6" fill="${BASE.accent}">THE WEEK, AS A FIELD</text>`);
  out.push(`<text x="48" y="122" font-family="${SANS}" font-size="30" fill="${BASE.ink}" opacity="0.85">Every dispatch we shipped, and every thread between them</text>`);

  // Edges under nodes: curved, dash-drifting. The curve bows perpendicular to
  // the chord by a seeded amount so no two links read as the same wire.
  for (const e of edges) {
    const A = nodes[e.a]; const B = nodes[e.b];
    const mx = (A.x + B.x) / 2; const my = (A.y + B.y) / 2;
    const dx = B.x - A.x; const dy = B.y - A.y;
    const d = Math.hypot(dx, dy) || 1;
    const bow = (rand() - 0.5) * clamp(d * 0.3, 30, 130);
    const cxx = mx - (dy / d) * bow; const cyy = my + (dx / d) * bow;
    const colA = PAL(A.it.section).accent;
    out.push(`<path d="M${r1(A.x)} ${r1(A.y)}Q${r1(cxx)} ${r1(cyy)} ${r1(B.x)} ${r1(B.y)}" fill="none" stroke="${colA}" stroke-opacity="${e.wgt > 1 ? 0.55 : 0.3}" stroke-width="${e.wgt > 1 ? 3 : 2}" stroke-dasharray="7 9" class="tfe"/>`);
  }

  // The observer probe: emits nothing, receives everything, labelled never.
  const ox = box.x1 - 30; const oy = box.y0 + (box.y1 - box.y0) * (0.25 + rand() * 0.5);
  out.push(`<circle cx="${r1(ox)}" cy="${r1(oy)}" r="11" fill="none" stroke="${BASE.muted}" stroke-opacity="0.55" stroke-width="2"/>`);
  out.push(`<circle cx="${r1(ox)}" cy="${r1(oy)}" r="3.5" fill="${BASE.muted}" fill-opacity="0.55"/>`);

  // Labels: place each under its node, then resolve collisions greedily — flip
  // a colliding label above its node, and if that collides too, step it away
  // until it clears. Deterministic (nodes are walked in item order), and the
  // reason the bottom of the canvas never shows two titles typeset into each
  // other (the first eyeballed render did exactly that).
  const placed = [];
  const labels = nodes.map((n) => {
    const label = trunc(n.it.title, 30);
    const bw = label.length * 12.2 + 12; const bh = 26;
    const lx = clamp(n.x, box.x0 + 40, w - 250);
    const below = n.y + n.r * 0.42 + 34; const above = n.y - n.r * 0.42 - 22;
    const hits = (x, y) => placed.some((b) => Math.abs(x - b.x) * 2 < bw + b.w && Math.abs(y - b.y) * 2 < bh + b.h);
    let ly = below;
    if (hits(lx, ly)) ly = above;
    for (let k = 0; hits(lx, ly) && k < 8; k++) ly += 28;
    placed.push({ x: lx, y: ly, w: bw, h: bh });
    return { n, label, lx, ly };
  });

  nodes.forEach((n, idx) => {
    const p = PAL(n.it.section);
    const delay = ((idx % 7) * 0.9).toFixed(1);
    out.push(`<g class="tfb" style="animation-delay:${delay}s">`);
    out.push(`<circle cx="${r1(n.x)}" cy="${r1(n.y)}" r="${r1(n.r * 2.1)}" fill="url(#halo-${n.it.section})"/>`);
    out.push(`<circle cx="${r1(n.x)}" cy="${r1(n.y)}" r="${r1(n.r * 0.42)}" fill="${p.accent}"/>`);
    out.push(`<circle cx="${r1(n.x)}" cy="${r1(n.y)}" r="${r1(n.r * 0.42 + 6)}" fill="none" stroke="${p.accent}" stroke-opacity="0.5" stroke-width="1.5"/>`);
    out.push('</g>');
  });
  for (const { label, lx, ly } of labels) {
    out.push(`<text x="${r1(lx)}" y="${r1(ly)}" text-anchor="middle" font-family="${MONO}" font-size="20" fill="${BASE.ink}" fill-opacity="0.82">${esc(label)}</text>`);
  }

  const counts = SECTIONS.map((s) => [s, items.filter((i) => i.section === s).length]);
  out.push(legend(counts, 48, h - 88));
  out.push(caption(w, h, `SEED ${seed}`, `${digest.window.since} → ${digest.window.until} · ${items.length} DISPATCHES`));
  out.push('</svg>');
  return out.join('\n');
}

// ---- timeline: seven days of shipping ---------------------------------------
// One column per day of the window, one dot per article (its section's color,
// stacked in publish order), the day's count on top. The shimmer band pans the
// week once every 8s; at rest it is simply a lit chart.
function timeline(digest, slug) {
  const w = 1536; const h = 640;
  const seed = fnv1a(`${slug}|timeline|${digest.window.since}|${digest.window.until}`);
  const days = [];
  const start = new Date(`${digest.window.since}T00:00:00Z`);
  const end = new Date(`${digest.window.until}T00:00:00Z`);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) die('digest window.since/until are not YYYY-MM-DD dates');
  for (let t = start.getTime(); t <= end.getTime(); t += 86400000) days.push(new Date(t));
  if (days.length > 21) die(`window is ${days.length} days — a weekly timeline draws at most 21`);

  const byDay = days.map((d) => {
    const key = d.toISOString().slice(0, 10);
    return { key, d, items: digest.items.filter((it) => String(it.date).slice(0, 10) === key) };
  });
  const names = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  const left = 110; const right = w - 80; const baseY = h - 170; const colW = (right - left) / days.length;

  const out = [svgOpen({
    w, h, seed,
    title: `Seven days of shipping — ${digest.window.since} to ${digest.window.until}`,
    desc: `Publication timeline for the week: ${digest.items.length} articles as dots, one column per day, ` +
      'colored by section, stacked in publish order. Computed from the committed weekly digest.',
  })];
  out.push(motionStyle(`@keyframes tf-pan{from{transform:translateX(0)}to{transform:translateX(${w - 320}px)}}
.tfp{animation:tf-shimmer 8s ease-in-out infinite,tf-pan 16s linear infinite alternate}
@media (prefers-reduced-motion:reduce){.tfp{animation:none!important;opacity:.12!important}}
`));
  out.push(bgDefs(w, h));
  // The shimmer band fades at both edges — a hard-edged rectangle drifting
  // across a dark field reads as a rendering bug, not weather.
  out.push(`<defs><linearGradient id="band" x1="0" y1="0" x2="1" y2="0">
<stop offset="0" stop-color="${BASE.cool}" stop-opacity="0"/>
<stop offset="0.5" stop-color="${BASE.cool}" stop-opacity="1"/>
<stop offset="1" stop-color="${BASE.cool}" stop-opacity="0"/></linearGradient></defs>`);
  out.push(`<rect x="60" y="0" width="300" height="${h}" fill="url(#band)" opacity="0.1" class="tfp"/>`);

  out.push(`<text x="48" y="76" font-family="${MONO}" font-size="26" font-weight="600" letter-spacing="6" fill="${BASE.accent}">SEVEN DAYS OF SHIPPING</text>`);
  out.push(`<line x1="${left - 30}" y1="${baseY + 26}" x2="${right + 10}" y2="${baseY + 26}" stroke="${BASE.grid}" stroke-width="2"/>`);

  byDay.forEach((day, di) => {
    const cx = left + colW * di + colW / 2;
    const label = `${names[day.d.getUTCDay()]} ${day.key.slice(5)}`;
    out.push(`<text x="${r1(cx)}" y="${baseY + 66}" text-anchor="middle" font-family="${MONO}" font-size="21" fill="${BASE.muted}">${esc(label)}</text>`);
    if (!day.items.length) {
      out.push(`<circle cx="${r1(cx)}" cy="${baseY}" r="4" fill="${BASE.grid}"/>`);
      return;
    }
    day.items.forEach((it, ii) => {
      const cy = baseY - 22 - ii * 44;
      const p = PAL(it.section);
      out.push(`<g class="tfb" style="animation-delay:${((di * 0.5 + ii * 0.25) % 6).toFixed(2)}s">`);
      out.push(`<circle cx="${r1(cx)}" cy="${r1(cy)}" r="26" fill="url(#halo-${it.section})"/>`);
      out.push(`<circle cx="${r1(cx)}" cy="${r1(cy)}" r="12" fill="${p.accent}"><title>${esc(it.title)}</title></circle>`);
      out.push('</g>');
    });
    out.push(`<text x="${r1(cx)}" y="${baseY - 22 - day.items.length * 44 - 18}" text-anchor="middle" font-family="${MONO}" font-size="24" font-weight="600" fill="${BASE.ink}">${day.items.length}</text>`);
  });

  const counts = SECTIONS.map((s) => [s, digest.items.filter((i) => i.section === s).length]);
  out.push(legend(counts, 48, h - 76));
  out.push(caption(w, h, `SEED ${seed}`, `${digest.items.length} DISPATCHES / ${days.length} DAYS`));
  out.push('</svg>');
  return out.join('\n');
}

// ---- gauge: absurd precision, deadpanned ------------------------------------
// A dial for whatever the bard claims to have measured ("Irony Saturation,
// 87.3%"). The needle RESTS at the value — frame 0 is the verdict, the breathe
// is a gift — and the sublabel is where the joke walks itself back honestly.
function gauge(slug, { value, label, sublabel }) {
  const w = 1024; const h = 720;
  const v = Number(value);
  if (!Number.isFinite(v) || v < 0 || v > 100) die(`--value must be a number in 0..100 (got: ${value})`);
  if (!label) die('--label is required for a gauge (what did we allegedly measure?)');
  const seed = fnv1a(`${slug}|gauge|${label}|${v}`);
  const cx = w / 2; const cy = h - 190; const R = 300;
  const a0 = Math.PI * 1.2; const a1 = -Math.PI * 0.2; // 210° → -36°, a classic dial sweep
  const ang = (t) => a0 + (a1 - a0) * t;
  const px = (a, rr) => r1(cx + Math.cos(a) * rr);
  const py = (a, rr) => r1(cy - Math.sin(a) * rr);

  const out = [svgOpen({
    w, h, seed,
    title: `${label}: ${v}%`,
    desc: `A satirical measurement dial reading ${v} percent for “${label}”. ${sublabel || ''}`.trim(),
  })];
  out.push(motionStyle());
  out.push(bgDefs(w, h));
  out.push(`<defs><linearGradient id="arc" x1="0" y1="1" x2="1" y2="0">
<stop offset="0" stop-color="${BASE.cool}"/><stop offset="1" stop-color="${BASE.warm}"/></linearGradient></defs>`);

  // Track + lit arc up to the value.
  const arc = (t0, t1, rr) => `M${px(ang(t0), rr)} ${py(ang(t0), rr)} A${rr} ${rr} 0 ${(t1 - t0) > 0.5 ? 1 : 0} 1 ${px(ang(t1), rr)} ${py(ang(t1), rr)}`;
  out.push(`<path d="${arc(0, 1, R)}" fill="none" stroke="${BASE.grid}" stroke-width="26" stroke-linecap="round"/>`);
  out.push(`<path d="${arc(0, v / 100, R)}" fill="none" stroke="url(#arc)" stroke-width="26" stroke-linecap="round" class="tfb"/>`);

  // Ticks every 10; numerals every 20 EXCEPT the endpoints — 0 and 100 land at
  // the bottom of the sweep, straight into the reading and the sublabel.
  for (let t = 0; t <= 100; t += 10) {
    const a = ang(t / 100);
    out.push(`<line x1="${px(a, R - 36)}" y1="${py(a, R - 36)}" x2="${px(a, R - 58)}" y2="${py(a, R - 58)}" stroke="${BASE.muted}" stroke-width="${t % 20 ? 2 : 4}"/>`);
    if (t % 20 === 0 && t > 0 && t < 100) out.push(`<text x="${px(a, R - 92)}" y="${py(a, R - 92)}" text-anchor="middle" dominant-baseline="middle" font-family="${MONO}" font-size="24" fill="${BASE.muted}">${t}</text>`);
  }

  // Needle at rest on the reading.
  const na = ang(v / 100);
  out.push(`<circle cx="${cx}" cy="${cy}" r="70" fill="url(#halo-field-notes)"/>`);
  out.push(`<line x1="${px(na, 24)}" y1="${py(na, 24)}" x2="${px(na, R - 70)}" y2="${py(na, R - 70)}" stroke="${BASE.ink}" stroke-width="7" stroke-linecap="round"/>`);
  out.push(`<circle cx="${cx}" cy="${cy}" r="16" fill="${BASE.accent}"/>`);

  // The reading, absurdly precise; the label; the walk-back.
  out.push(`<text x="${cx}" y="${cy + 108}" text-anchor="middle" font-family="${MONO}" font-size="96" font-weight="700" fill="${BASE.ink}">${esc(String(v))}<tspan font-size="52" fill="${BASE.muted}">%</tspan></text>`);
  out.push(`<text x="${cx}" y="130" text-anchor="middle" font-family="${MONO}" font-size="30" font-weight="600" letter-spacing="6" fill="${BASE.accent}">${esc(label.toUpperCase())}</text>`);
  if (sublabel) out.push(`<text x="${cx}" y="${h - 30}" text-anchor="middle" font-family="${SANS}" font-size="24" fill="${BASE.muted}">${esc(sublabel)}</text>`);
  out.push('</svg>');
  return out.join('\n');
}

// ---- CLI --------------------------------------------------------------------
function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    if (!argv[i].startsWith('--')) die(`unexpected argument: ${argv[i]}`);
    args[argv[i].slice(2)] = argv[i + 1];
    i += 1;
  }
  return args;
}

const USAGE = `usage:
  figures.mjs constellation --digest <digest.json> --slug <epic-slug> [--out <file>]
  figures.mjs timeline      --digest <digest.json> --slug <epic-slug> [--out <file>]
  figures.mjs gauge         --slug <epic-slug> --value <0..100> --label <text> [--sublabel <text>] [--out <file>]`;

function main() {
  const [cmd, ...rest] = process.argv.slice(2);
  if (!cmd || cmd === '--help' || cmd === '-h') { console.log(USAGE); process.exit(cmd ? 0 : 2); }
  const args = parseArgs(rest);
  const slug = args.slug;
  if (!slug || !/^[a-z0-9-]+$/.test(slug)) die('--slug <epic-article-slug> is required (lowercase, hyphenated)');

  let svg;
  if (cmd === 'constellation') svg = constellation(loadDigest(args.digest), slug);
  else if (cmd === 'timeline') svg = timeline(loadDigest(args.digest), slug);
  else if (cmd === 'gauge') svg = gauge(slug, args);
  else die(`unknown figure type: ${cmd}\n${USAGE}`);

  const outFile = args.out || path.join(ROOT, 'assets', 'images', 'figures', slug, `${cmd}.svg`);
  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  fs.writeFileSync(outFile, svg);
  console.log(`[trace-figures] ✓ ${path.relative(ROOT, outFile)} (${(svg.length / 1024).toFixed(1)} kB)`);
}

main();
