#!/usr/bin/env node
// Builds docs/preview-lab.html — the interactive Trace Bloom explorer.
//
// The lab INLINES the real renderer (lib/core.mjs + lib/svg.mjs + the design
// tokens) rather than re-implementing it in p5. An explorer that carries its own
// copy of the algorithm drifts from production within a week and then quietly
// lies to whoever is tuning it; this one cannot, because it is the same code.
// Re-run after touching lib/ or _data/preview/design.json:
//
//   node scripts/preview/build-lab.mjs

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..', '..');

const design = fs.readFileSync(path.join(ROOT, '_data/preview/design.json'), 'utf8');
const core = fs.readFileSync(path.join(HERE, 'lib/core.mjs'), 'utf8');
// svg.mjs imports the motif compositor, so the lab has to carry it too — an
// explorer missing half the renderer is exactly the drift this inlining exists
// to prevent, even though the lab itself never passes a motif.
const motif = fs.readFileSync(path.join(HERE, 'lib/motif.mjs'), 'utf8');
const svg = fs.readFileSync(path.join(HERE, 'lib/svg.mjs'), 'utf8');

/** Flatten an ES module into inline-script scope: drop imports, drop `export`. */
const inline = (src) => src
  .replace(/^import[\s\S]*?from\s+['"][^'"]+['"];\s*$/gm, '')
  .replace(/^export\s+/gm, '');

const ALGORITHM = `${inline(core)}\n${inline(motif)}\n${inline(svg)}`;

