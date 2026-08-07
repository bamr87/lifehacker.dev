// Trace Bloom — the generative core.
//
// Philosophy: docs/TRACE-BLOOM.md. Framework: docs/PREVIEW-IMAGES.md.
//
// A substrate (lattice) is laid down, relaxed, and probed. Wavefronts propagate
// ALONG THE GRAPH from each emitter, decaying per unit of travel and carrying a
// phase; where they meet they interfere, and the constructive nodes bloom. The
// output is a plain scene object (positions, weights, arrival buckets) that a
// renderer turns into SVG or draws on a p5 canvas — the algorithm itself knows
// nothing about either.
//
// Everything is seeded: same seed + same params => byte-identical scene, forever.
// Zero dependencies (stdlib only) so it runs in CI, on a laptop, and in a browser.

// ── deterministic randomness ─────────────────────────────────────────────────

/** FNV-1a. Stable across runs and machines — unlike JS string hashing. */
export function fnv1a(str) {
  let h = 0x811c9dc5;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}

/** Mulberry32 — small, fast, good enough distribution for art, fully seeded. */
export function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Seeded 2D value noise with fbm. Used for substrate drift, not for texture. */
export function makeNoise(rand) {
  const perm = new Uint8Array(512);
  const p = new Uint8Array(256);
  for (let i = 0; i < 256; i++) p[i] = i;
  for (let i = 255; i > 0; i--) {          // seeded Fisher-Yates
    const j = Math.floor(rand() * (i + 1));
    const t = p[i]; p[i] = p[j]; p[j] = t;
  }
  for (let i = 0; i < 512; i++) perm[i] = p[i & 255];

  const fade = (t) => t * t * t * (t * (t * 6 - 15) + 10);
  const grad = (hash, x, y) => {
    switch (hash & 3) {
      case 0: return x + y;
      case 1: return -x + y;
      case 2: return x - y;
      default: return -x - y;
    }
  };

  function noise2(x, y) {
    const X = Math.floor(x) & 255, Y = Math.floor(y) & 255;
    const xf = x - Math.floor(x), yf = y - Math.floor(y);
    const u = fade(xf), v = fade(yf);
    const aa = perm[perm[X] + Y], ab = perm[perm[X] + Y + 1];
    const ba = perm[perm[X + 1] + Y], bb = perm[perm[X + 1] + Y + 1];
    const x1 = lerp(grad(aa, xf, yf), grad(ba, xf - 1, yf), u);
    const x2 = lerp(grad(ab, xf, yf - 1), grad(bb, xf - 1, yf - 1), u);
    return lerp(x1, x2, v);                // roughly -1..1
  }

  /** Layered octaves — turbulence where the substrate should feel unsurveyed. */
  noise2.fbm = (x, y, octaves = 3) => {
    let sum = 0, amp = 1, freq = 1, norm = 0;
    for (let o = 0; o < octaves; o++) {
      sum += noise2(x * freq, y * freq) * amp;
      norm += amp;
      amp *= 0.5; freq *= 2;
    }
    return sum / norm;
  };
  return noise2;
}

// ── small math ───────────────────────────────────────────────────────────────

export const lerp = (a, b, t) => a + (b - a) * t;
export const clamp = (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v);
const round = (v, dp = 1) => {
  const m = 10 ** dp;
  return Math.round(v * m) / m;
};

/** Map a 0..1 roll into a bounds entry from design.json. */
function pick(rand, bounds) {
  return lerp(bounds.min, bounds.max, rand());
}

// ── article → parameters ─────────────────────────────────────────────────────
//
// The parameters are DERIVED, never hand-authored per article. `decay` is the
// one that carries editorial meaning (failure vs. steady state), so it is not
// left purely to the seed — the article's own language nudges it.

const URGENT = /\b(fail|failed|failing|broke|broken|break|bug|crash|leak|regress|outage|panic|stale|silent|wrong|lost|rot|flake|flaky|deadlock|timeout|hang|corrupt|drift|never|can'?t|didn'?t|isn'?t|won'?t)\b/gi;
const STEADY = /\b(architecture|design|pattern|guide|reference|how|structure|convention|standard|pipeline|contract|model|system|overview|explain|works|primer)\b/gi;

