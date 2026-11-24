#!/usr/bin/env node
// Generative hero art, one per vault note. Offline and deterministic: the same
// slug always yields the same image, so builds are reproducible and nothing is
// fetched at publish time. The motif is the logo's — a ring that breaks where
// the expectation reverses — seeded into concentric arcs.
// Usage: node engine/scripts/preview.mjs   → assets/images/previews/<slug>.svg
import { readdirSync, writeFileSync, mkdirSync, statSync } from "node:fs";
import { root } from "./lib.mjs";

const OUT = root("assets", "images", "previews");
mkdirSync(OUT, { recursive: true });

const INK = "#1b1b1f";
// Muted, print-like accents. Index chosen by hash, so a note keeps its colour.
const ACCENTS = ["#e8e4d9", "#c9a227", "#7d9a8b", "#b4654a", "#8a8fa3", "#a98c6b"];

const hash = (s) => {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h >>> 0;
};
const rng = (seed) => () => {
  seed = (seed + 0x6d2b79f5) >>> 0;
  let t = seed;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};

// Arc path on a circle, from a1 to a2 degrees.
const arc = (cx, cy, r, a1, a2) => {
  const p = (a) => [cx + r * Math.cos((a * Math.PI) / 180), cy + r * Math.sin((a * Math.PI) / 180)];
  const [x1, y1] = p(a1);
  const [x2, y2] = p(a2);
  const large = Math.abs(a2 - a1) > 180 ? 1 : 0;
  const sweep = a2 > a1 ? 1 : 0;
  return `M${x1.toFixed(1)} ${y1.toFixed(1)}A${r} ${r} 0 ${large} ${sweep} ${x2.toFixed(1)} ${y2.toFixed(1)}`;
};

export function previewSVG(slug) {
  const h = hash(slug);
  const rand = rng(h);
  const accent = ACCENTS[h % ACCENTS.length];
  const cx = 840 + Math.round(rand() * 120 - 60);
  const cy = 315 + Math.round(rand() * 90 - 45);

  const rings = [];
  const count = 5 + (h % 4);
  for (let i = 0; i < count; i++) {
    const r = 70 + i * (26 + Math.round(rand() * 16));
    const start = Math.round(rand() * 360);
    // Each ring is broken — the gap is the reversal.
    const span = 150 + Math.round(rand() * 170);
    const w = i === 0 ? 7 : 1.5 + rand() * 3;
    const op = (0.22 + rand() * 0.55).toFixed(2);
    rings.push(
      `<path d="${arc(cx, cy, r, start, start + span)}" stroke="${accent}" stroke-width="${w.toFixed(1)}" opacity="${op}" stroke-linecap="round"/>`
    );
  }

  // A few drifting marks, so no two entries read as the same plate.
  const motes = [];
  for (let i = 0; i < 12; i++) {
    const x = Math.round(rand() * 1200);
    const y = Math.round(rand() * 630);
    const rr = (rand() * 2.6 + 0.6).toFixed(1);
    motes.push(`<circle cx="${x}" cy="${y}" r="${rr}" fill="${accent}" opacity="${(rand() * 0.3).toFixed(2)}"/>`);
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 630" width="1200" height="630" role="img" aria-label="">
<rect width="1200" height="630" fill="${INK}"/>
<g fill="none">${rings.join("")}</g>
${motes.join("")}
</svg>
`;
}

// Run standalone: render one per note in the vault.
if (import.meta.url === `file://${process.argv[1]}`) {
  const skip = new Set(["templates"]);
  const slugs = [];
  for (const dir of readdirSync(root("vault"))) {
    const full = root("vault", dir);
    if (!statSync(full).isDirectory()) {
      if (dir.endsWith(".md")) slugs.push(dir.replace(/\.md$/, ""));
      continue;
    }
    if (skip.has(dir) || dir.startsWith(".")) continue;
    for (const f of readdirSync(full).filter((f) => f.endsWith(".md"))) slugs.push(f.replace(/\.md$/, ""));
  }
  for (const s of slugs) writeFileSync(`${OUT}/${s.toLowerCase()}.svg`, previewSVG(s), "utf8");
  // Textless fallback for pages that aren't vault notes (browse index, 404).
  // The OG banner carries wordmark text and must never sit behind a page title.
  writeFileSync(`${OUT}/default.svg`, previewSVG("irony-works"), "utf8");
  console.log(`Rendered ${slugs.length + 1} preview images → assets/images/previews/`);
}