const HTML = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trace Bloom — Preview Lab</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.7.0/p5.min.js"><\/script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600&family=Lora:wght@400;500&display=swap" rel="stylesheet">
    <style>
        /* Anthropic Brand Colors */
        :root {
            --anthropic-dark: #141413;
            --anthropic-light: #faf9f5;
            --anthropic-mid-gray: #b0aea5;
            --anthropic-light-gray: #e8e6dc;
            --anthropic-orange: #d97757;
            --anthropic-blue: #6a9bcc;
            --anthropic-green: #788c5d;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, var(--anthropic-light) 0%, #f5f3ee 100%);
            min-height: 100vh; color: var(--anthropic-dark);
        }
        .container { display: flex; min-height: 100vh; padding: 20px; gap: 20px; }
        .sidebar {
            width: 320px; flex-shrink: 0; background: rgba(255,255,255,0.95);
            backdrop-filter: blur(10px); padding: 24px; border-radius: 12px;
            box-shadow: 0 10px 30px rgba(20,20,19,0.1); overflow-y: auto; overflow-x: hidden;
        }
        .sidebar h1 { font-family: 'Lora', serif; font-size: 24px; font-weight: 500; margin-bottom: 8px; }
        .sidebar .subtitle { color: var(--anthropic-mid-gray); font-size: 14px; margin-bottom: 32px; line-height: 1.4; }
        .control-section { margin-bottom: 32px; }
        .control-section h3 {
            font-size: 16px; font-weight: 600; margin-bottom: 16px;
            display: flex; align-items: center; gap: 8px;
        }
        .control-section h3::before { content: '•'; color: var(--anthropic-orange); font-weight: bold; }
        .seed-input {
            width: 100%; background: var(--anthropic-light); padding: 12px; border-radius: 8px;
            font-family: 'Courier New', monospace; font-size: 14px; margin-bottom: 12px;
            border: 1px solid var(--anthropic-light-gray); text-align: center;
        }
        .seed-input:focus {
            outline: none; border-color: var(--anthropic-orange);
            box-shadow: 0 0 0 2px rgba(217,119,87,0.1); background: white;
        }
        .seed-controls { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 8px; }
        .regen-button { margin-bottom: 0; }
        .control-group { margin-bottom: 20px; }
        .control-group label { display: block; font-size: 14px; font-weight: 500; margin-bottom: 8px; }
        .slider-container { display: flex; align-items: center; gap: 12px; }
        .slider-container input[type="range"] {
            flex: 1; height: 4px; background: var(--anthropic-light-gray);
            border-radius: 2px; outline: none; -webkit-appearance: none;
        }
        .slider-container input[type="range"]::-webkit-slider-thumb {
            -webkit-appearance: none; width: 16px; height: 16px; background: var(--anthropic-orange);
            border-radius: 50%; cursor: pointer; transition: all 0.2s ease;
        }
        .slider-container input[type="range"]::-webkit-slider-thumb:hover { transform: scale(1.1); background: #c86641; }
        .slider-container input[type="range"]::-moz-range-thumb {
            width: 16px; height: 16px; background: var(--anthropic-orange);
            border-radius: 50%; border: none; cursor: pointer;
        }
        .value-display {
            font-family: 'Courier New', monospace; font-size: 12px;
            color: var(--anthropic-mid-gray); min-width: 60px; text-align: right;
        }
        .text-input {
            width: 100%; padding: 10px; border-radius: 6px; font-size: 13px;
            border: 1px solid var(--anthropic-light-gray); background: var(--anthropic-light);
            font-family: 'Poppins', sans-serif;
        }
        .text-input:focus { outline: none; border-color: var(--anthropic-orange); background: #fff; }
        .button {
            background: var(--anthropic-orange); color: white; border: none; padding: 10px 16px;
            border-radius: 6px; font-size: 14px; font-weight: 500; cursor: pointer;
            transition: all 0.2s ease; width: 100%;
        }
        .button:hover { background: #c86641; transform: translateY(-1px); }
        .button:active { transform: translateY(0); }
        .button.secondary { background: var(--anthropic-blue); }
        .button.secondary:hover { background: #5a8bb8; }
        .button.tertiary { background: var(--anthropic-green); }
        .button.tertiary:hover { background: #6b7b52; }
        .button-row { display: flex; gap: 8px; margin-bottom: 8px; }
        .button-row .button { flex: 1; }
        .seg { display: grid; grid-template-columns: 1fr 1fr; gap: 6px; }
        .seg button {
            padding: 9px 6px; border: 1px solid var(--anthropic-light-gray); background: #fff;
            border-radius: 6px; cursor: pointer; font-size: 12px; font-family: 'Poppins', sans-serif;
            transition: all .15s ease;
        }
        .seg button.on { background: var(--anthropic-dark); color: #fff; border-color: var(--anthropic-dark); }
        .readout {
            font-family: 'Courier New', monospace; font-size: 11px; line-height: 1.7;
            color: var(--anthropic-mid-gray); background: var(--anthropic-light);
            padding: 10px; border-radius: 6px; white-space: pre-wrap;
        }
        .canvas-area { flex: 1; display: flex; align-items: center; justify-content: center; min-width: 0; }
        #canvas-container {
            width: 100%; max-width: 1000px; border-radius: 12px; overflow: hidden;
            box-shadow: 0 20px 40px rgba(20,20,19,0.1); background: white;
        }
        #canvas-container canvas { display: block; width: 100% !important; height: auto !important; }
        .loading { display: flex; align-items: center; justify-content: center; font-size: 18px; color: var(--anthropic-mid-gray); }
        @media (max-width: 600px) {
            .container { flex-direction: column; }
            .sidebar { width: 100%; }
            .canvas-area { padding: 20px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="sidebar">
            <h1>Trace Bloom</h1>
            <div class="subtitle">Preview Lab — sweep the seed space behind lifehacker.dev's cover art. This page runs the production renderer, not a copy of it.</div>

            <!-- Seed -->
            <div class="control-section">
                <h3>Seed</h3>
                <input type="number" id="seed-input" class="seed-input" value="12345" onchange="updateSeed()">
                <div class="seed-controls">
                    <button class="button secondary" onclick="previousSeed()">← Prev</button>
                    <button class="button secondary" onclick="nextSeed()">Next →</button>
                </div>
                <button class="button tertiary regen-button" onclick="randomSeedAndUpdate()">↻ Random</button>
            </div>

            <!-- Article -->
            <div class="control-section">
                <h3>Article</h3>
                <div class="control-group">
                    <label>Headline</label>
                    <input type="text" id="titleInput" class="text-input"
                           value="Order your Dockerfile so the layer cache does its job"
                           oninput="setTitle(this.value)">
                </div>
                <div class="control-group">
                    <label>Section (substrate + palette)</label>
                    <div class="seg" id="sectionSeg"></div>
                </div>
                <button class="button secondary" onclick="seedFromTitle()">Seed from headline</button>
            </div>

            <!-- Parameters -->
            <div class="control-section">
                <h3>Parameters</h3>
                <div class="control-group">
                    <label>Density — lattice nodes</label>
                    <div class="slider-container">
                        <input type="range" id="density" min="10" max="30" step="1" value="19" oninput="updateParam('density', this.value)">
                        <span class="value-display" id="density-value">19</span>
                    </div>
                </div>
                <div class="control-group">
                    <label>Probes — emitters</label>
                    <div class="slider-container">
                        <input type="range" id="probes" min="1" max="6" step="1" value="3" oninput="updateParam('probes', this.value)">
                        <span class="value-display" id="probes-value">3</span>
                    </div>
                </div>
                <div class="control-group">
                    <label>Decay — failure ⟷ steady state</label>
                    <div class="slider-container">
                        <input type="range" id="decay" min="0.08" max="0.6" step="0.01" value="0.3" oninput="updateParam('decay', this.value)">
                        <span class="value-display" id="decay-value">0.30</span>
                    </div>
                </div>
                <div class="control-group">
                    <label>Interference — bloom focus</label>
                    <div class="slider-container">
                        <input type="range" id="interference" min="0.2" max="1.4" step="0.05" value="0.8" oninput="updateParam('interference', this.value)">
                        <span class="value-display" id="interference-value">0.80</span>
                    </div>
                </div>
                <div class="control-group">
                    <label>Relax — survey passes</label>
                    <div class="slider-container">
                        <input type="range" id="relax" min="0" max="8" step="1" value="3" oninput="updateParam('relax', this.value)">
                        <span class="value-display" id="relax-value">3</span>
                    </div>
                </div>
                <div class="control-group">
                    <label>Drift — off true</label>
                    <div class="slider-container">
                        <input type="range" id="drift" min="0" max="1" step="0.02" value="0.32" oninput="updateParam('drift', this.value)">
                        <span class="value-display" id="drift-value">0.32</span>
                    </div>
                </div>
                <div class="control-group">
                    <label>Bloom — focal drama</label>
                    <div class="slider-container">
                        <input type="range" id="bloom" min="0.3" max="2" step="0.05" value="0.9" oninput="updateParam('bloom', this.value)">
                        <span class="value-display" id="bloom-value">0.90</span>
                    </div>
                </div>
            </div>

            <!-- Readout -->
            <div class="control-section">
                <h3>Scene</h3>
                <div class="readout" id="readout">—</div>
            </div>

            <!-- Actions -->
            <div class="control-section">
                <h3>Actions</h3>
                <div class="button-row">
                    <button class="button" onclick="regenerate()">Regenerate</button>
                    <button class="button" onclick="resetParameters()">Reset</button>
                </div>
                <div class="button-row">
                    <button class="button secondary" onclick="downloadPNG()">Download PNG</button>
                    <button class="button tertiary" onclick="downloadSVG()">Download SVG</button>
                </div>
            </div>
        </div>

        <div class="canvas-area">
            <div id="canvas-container"><div class="loading">Initializing generative art…</div></div>
        </div>
    </div>

<script type="module">
// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTION RENDERER — inlined verbatim from scripts/preview/lib/{core,svg}.mjs
// by scripts/preview/build-lab.mjs. Do not edit here; edit there and rebuild.
// ═══════════════════════════════════════════════════════════════════════════
${ALGORITHM}

const DESIGN = ${design};

// ═══════════════════════════════════════════════════════════════════════════
// LAB STATE
// ═══════════════════════════════════════════════════════════════════════════
const SECTIONS = Object.keys(DESIGN.sections);

let params = {
  seed: 12345, section: 'hacks', lattice: DESIGN.sections.hacks.lattice,
  density: 19, probes: 3, decay: 0.30, interference: 0.80,
  relax: 3, drift: 0.32, bloom: 0.90, tone: 'even',
};
let defaultParams = { ...params };
let title = 'Order your Dockerfile so the layer cache does its job';
let scene = null;
let sketch = null;

function meta() {
  return {
    title,
    date: new Date().toISOString().slice(0, 10),
    author: 'claude',
    sectionLabel: DESIGN.sections[params.section].label,
  };
}

function rebuild() {
  params.lattice = DESIGN.sections[params.section].lattice;
  scene = buildScene(params, DESIGN);
  const r = document.getElementById('readout');
  r.textContent =
    'seed      ' + params.seed + '\\n' +
    'lattice   ' + params.lattice + '\\n' +
    'nodes     ' + scene.nodes.length + '\\n' +
    'edges     ' + scene.edges.length + '\\n' +
    'blooms    ' + scene.blooms.length + '\\n' +
    'probes    ' + scene.probes.length + ' (+1 observer)';
  if (sketch) sketch.redraw();
}

// ═══════════════════════════════════════════════════════════════════════════
// P5 — draws the same scene the SVG emitter writes
// ═══════════════════════════════════════════════════════════════════════════
const TIERS = [
  { min: 0.78, width: 4.4, alpha: 255 },
  { min: 0.46, width: 2.6, alpha: 217 },
  { min: 0.18, width: 1.7, alpha: 153 },
];

new p5((p) => {
  sketch = p;
  p.setup = () => {
    const c = p.createCanvas(DESIGN.canvas.width, DESIGN.canvas.height);
    c.parent('canvas-container');
    p.noLoop();
    const l = document.querySelector('.loading');
    if (l) l.style.display = 'none';
    rebuild();
  };

  p.draw = () => {
    if (!scene) return;
    const P = scene.palette, W = p.width, H = p.height;
    const ctx = p.drawingContext;

    const bg = ctx.createLinearGradient(0, 0, W, H);
    bg.addColorStop(0, P.bg0); bg.addColorStop(1, P.bg1);
    ctx.fillStyle = bg; ctx.fillRect(0, 0, W, H);

    // substrate
    p.stroke(p.color(P.grid)); p.strokeWeight(1.5); p.noFill();
    for (const e of scene.edges) p.line(e.x1, e.y1, e.x2, e.y2);

    // signal
    for (const e of scene.edges) {
      const tier = TIERS.findIndex((t) => e.lit >= t.min);
      if (tier === -1) continue;
      const t = TIERS[tier];
      const col = p.color(mix(P.grid, e.sign > 0 ? P.cool : P.warm,
        clamp(0.55 + (2 - tier) * 0.22, 0, 1)));
      col.setAlpha(t.alpha);
      p.stroke(col); p.strokeWeight(t.width);
      p.line(e.x1, e.y1, e.x2, e.y2);
    }

    // blooms
    p.noStroke();
    for (const b of scene.blooms) {
      const base = b.sign > 0 ? P.cool : P.warm;
      const g = ctx.createRadialGradient(b.x, b.y, 0, b.x, b.y, b.r);
      g.addColorStop(0, hexA(base, 0.95));
      g.addColorStop(0.18, hexA(base, 0.5));
      g.addColorStop(0.5, hexA(base, 0.14));
      g.addColorStop(1, hexA(base, 0));
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2); ctx.fill();
    }
    for (const b of scene.blooms.slice(0, 6)) {
      ctx.fillStyle = hexA(b.sign > 0 ? P.cool : P.warm, 0.9);
      ctx.beginPath(); ctx.arc(b.x, b.y, Math.max(3, b.r * 0.07), 0, Math.PI * 2); ctx.fill();
    }

    // probes + observer
    for (const pr of scene.probes) {
      p.noFill(); p.stroke(hexA(P.ink, 0.75)); p.strokeWeight(2.2);
      p.circle(pr.x, pr.y, 30);
      p.noStroke(); p.fill(hexA(P.ink, 0.9)); p.circle(pr.x, pr.y, 9);
    }
    if (scene.observer) {
      p.noFill(); p.stroke(hexA(P.muted, 0.6)); p.strokeWeight(1.6);
      ctx.setLineDash([5, 7]); p.circle(scene.observer.x, scene.observer.y, 52); ctx.setLineDash([]);
      p.noStroke(); p.fill(hexA(P.muted, 0.6)); p.circle(scene.observer.x, scene.observer.y, 6);
    }

    // scrims
    const L = DESIGN.layout;
    const floor = ctx.createLinearGradient(0, H, 0, H * 0.54);
    floor.addColorStop(0, hexA(P.bg0, 0.5)); floor.addColorStop(1, hexA(P.bg0, 0));
    ctx.fillStyle = floor; ctx.fillRect(0, 0, W, H);
    const scrim = ctx.createLinearGradient(0, 0, W, 0);
    scrim.addColorStop(0, hexA(P.bg0, 0.94));
    scrim.addColorStop(0.38, hexA(P.bg0, 0.8));
    scrim.addColorStop(L.scrimStop, hexA(P.bg0, 0.12));
    scrim.addColorStop(0.9, hexA(P.bg0, 0));
    ctx.fillStyle = scrim; ctx.fillRect(0, 0, W, H);

    drawType(p, ctx, scene, meta(), DESIGN);
  };
}, undefined);

/** Type block — mirrors renderSVG()'s safe-band layout so what you tune is what ships. */
function drawType(p, ctx, sc, m, D) {
  const T = D.type, L = D.layout, P = sc.palette, W = sc.w, H = sc.h;
  const textMax = W * L.plateWidth - L.margin * 1.1;
  const GAP_EYEBROW = 44, GAP_RULE = 52, RULE_H = 4, GAP_BYLINE = 42;
  const band = H * (L.safeBottom - L.safeTop) * 0.93;
  const blockHeight = (lines, size) => T.eyebrow.size + GAP_EYEBROW
    + (lines - 1) * size * T.headline.leading + size
    + GAP_RULE + RULE_H + GAP_BYLINE + T.byline.size;

  let head = null;
  for (const maxLines of [T.headline.maxLines, T.headline.maxLines - 1]) {
    const c = fitHeadline(m.title, { maxWidth: textMax, maxLines, size: T.headline.size, tracking: T.headline.tracking });
    if (blockHeight(c.lines.length, c.size) <= band) { head = c; break; }
    head = head || c;
  }
  while (blockHeight(head.lines.length, head.size) > band && head.size > 44) {
    head = fitHeadline(m.title, { maxWidth: textMax, maxLines: head.lines.length, size: head.size - 6, minSize: 44, tracking: T.headline.tracking });
  }

  const lineH = head.size * T.headline.leading;
  const top = H * (L.safeTop + L.safeBottom) / 2 - blockHeight(head.lines.length, head.size) / 2;
  const eyebrowY = top + T.eyebrow.size;
  const firstBase = eyebrowY + GAP_EYEBROW + head.size;
  const ruleY = firstBase + (head.lines.length - 1) * lineH + GAP_RULE;
  const bylineY = ruleY + RULE_H + GAP_BYLINE + T.byline.size * 0.5;

  ctx.textAlign = 'left'; ctx.textBaseline = 'alphabetic';
  ctx.letterSpacing = T.eyebrow.tracking + 'px';
  ctx.font = '600 ' + T.eyebrow.size + 'px ' + T.mono;
  ctx.fillStyle = P.accent;
  ctx.fillText([m.sectionLabel, m.date].filter(Boolean).join('   ·   ').toUpperCase(), L.margin, eyebrowY);

  ctx.letterSpacing = T.headline.tracking + 'px';
  ctx.font = T.headline.weight + ' ' + head.size + 'px ' + T.sans;
  ctx.fillStyle = P.ink;
  head.lines.forEach((line, i) => ctx.fillText(line, L.margin, firstBase + i * lineH));

  ctx.letterSpacing = '0px';
  ctx.fillStyle = P.accent;
  ctx.fillRect(L.margin, ruleY, 112, RULE_H);

  ctx.letterSpacing = T.byline.tracking + 'px';
  ctx.font = '500 ' + T.byline.size + 'px ' + T.mono;
  ctx.fillStyle = P.muted;
  ctx.fillText(['by ' + m.author, 'lifehacker.dev'].join('   ·   '), L.margin, bylineY);
  ctx.letterSpacing = '0px';
}

function hexA(hex, a) {
  const [r, g, b] = hexToRgb(hex);
  return 'rgba(' + r + ',' + g + ',' + b + ',' + a + ')';
}

// ═══════════════════════════════════════════════════════════════════════════
// UI HANDLERS
// ═══════════════════════════════════════════════════════════════════════════
const FIXED = ['density', 'probes', 'relax'];

window.updateParam = (name, value) => {
  params[name] = FIXED.includes(name) ? parseInt(value, 10) : parseFloat(value);
  const el = document.getElementById(name + '-value');
  if (el) el.textContent = FIXED.includes(name) ? params[name] : params[name].toFixed(2);
  rebuild();
};

window.setTitle = (v) => { title = v; if (sketch) sketch.redraw(); };

window.seedFromTitle = () => {
  params.seed = fnv1a(title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 50));
  updateSeedDisplay(); rebuild();
};

window.setSection = (s) => {
  params.section = s;
  for (const btn of document.querySelectorAll('#sectionSeg button')) btn.classList.toggle('on', btn.dataset.s === s);
  rebuild();
};

window.regenerate = () => rebuild();

window.downloadPNG = () => {
  const a = document.createElement('a');
  a.download = 'trace-bloom-' + params.seed + '.png';
  a.href = sketch.canvas.toDataURL('image/png');
  a.click();
};

window.downloadSVG = () => {
  const out = renderSVG(scene, meta(), DESIGN);
  const a = document.createElement('a');
  a.download = 'trace-bloom-' + params.seed + '.svg';
  a.href = URL.createObjectURL(new Blob([out], { type: 'image/svg+xml' }));
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 4000);
};

// ── seed controls (fixed) ────────────────────────────────────────────────────
function updateSeedDisplay() { document.getElementById('seed-input').value = params.seed; }
window.updateSeed = () => {
  const v = parseInt(document.getElementById('seed-input').value, 10);
  if (v && v > 0) { params.seed = v; rebuild(); } else { updateSeedDisplay(); }
};
window.previousSeed = () => { params.seed = Math.max(1, params.seed - 1); updateSeedDisplay(); rebuild(); };
window.nextSeed = () => { params.seed += 1; updateSeedDisplay(); rebuild(); };
window.randomSeedAndUpdate = () => { params.seed = Math.floor(Math.random() * 999999) + 1; updateSeedDisplay(); rebuild(); };

window.resetParameters = () => {
  params = { ...defaultParams };
  for (const k of ['density', 'probes', 'decay', 'interference', 'relax', 'drift', 'bloom']) {
    document.getElementById(k).value = params[k];
    document.getElementById(k + '-value').textContent = FIXED.includes(k) ? params[k] : params[k].toFixed(2);
  }
  setSection(params.section);
  updateSeedDisplay();
  rebuild();
};

// section selector
const seg = document.getElementById('sectionSeg');
for (const s of SECTIONS) {
  const btn = document.createElement('button');
  btn.textContent = DESIGN.sections[s].label;
  btn.dataset.s = s;
  btn.className = s === params.section ? 'on' : '';
  btn.onclick = () => setSection(s);
  seg.appendChild(btn);
}
updateSeedDisplay();
<\/script>
</body>
</html>
`;

const outPath = path.join(ROOT, 'docs/preview-lab.html');
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, HTML, 'utf8');
console.log(`[trace-bloom] wrote docs/preview-lab.html (${(HTML.length / 1024).toFixed(1)} kB, renderer inlined)`);
