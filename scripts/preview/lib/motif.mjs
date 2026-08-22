// Trace Bloom — the motif layer: the one thing a model is allowed to draw.
//
// A MOTIF is a small vector illustration of what an article is actually ABOUT,
// drawn by Claude inside a 1000x1000 box and composited into the art half of a
// banner. It is deliberately NOT a whole SVG document, because the last pipeline
// asked a model for one of those and got nothing usable (docs/PREVIEW-IMAGES.md).
// The split of labour that replaced it still holds — deterministic code owns
// typography, the safe band, the palette, the animation contract, and every byte
// that reaches disk; the model owns subject matter and nothing else.
//
// Three properties make that safe:
//
//   1. WHITELIST, NOT BLACKLIST. Model output is parsed into a tree, validated
//      element by element and attribute by attribute, and RE-SERIALIZED by this
//      file. Nothing the model wrote is ever copied through verbatim, so there is
//      no smuggling channel — no <script>, no <image>, no href, no filter.
//   2. PALETTE TOKENS, NOT COLOURS. A motif may only paint with `ink`, `cool`,
//      `warm`, `accent`, `grid`, `muted`, `bg0`, `bg1` — resolved to the SECTION's
//      hex at render time. A hack motif and a wire motif drawn a month apart
//      still belong to the same site, and re-skinning design.json reaches them.
//   3. GEOMETRY IS CHECKED. Coordinates are walked (paths included) so a motif
//      that hides in a corner, drifts out of frame, or drops a full-bleed plate
//      over the field is REJECTED with a specific reason — which is what the
//      authoring loop feeds back to the model as its next instruction. That
//      feedback loop is the thing the old Claude rung never had.
//
// The stored form (`_data/preview/motifs/<slug>.svg`) is a standalone document
// so a reviewer can open it in a browser: it carries a preview-only <style> that
// binds the tokens to one section palette. Compositing ignores that block and
// resolves tokens directly, so a banner never depends on CSS to be correct.

import { fnv1a } from './core.mjs';

export const MOTIF_SCHEMA = 'trace-bloom-motif/1';

/** The whole colour vocabulary. Anything else is a validation error. */
export const TOKENS = ['ink', 'cool', 'warm', 'accent', 'grid', 'muted', 'bg0', 'bg1'];

/** The motif's own coordinate system, independent of canvas or box size. */
export const MOTIF_GRID = 1000;

const PAINT = ['fill', 'stroke', 'stop-color'];
const COMMON = [
  'transform', 'opacity', 'fill', 'stroke', 'stroke-width', 'stroke-opacity',
  'fill-opacity', 'fill-rule', 'stroke-linecap', 'stroke-linejoin',
  'stroke-dasharray', 'stroke-miterlimit',
];

/** Element -> allowed attributes. An element that is not a key here is refused,
 *  which is why `script`, `image`, `use`, `text`, `filter`, and the animation
 *  elements need no explicit ban: they simply are not in the vocabulary. */
const ELEMENTS = {
  g: COMMON,
  path: [...COMMON, 'd'],
  circle: [...COMMON, 'cx', 'cy', 'r'],
  ellipse: [...COMMON, 'cx', 'cy', 'rx', 'ry'],
  rect: [...COMMON, 'x', 'y', 'width', 'height', 'rx', 'ry'],
  line: [...COMMON, 'x1', 'y1', 'x2', 'y2'],
  polyline: [...COMMON, 'points'],
  polygon: [...COMMON, 'points'],
  defs: [],
  linearGradient: ['id', 'x1', 'y1', 'x2', 'y2', 'gradientUnits', 'gradientTransform', 'spreadMethod'],
  radialGradient: ['id', 'cx', 'cy', 'r', 'fx', 'fy', 'gradientUnits', 'gradientTransform', 'spreadMethod'],
  stop: ['offset', 'stop-color', 'stop-opacity'],
};
const DRAWABLE = new Set(['path', 'circle', 'ellipse', 'rect', 'line', 'polyline', 'polygon']);
const NUMERIC = new Set([
  'cx', 'cy', 'r', 'rx', 'ry', 'x', 'y', 'x1', 'y1', 'x2', 'y2', 'fx', 'fy',
  'width', 'height', 'stroke-width', 'stroke-miterlimit',
]);
const UNIT = new Set(['opacity', 'fill-opacity', 'stroke-opacity', 'stop-opacity', 'offset']);
const TRANSFORMS = /^(?:(?:translate|scale|rotate|matrix|skewX|skewY)\s*\(\s*[-\d.eE,\s]*\)\s*)+$/;
const PATH_DATA = /^[MmLlHhVvCcSsQqTtAaZz0-9eE.,+\-\s]+$/;