export function deriveParams({ slug, title = '', tags = [], section = 'field-notes', body = '' }, design) {
  const sections = design.sections;
  const sec = sections[section] ? section : 'field-notes';
  const seed = fnv1a(slug || title);
  const rand = mulberry32(seed);
  const b = design.bounds;

  // Sample the closed parameter space. Order matters — it is part of the seed
  // contract; inserting a pick() above an existing one re-rolls every banner.
  const density = Math.round(pick(rand, b.density));
  const probes = Math.round(pick(rand, b.probes));
  const relax = Math.round(pick(rand, b.relax));
  const drift = pick(rand, b.drift);
  const interference = pick(rand, b.interference);
  const bloom = pick(rand, b.bloom);
  let decay = pick(rand, b.decay);

  // Editorial nudge: how the piece reads tilts the decay curve. Counted over
  // title + tags + the first slice of body so a single scare-word can't swing it.
  const corpus = `${title} ${tags.join(' ')} ${body.slice(0, 1200)}`;
  const urgent = (corpus.match(URGENT) || []).length;
  const steady = (corpus.match(STEADY) || []).length;
  const tilt = clamp((urgent - steady) / 8, -1, 1);
  decay = clamp(decay + tilt * 0.12, b.decay.min, b.decay.max);

  return {
    seed, section: sec, lattice: sections[sec].lattice,
    density, probes, relax, drift, interference, bloom, decay,
    tone: tilt > 0.15 ? 'urgent' : tilt < -0.15 ? 'steady' : 'even',
  };
}

// ── the substrate ────────────────────────────────────────────────────────────

function latticeNodes(params, noise, rand, W, H) {
  const { lattice, density, drift } = params;
  const nodes = [];
  const cols = density;
  const rows = Math.max(6, Math.round(density * (H / W) * 1.18));
  const gx = W / (cols - 1), gy = H / (rows - 1);

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      let x = c * gx, y = r * gy;

      if (lattice === 'isometric') {
        // Skew into a blueprint axonometric, then re-fit to the canvas.
        const sx = (c - (cols - 1) / 2) * gx, sy = (r - (rows - 1) / 2) * gy;
        x = W / 2 + (sx - sy * 0.5) * 0.86;
        y = H / 2 + (sy * 0.62 + sx * 0.22) * 0.94;
      }

      // Drift: how far the survey is off true. Quantized lattices snap it away.
      const n1 = noise.fbm(c * 0.28, r * 0.28, 3);
      const n2 = noise.fbm(c * 0.28 + 40, r * 0.28 + 40, 3);
      const amp = (lattice === 'quantized' ? 0.12 : lattice === 'organic' ? 1.0 : 0.42) * drift;
      x += n1 * gx * amp;
      y += n2 * gy * amp;
      if (lattice === 'quantized') {        // snap: nothing continuous here
        x = Math.round(x / (gx / 2)) * (gx / 2);
        y = Math.round(y / (gy / 2)) * (gy / 2);
      }
      nodes.push({ x, y, c, r, f: 0, d: Infinity, deg: 0 });
    }
  }
  return { nodes, cols, rows, gx, gy };
}

/** Relaxation: nodes push apart until the field settles. This is the pass that
 *  separates "surveyed" from "screensaver" — see the manifesto. */
function relaxNodes(nodes, passes, minDist) {
  for (let p = 0; p < passes; p++) {
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const a = nodes[i], bn = nodes[j];
        const dx = bn.x - a.x, dy = bn.y - a.y;
        const d2 = dx * dx + dy * dy;
        if (d2 > minDist * minDist || d2 === 0) continue;
        const d = Math.sqrt(d2);
        const push = (minDist - d) * 0.24;      // meticulously gentle falloff
        const ux = dx / d, uy = dy / d;
        a.x -= ux * push; a.y -= uy * push;
        bn.x += ux * push; bn.y += uy * push;
      }
    }
  }
}

function latticeEdges(params, grid, rand) {
  const { lattice } = params;
  const { nodes, cols, rows } = grid;
  const at = (c, r) => (c < 0 || r < 0 || c >= cols || r >= rows ? -1 : r * cols + c);
  const edges = [];
  const push = (i, j) => {
    if (i < 0 || j < 0) return;
    edges.push({ a: i, b: j });
    nodes[i].deg++; nodes[j].deg++;
  };

  if (lattice === 'organic') {
    // Near-neighbour mesh: each node links to its 3 closest, deduped.
    const seen = new Set();
    for (let i = 0; i < nodes.length; i++) {
      const near = [];
      for (let j = 0; j < nodes.length; j++) {
        if (i === j) continue;
        const dx = nodes[j].x - nodes[i].x, dy = nodes[j].y - nodes[i].y;
        near.push([dx * dx + dy * dy, j]);
      }
      near.sort((p, q) => p[0] - q[0]);
      for (let k = 0; k < 3 && k < near.length; k++) {
        const j = near[k][1];
        const key = i < j ? `${i}:${j}` : `${j}:${i}`;
        if (seen.has(key)) continue;
        seen.add(key);
        push(i, j);
      }
    }
    return edges;
  }

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const i = at(c, r);
      // Manhattan routing pays for every corner: drop a fraction of the runs so
      // the signal has to detour. Quantized keeps more of them (chunky blocks).
      const keep = lattice === 'quantized' ? 0.78 : 0.62;
      if (rand() < keep) push(i, at(c + 1, r));
      if (rand() < keep) push(i, at(c, r + 1));
      if (lattice === 'isometric' && rand() < 0.3) push(i, at(c + 1, r + 1));
      if (lattice === 'quantized' && rand() < 0.12) push(i, at(c + 1, r + 1));
    }
  }
  return edges;
}