/** Thinnest stroke that survives the card crop (motif units, scaled by ~0.58
 *  into a 1536px canvas and then by ~0.2 again into a 300px card). Hairlines are
 *  CLAMPED UP on serialization rather than rejected: a detail stroke one unit
 *  under the floor is not worth a whole redraw, and "deterministic code owns
 *  what must never be wrong" cuts both ways — if we can just fix it, fix it.
 *  `stroke-width="0"` is left alone; that means "no stroke", and honouring it is
 *  not the same as letting a hairline through. */
const MIN_STROKE = 4;

/** Coordinate slack. A stroke may kiss the edge of the box; a shape may not
 *  wander off looking for the headline. */
const BOUND_LO = -80;
const BOUND_HI = MOTIF_GRID + 80;

// -- parse -------------------------------------------------------------------

const TAG_RE = /<\s*(\/)?\s*([A-Za-z][A-Za-z0-9:-]*)((?:"[^"]*"|'[^']*'|[^<>])*?)(\/)?>/g;
const ATTR_RE = /([A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*(?:"([^"]*)"|'([^']*)')/g;

function parseAttrs(raw) {
  const attrs = {};
  let m;
  ATTR_RE.lastIndex = 0;
  while ((m = ATTR_RE.exec(raw)) !== null) attrs[m[1]] = m[2] !== undefined ? m[2] : m[3];
  return attrs;
}

/**
 * Parse an SVG fragment into a shallow node tree. Text nodes are dropped — a
 * motif has no text by design — so this is a structural read, not a DOM.
 * Throws on anything malformed; the caller turns that into model feedback.
 */
export function parseFragment(source) {
  const src = String(source).replace(/<!--[\s\S]*?-->/g, '');
  if (/<!\[CDATA\[|<\?|<!DOCTYPE/i.test(src)) {
    throw new Error('CDATA, DOCTYPE, and processing instructions are not allowed');
  }
  const root = { tag: '#root', attrs: {}, children: [] };
  const stack = [root];
  let m;
  TAG_RE.lastIndex = 0;
  while ((m = TAG_RE.exec(src)) !== null) {
    const [, closing, tag, rawAttrs, selfClosing] = m;
    if (closing) {
      const open = stack.pop();
      if (!open || open.tag !== tag || stack.length === 0) {
        throw new Error(`unbalanced tag </${tag}>`);
      }
      continue;
    }
    const node = { tag, attrs: parseAttrs(rawAttrs), children: [] };
    stack[stack.length - 1].children.push(node);
    if (!selfClosing) stack.push(node);
  }
  if (stack.length !== 1) throw new Error(`unclosed tag <${stack[stack.length - 1].tag}>`);
  return root;
}

// -- geometry ----------------------------------------------------------------

const numbersIn = (str) => (String(str).match(/-?\d*\.?\d+(?:[eE][-+]?\d+)?/g) || []).map(Number);

/**
 * Walk a path `d` and return the absolute points it visits (endpoints and
 * control points). Approximate by design: the bounding box of the control hull
 * contains the curve, which is exactly the guarantee the bounds check needs.
 */
export function pathPoints(d) {
  const pts = [];
  const tokens = String(d).match(/[MmLlHhVvCcSsQqTtAaZz]|-?\d*\.?\d+(?:[eE][-+]?\d+)?/g) || [];
  let i = 0, cx = 0, cy = 0, sx = 0, sy = 0, cmd = null;
  const num = () => Number(tokens[i++]);
  const put = (x, y) => { pts.push([x, y]); };
  while (i < tokens.length) {
    if (/^[A-Za-z]$/.test(tokens[i])) cmd = tokens[i++];
    if (!cmd) break;
    const rel = cmd === cmd.toLowerCase();
    const up = cmd.toUpperCase();
    if (up === 'Z') { cx = sx; cy = sy; put(cx, cy); continue; }
    if (i >= tokens.length || /^[A-Za-z]$/.test(tokens[i])) continue;
    switch (up) {
      case 'M': case 'L': case 'T': {
        const x = num(), y = num();
        cx = rel ? cx + x : x; cy = rel ? cy + y : y;
        if (up === 'M') { sx = cx; sy = cy; cmd = rel ? 'l' : 'L'; }
        put(cx, cy); break;
      }
      case 'H': { const x = num(); cx = rel ? cx + x : x; put(cx, cy); break; }
      case 'V': { const y = num(); cy = rel ? cy + y : y; put(cx, cy); break; }
      case 'C': {
        const x1 = num(), y1 = num(), x2 = num(), y2 = num(), x = num(), y = num();
        put(rel ? cx + x1 : x1, rel ? cy + y1 : y1);
        put(rel ? cx + x2 : x2, rel ? cy + y2 : y2);
        cx = rel ? cx + x : x; cy = rel ? cy + y : y; put(cx, cy); break;
      }
      case 'S': case 'Q': {
        const x1 = num(), y1 = num(), x = num(), y = num();
        put(rel ? cx + x1 : x1, rel ? cy + y1 : y1);
        cx = rel ? cx + x : x; cy = rel ? cy + y : y; put(cx, cy); break;
      }
      case 'A': {
        num(); num(); num(); num(); num();
        const x = num(), y = num();
        cx = rel ? cx + x : x; cy = rel ? cy + y : y; put(cx, cy); break;
      }
      default: return pts;   // unknown command: bail, the syntax check catches it
    }
    if (!Number.isFinite(cx) || !Number.isFinite(cy)) return pts;
  }
  return pts;
}

/** Every absolute point an element contributes, ignoring transforms (which are
 *  bounded separately — a translate that pushes art out of frame still shows up
 *  as a coverage failure, because the visible box is what we measure against). */
function elementPoints(node) {
  const a = node.attrs;
  const n = (k, d = 0) => (a[k] === undefined ? d : Number(a[k]));
  switch (node.tag) {
    case 'path': return pathPoints(a.d || '');
    case 'circle': return [[n('cx') - n('r'), n('cy') - n('r')], [n('cx') + n('r'), n('cy') + n('r')]];
    case 'ellipse': return [[n('cx') - n('rx'), n('cy') - n('ry')], [n('cx') + n('rx'), n('cy') + n('ry')]];
    case 'rect': return [[n('x'), n('y')], [n('x') + n('width'), n('y') + n('height')]];
    case 'line': return [[n('x1'), n('y1')], [n('x2'), n('y2')]];
    case 'polyline': case 'polygon': {
      const v = numbersIn(a.points || '');
      const out = [];
      for (let i = 0; i + 1 < v.length; i += 2) out.push([v[i], v[i + 1]]);
      return out;
    }
    default: return [];
  }
}

// -- validate ----------------------------------------------------------------

function isPaint(value, gradientIds) {
  const v = String(value).trim();
  if (v === 'none' || v === 'transparent') return true;
  if (TOKENS.includes(v)) return true;
  const varMatch = v.match(/^var\(\s*--([a-z0-9]+)\s*\)$/i);
  if (varMatch) return TOKENS.includes(varMatch[1].toLowerCase());
  const url = v.match(/^url\(\s*#([A-Za-z][\w-]*)\s*\)$/);
  if (url) return gradientIds.has(url[1]);
  return false;
}

const canonicalPaint = (value) => {
  const v = String(value).trim();
  if (TOKENS.includes(v)) return `var(--${v})`;
  const varMatch = v.match(/^var\(\s*--([a-z0-9]+)\s*\)$/i);
  if (varMatch) return `var(--${varMatch[1].toLowerCase()})`;
  return v;
};

/**
 * Validate a parsed motif tree. Returns `{ ok, violations, stats, tree }`.
 *
 * Violations are written as INSTRUCTIONS, not diagnostics: the authoring loop
 * pastes them straight back to the model as the next turn, so each one has to
 * say what to do differently.
 */
export function validateTree(root, { minElements = 6, maxElements = 200, minSpan = 0.42 } = {}) {
  const violations = [];
  const gradientIds = new Set();
  const usedPaints = new Set();
  const points = [];
  let drawables = 0;

  const collectGradients = (node) => {
    if ((node.tag === 'linearGradient' || node.tag === 'radialGradient') && node.attrs.id) {
      gradientIds.add(node.attrs.id);
    }
    node.children.forEach(collectGradients);
  };
  collectGradients(root);

  const visit = (node, depth) => {
    if (node.tag !== '#root') {
      const allowed = ELEMENTS[node.tag];
      if (!allowed) {
        violations.push(`<${node.tag}> is not allowed. Draw only with g, path, circle, ellipse, rect, line, polyline, polygon (gradients via defs/linearGradient/radialGradient/stop). No text, no images, no scripts, no filters — the headline is typeset separately.`);
        return;
      }
      if (depth > 8) violations.push('nesting is deeper than 8 groups; flatten the drawing.');
      for (const [key, value] of Object.entries(node.attrs)) {
        if (!allowed.includes(key)) {
          violations.push(`attribute ${key}="..." is not allowed on <${node.tag}>. Allowed: ${allowed.join(', ') || '(none)'}.`);
          continue;
        }
        if (PAINT.includes(key) && !isPaint(value, gradientIds)) {
          violations.push(`${key}="${value}" on <${node.tag}> is not a palette token. Paint only with ${TOKENS.join(', ')} (e.g. fill="cool"), "none", or url(#id) for a gradient you defined. Raw hex, rgb(), and named CSS colours are refused so the art stays on-palette for every section.`);
        }
        if (NUMERIC.has(key) && !Number.isFinite(Number(value))) {
          violations.push(`${key}="${value}" on <${node.tag}> is not a number.`);
        }
        if (UNIT.has(key)) {
          const pct = String(value).includes('%');
          const num = Number(String(value).replace('%', ''));
          if (!Number.isFinite(num) || num < 0 || num > (pct ? 100 : 1)) {
            violations.push(`${key}="${value}" on <${node.tag}> must be between 0 and 1.`);
          }
        }
        if (key === 'transform' && !TRANSFORMS.test(value)) {
          violations.push(`transform="${value}" is not a plain translate/scale/rotate/matrix/skew list.`);
        }
        if (key === 'd' && !PATH_DATA.test(value)) {
          violations.push('a path `d` contains something other than SVG path commands and numbers.');
        }
        if ((key === 'points' || key === 'stroke-dasharray') && !/^[\d.,\s-]+$/.test(value)) {
          violations.push(`${key}="${value}" must be a plain list of numbers.`);
        }
        if (key === 'id' && !/^[A-Za-z][\w-]{0,40}$/.test(value)) {
          violations.push(`id="${value}" must be a short identifier.`);
        }
      }
      if (DRAWABLE.has(node.tag)) {
        drawables++;
        points.push(...elementPoints(node));
        for (const key of ['fill', 'stroke']) {
          const v = node.attrs[key];
          if (v && v !== 'none') usedPaints.add(canonicalPaint(v));
        }
        // A full-bleed opaque plate would erase the lattice field the motif is
        // supposed to sit ON, turning the banner back into flat wallpaper.
        if (node.tag === 'rect') {
          const area = Number(node.attrs.width || 0) * Number(node.attrs.height || 0);
          const alpha = Number(node.attrs['fill-opacity'] ?? node.attrs.opacity ?? 1);
          if (area > 0.72 * MOTIF_GRID * MOTIF_GRID && node.attrs.fill !== 'none' && alpha > 0.5) {
            violations.push('a rectangle covers most of the frame as a solid background. Leave the background alone — the banner already has one, and the drawing must sit ON it.');
          }
        }
      }
    }
    node.children.forEach((child) => visit(child, depth + 1));
  };
  visit(root, 0);

  if (drawables < minElements) {
    violations.push(`the drawing has only ${drawables} shapes; build the subject out of at least ${minElements} so it reads as an illustration rather than an icon.`);
  }
  if (drawables > maxElements) {
    violations.push(`the drawing has ${drawables} shapes; simplify to under ${maxElements} — it must stay legible at 300px wide.`);
  }
  if (usedPaints.size < 2 && drawables) {
    violations.push('the drawing uses a single colour. Use at least two palette tokens so the subject separates from its own structure.');
  }

  let stats = { drawables, span: [0, 0], centre: [500, 500], paints: usedPaints.size };
  if (points.length) {
    const xs = points.map((p) => p[0]).filter(Number.isFinite);
    const ys = points.map((p) => p[1]).filter(Number.isFinite);
    if (xs.length && ys.length) {
      const minX = Math.min(...xs), maxX = Math.max(...xs);
      const minY = Math.min(...ys), maxY = Math.max(...ys);
      stats = {
        drawables,
        span: [(maxX - minX) / MOTIF_GRID, (maxY - minY) / MOTIF_GRID],
        centre: [(minX + maxX) / 2, (minY + maxY) / 2],
        paints: usedPaints.size,
      };
      if (minX < BOUND_LO || minY < BOUND_LO || maxX > BOUND_HI || maxY > BOUND_HI) {
        violations.push(`the drawing runs from (${minX.toFixed(0)}, ${minY.toFixed(0)}) to (${maxX.toFixed(0)}, ${maxY.toFixed(0)}). Everything must live inside 0..${MOTIF_GRID} on both axes — anything outside is clipped away.`);
      }
      if (stats.span[0] < minSpan || stats.span[1] < minSpan) {
        violations.push(`the drawing fills only ${(stats.span[0] * 100).toFixed(0)}% x ${(stats.span[1] * 100).toFixed(0)}% of the frame. Compose it to fill at least ${(minSpan * 100).toFixed(0)}% of both axes — a small emblem in the middle of a big frame disappears in a 300px card.`);
      }
      const off = Math.max(Math.abs(stats.centre[0] - 500), Math.abs(stats.centre[1] - 500));
      if (off > 260) {
        violations.push(`the drawing's centre of mass is at (${stats.centre[0].toFixed(0)}, ${stats.centre[1].toFixed(0)}); centre it nearer (500, 500).`);
      }
    }
  }
  return { ok: violations.length === 0, violations: [...new Set(violations)], stats, tree: root };
}

// -- serialize ---------------------------------------------------------------

const esc = (s) => String(s)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/**
 * Re-emit a validated tree. `resolve` maps a token to whatever the caller wants
 * painted — hex for a composited banner, `var(--token)` for the stored file.
 * NOTHING the model wrote is copied through: every tag and attribute here came
 * out of the whitelist above.
 */
export function serializeTree(root, { resolve = (t) => `var(--${t})`, idPrefix = 'm-', indent = '' } = {}) {
  const paint = (value) => {
    const v = canonicalPaint(value);
    const varMatch = v.match(/^var\(\s*--([a-z0-9]+)\s*\)$/i);
    if (varMatch) return resolve(varMatch[1].toLowerCase());
    const url = v.match(/^url\(\s*#([A-Za-z][\w-]*)\s*\)$/);
    if (url) return `url(#${idPrefix}${url[1]})`;
    return v;
  };
  // With an indent the output is pretty-printed one element per line, because a
  // motif is a file a human reviews in a diff. Without one it is a single line —
  // and that unindented form is what motifDigest hashes, so how the file is
  // formatted can never change a drawing's identity.
  const emit = (node, pad) => {
    const allowed = ELEMENTS[node.tag] || [];
    const attrs = [];
    for (const key of Object.keys(node.attrs)) {
      if (!allowed.includes(key)) continue;
      let value = node.attrs[key];
      if (PAINT.includes(key)) value = paint(value);
      else if (key === 'id') value = `${idPrefix}${value}`;
      else if (key === 'stroke-width' && Number(value) > 0 && Number(value) < MIN_STROKE) {
        value = String(MIN_STROKE);
      }
      attrs.push(`${key}="${esc(value)}"`);
    }
    const open = `<${node.tag}${attrs.length ? ` ${attrs.join(' ')}` : ''}`;
    if (!node.children.length) return `${pad}${open}/>`;
    if (!indent) return `${pad}${open}>${node.children.map((c) => emit(c, '')).join('')}</${node.tag}>`;
    return [`${pad}${open}>`,
      ...node.children.map((c) => emit(c, `${pad}${indent}`)),
      `${pad}</${node.tag}>`].join('\n');
  };
  return root.children.map((child) => emit(child, indent)).join('\n');
}

/** Stable identity for a motif's artwork. */
export const motifDigest = (body) => fnv1a(String(body)).toString(16).padStart(8, '0');

/** Version of the COMPOSITING contract (how a motif is placed, clipped, staged
 *  and animated into a banner) — distinct from GENERATOR, which versions the
 *  banner as a whole. Bump it when renderMotifLayer changes shape, and every
 *  illustrated banner goes stale on the next run while the un-illustrated ones,
 *  which this cannot affect, are left alone. */
export const MOTIF_RENDERER = 'motif/2';

/** What a banner stamps as `data-motif`: the artwork's identity AND the
 *  compositing version, so either changing makes the banner stale. */
export const motifStamp = (motif) => `${MOTIF_RENDERER}:${motif.digest}`;

/** The standalone, reviewable form written to _data/preview/motifs/<slug>.svg. */
export function serializeMotifDocument({ tree, concept, model, attempts, palette, title }) {
  const body = serializeTree(tree, { indent: '  ' });
  // The digest is taken from the UNINDENTED serialization — the same form
  // parseMotifDocument hashes on the way back in. Hashing the pretty-printed
  // body here would stamp the file with an identity the banner never carries.
  const digest = motifDigest(serializeTree(tree));
  const vars = TOKENS.map((t) => `--${t}:${(palette && palette[t]) || '#888888'}`).join(';');
  return [
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${MOTIF_GRID} ${MOTIF_GRID}" width="${MOTIF_GRID}" height="${MOTIF_GRID}" role="img"`,
    `     data-schema="${MOTIF_SCHEMA}" data-model="${esc(model || 'unknown')}" data-attempts="${Number(attempts) || 1}" data-digest="${digest}">`,
    `<title>${esc(concept || title || 'Article motif')}</title>`,
    '<!-- Preview only: the banner compositor ignores this block and resolves the',
    '     tokens against the article\'s own section palette. -->',
    `<style>:root{${vars}}</style>`,
    body,
    '</svg>',
    '',
  ].join('\n');
}

/** Read a stored motif document back into `{ tree, concept, model, digest }`,
 *  re-validating it — a motif is a committed input, so it is checked on the way
 *  in as well as on the way out. Throws with the violations on bad input. */
export function parseMotifDocument(text) {
  const concept = (text.match(/<title>([\s\S]*?)<\/title>/) || [, ''])[1]
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"')
    .replace(/&amp;/g, '&').trim();
  const model = (text.match(/data-model="([^"]*)"/) || [, ''])[1];
  const artOnly = String(text)
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/<style[\s\S]*?<\/style>/g, '')
    .replace(/<title[\s\S]*?<\/title>/g, '')
    .replace(/^[\s\S]*?<svg[^>]*>/, '')
    .replace(/<\/svg>\s*$/, '');
  const tree = parseFragment(artOnly);
  const result = validateTree(tree);
  if (!result.ok) {
    const err = new Error(`motif failed validation: ${result.violations.join(' | ')}`);
    err.violations = result.violations;
    throw err;
  }
  const body = serializeTree(tree);
  return { tree, concept, model, digest: motifDigest(body), stats: result.stats };
}

/**
 * The composited layer: the motif, scaled into the banner's art box, seated on a
 * soft stage so it separates from the lattice behind it, and wired into the same
 * reveal sweep as everything else. Returns `{ defs, layer }` for the renderer to
 * place — defs go in <defs>, the layer goes under the scrim.
 */
export function renderMotifLayer(motif, design, palette, { bucket = 6 } = {}) {
  // The stage rides the lattice's own sweep (it is weather). The drawing does
  // not: it gets its own reveal, defined in svg.mjs, which starts at .72 rather
  // than .3. Frame 0 is what every social scraper and rasterizer captures, and
  // the subject of the picture cannot be 30% there when they do.
  const box = (design.motif && design.motif.box) || { x: 862, y: 224, size: 576 };
  const stageOpacity = (design.motif && design.motif.stageOpacity) ?? 0.62;
  const scale = box.size / MOTIF_GRID;
  const art = serializeTree(motif.tree, { resolve: (token) => palette[token] || palette.ink });
  const cx = box.x + box.size / 2;
  const cy = box.y + box.size / 2;
  const defs = [
    `<clipPath id="motifclip"><rect x="${box.x}" y="${box.y}" width="${box.size}" height="${box.size}"/></clipPath>`,
    `<radialGradient id="stage"><stop offset="0" stop-color="${palette.bg0}" stop-opacity="${stageOpacity}"/>`
      + `<stop offset="0.62" stop-color="${palette.bg0}" stop-opacity="${(stageOpacity * 0.45).toFixed(3)}"/>`
      + `<stop offset="1" stop-color="${palette.bg0}" stop-opacity="0"/></radialGradient>`,
  ].join('\n');
  // The clip and the transform MUST live on separate groups. A clipPath with the
  // default clipPathUnits="userSpaceOnUse" resolves in the user space of the
  // element that references it — which, on an element that also carries a
  // `transform`, is the space AFTER that transform. Putting both on one group
  // reads the box coordinates as motif coordinates and clips the drawing away to
  // a sliver. (It did. The first composited banner rendered one rectangle of a
  // 35-shape illustration, and nothing in the pipeline could have caught it:
  // the SVG was valid, the lint was green, and only a rasterized look found it.)
  const layer = [
    `<ellipse class="sig b${Math.max(0, bucket - 3)}" cx="${cx}" cy="${cy}" rx="${(box.size * 0.72).toFixed(0)}" ry="${(box.size * 0.66).toFixed(0)}" fill="url(#stage)"/>`,
    `<g class="motif" clip-path="url(#motifclip)">`,
    `<g transform="translate(${box.x} ${box.y}) scale(${scale.toFixed(4)})">`,
    art,
    '</g>',
    '</g>',
  ].join('\n');
  return { defs, layer };
}