// ── propagation ──────────────────────────────────────────────────────────────

/** Dijkstra over the lattice: the wavefront must TRAVEL THE GRAPH, arriving
 *  late where routing is bad. A radial falloff would ignore the topology, which
 *  is the whole subject of the picture. */
function propagate(nodes, adj, sources) {
  const dist = new Float64Array(nodes.length).fill(Infinity);
  const queue = [];
  for (const s of sources) { dist[s] = 0; queue.push([0, s]); }
  while (queue.length) {
    queue.sort((a, b) => a[0] - b[0]);       // n is small; a heap buys nothing
    const [d, u] = queue.shift();
    if (d > dist[u]) continue;
    for (const [v, w] of adj[u]) {
      const nd = d + w;
      if (nd < dist[v] - 1e-9) { dist[v] = nd; queue.push([nd, v]); }
    }
  }
  return dist;
}

export function buildScene(params, design, opts = {}) {
  const W = design.canvas.width, H = design.canvas.height;
  const sec = design.sections[params.section];
  const pal = sec.palette;
  const rand = mulberry32(params.seed ^ 0x9e3779b9);
  const noise = makeNoise(mulberry32(params.seed));

  const grid = latticeNodes(params, noise, rand, W, H);
  const { nodes } = grid;
  if (params.lattice === 'organic' || params.relax > 0) {
    relaxNodes(nodes, params.relax, Math.min(grid.gx, grid.gy) * 0.72);
  }
  const edges = latticeEdges(params, grid, rand);

  // adjacency, weighted by real distance travelled
  const adj = nodes.map(() => []);
  for (const e of edges) {
    const a = nodes[e.a], b = nodes[e.b];
    const w = Math.hypot(b.x - a.x, b.y - a.y);
    e.w = w;
    adj[e.a].push([e.b, w]);
    adj[e.b].push([e.a, w]);
  }

  // Emitters. Biased to the right so the type plate on the left stays clean —
  // composition is not left to chance even when placement is.
  const plateEdge = W * design.layout.plateWidth;
  const candidates = nodes
    .map((n, i) => i)
    .filter((i) => nodes[i].x > plateEdge * 0.82 && adj[i].length > 1);
  const pool = candidates.length >= params.probes + 1
    ? candidates
    : nodes.map((n, i) => i).filter((i) => adj[i].length > 1);

  const chosen = [];
  for (let k = 0; k < params.probes && pool.length; k++) {
    // Spread them: reject picks that crowd an existing probe.
    let best = -1, bestScore = -1;
    for (let t = 0; t < 24; t++) {
      const cand = pool[Math.floor(rand() * pool.length)];
      if (chosen.includes(cand)) continue;
      let score = Infinity;
      for (const c of chosen) score = Math.min(score, Math.hypot(nodes[cand].x - nodes[c].x, nodes[cand].y - nodes[c].y));
      if (chosen.length === 0) score = 1e9;
      if (score > bestScore) { bestScore = score; best = cand; }
    }
    if (best >= 0) chosen.push(best);
  }

  // THE OBSERVER PROBE — emits nothing, only receives; the field bends around it
  // because measuring costs the system something. See TRACE-BLOOM.md.
  let observer = -1;
  {
    const obsPool = nodes.map((n, i) => i)
      .filter((i) => !chosen.includes(i) && nodes[i].x > plateEdge && adj[i].length > 1);
    if (obsPool.length) observer = obsPool[Math.floor(rand() * obsPool.length)];
  }
  if (observer >= 0) {
    const o = nodes[observer];
    for (const n of nodes) {
      const dx = n.x - o.x, dy = n.y - o.y;
      const d = Math.hypot(dx, dy);
      if (d < 1e-6 || d > W * 0.2) continue;
      const bend = (1 - d / (W * 0.2)) ** 2 * 14;   // never the loudest thing here
      n.x += (dx / d) * bend; n.y += (dy / d) * bend;
    }
  }

  // Per-probe wavefronts, summed with phase → interference field.
  const scale = Math.hypot(W, H);
  const wavelength = scale / lerp(3.2, 5.6, ((params.seed >>> 8) & 255) / 255);
  const arrivals = new Float64Array(nodes.length).fill(Infinity);
  const field = new Float64Array(nodes.length);

  for (let k = 0; k < chosen.length; k++) {
    const dist = propagate(nodes, adj, [chosen[k]]);
    const phase0 = (k / Math.max(1, chosen.length)) * Math.PI * 2;
    for (let i = 0; i < nodes.length; i++) {
      const d = dist[i];
      if (!isFinite(d)) continue;
      const amp = Math.exp(-params.decay * (d / scale) * 6);
      field[i] += amp * Math.cos((d / wavelength) * Math.PI * 2 + phase0) * params.interference;
      if (d < arrivals[i]) arrivals[i] = d;
    }
  }

  // Normalise against a high PERCENTILE, not the maximum. Dividing by the single
  // hottest node lets one outlier crush the whole field into near-zero, which is
  // exactly how a "trace" picture ends up as a few blobs on black. Anchoring the
  // 85th percentile at 1.0 spreads the distribution across the render's tiers so
  // the substrate actually reads as traces.
  const mags = Array.from(field, Math.abs).sort((a, b) => a - b);
  const p85 = mags[Math.floor(mags.length * 0.85)] || 1e-6;
  let maxArr = 1e-6;
  for (let i = 0; i < nodes.length; i++) {
    if (isFinite(arrivals[i])) maxArr = Math.max(maxArr, arrivals[i]);
  }
  for (let i = 0; i < nodes.length; i++) {
    nodes[i].f = clamp(field[i] / p85, -1.35, 1.35);
    nodes[i].t = isFinite(arrivals[i]) ? arrivals[i] / maxArr : 1;
  }

  // ── emit renderable primitives ──────────────────────────────────────────────
  const buckets = design.motion.buckets;
  const outEdges = [];
  for (const e of edges) {
    const a = nodes[e.a], b = nodes[e.b];
    const f = (a.f + b.f) / 2;
    const lit = Math.abs(f);
    outEdges.push({
      x1: round(a.x), y1: round(a.y), x2: round(b.x), y2: round(b.y),
      lit: round(lit, 3), sign: f >= 0 ? 1 : -1,
      bucket: clamp(Math.floor(((a.t + b.t) / 2) * buckets), 0, buckets - 1),
    });
  }

  // Blooms at locally-maximal interference. Constructive nodes bloom bright;
  // this is the focal point nobody placed by hand.
  const bloomNodes = [];
  const neighbourMax = nodes.map((n, i) => {
    let m = 0;
    for (const [v] of adj[i]) m = Math.max(m, Math.abs(nodes[v].f));
    return m;
  });
  for (let i = 0; i < nodes.length; i++) {
    const a = Math.abs(nodes[i].f);
    if (a < 0.85 || a < neighbourMax[i]) continue;
    if (nodes[i].x < plateEdge * 0.6) continue;      // keep the type plate clean
    bloomNodes.push({
      x: round(nodes[i].x), y: round(nodes[i].y),
      r: round(lerp(22, 64, clamp(a, 0, 1)) * params.bloom),
      i: round(a, 3), sign: nodes[i].f >= 0 ? 1 : -1,
      bucket: clamp(Math.floor(nodes[i].t * buckets), 0, buckets - 1),
    });
  }
  bloomNodes.sort((p, q) => q.i - p.i);

  return {
    w: W, h: H, params, palette: pal, sectionLabel: sec.label,
    edges: outEdges,
    blooms: bloomNodes.slice(0, 14),
    probes: chosen.map((i) => ({ x: round(nodes[i].x), y: round(nodes[i].y), observer: false })),
    observer: observer >= 0
      ? { x: round(nodes[observer].x), y: round(nodes[observer].y), observer: true }
      : null,
    nodes: nodes.map((n) => ({ x: round(n.x), y: round(n.y), f: round(n.f, 3), t: round(n.t, 3) })),
    ...opts,
  };
}

// ── colour helpers (shared by the SVG emitter and the p5 viewer) ─────────────

export function hexToRgb(hex) {
  const h = hex.replace('#', '');
  return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
}
export function rgbToHex([r, g, b]) {
  return '#' + [r, g, b].map((v) => clamp(Math.round(v), 0, 255).toString(16).padStart(2, '0')).join('');
}
export function mix(hexA, hexB, t) {
  const a = hexToRgb(hexA), b = hexToRgb(hexB);
  return rgbToHex([lerp(a[0], b[0], t), lerp(a[1], b[1], t), lerp(a[2], b[2], t)]);
}
