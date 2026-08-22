#!/usr/bin/env node
// Trace Bloom — the illustrator. Claude draws what an article is ABOUT.
//
//   node scripts/preview/illustrate.mjs -f pages/_posts/hacks/2026-08-01-thing.md
//   node scripts/preview/illustrate.mjs --changed            # git-new/modified .md
//   node scripts/preview/illustrate.mjs --all --batch 5      # backfill the archive
//   node scripts/preview/illustrate.mjs --self-test          # offline; no model call
//
// WHAT THIS IS. The banner generator (generate.mjs) computes a composition from
// the article and typesets its headline. That is a portrait, not a picture of the
// subject — a reader sees "grid, glow, title" and learns nothing about the piece.
// This adds the missing half: a MOTIF, one small vector drawing of the article's
// actual subject, authored by Claude, validated by lib/motif.mjs, committed to
// _data/preview/motifs/<slug>.svg, and composited into the art half of the banner.
//
// WHY IT IS NOT THE OLD CLAUDE RUNG. docs/PREVIEW-IMAGES.md buried a pipeline
// that asked a model to one-shot a whole SVG document and silently shipped a
// gradient when that failed. Four things are different here, and each one is a
// direct answer to how that failed:
//
//   1. The model draws a FRAGMENT inside a fixed box, never a document. It never
//      touches typography, the safe band, the palette, or the animation contract.
//   2. Its output is parsed, whitelisted, and RE-SERIALIZED by our code, so an
//      unsafe banner cannot be produced even by a hostile response.
//   3. There is a FEEDBACK LOOP. Geometry and vocabulary are checked, and every
//      failure is handed back to the model as the next instruction. The old rung
//      had one shot and no check at all.
//   4. There is NO SILENT FALLBACK. Failing to illustrate exits non-zero and
//      says why. The article keeps the banner Trace Bloom already computed for
//      it — which is unique to that article, not a shared wallpaper — so nothing
//      degrades, and nobody is told a picture was made when it was not.
//
// COST. One subscription-auth Claude Code call per article, once, ever: the motif
// is committed, so re-skins, GENERATOR bumps and CI re-runs re-render from the
// committed file and never call a model again. No image API, no per-image dollar
// cost. Auth and model selection go through scripts/ai/run.sh (_data/ai.yml).
//
// Exit codes: 0 ok · 1 one or more articles failed · 3 no Claude credential.

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

import { deriveParams, buildScene } from './lib/core.mjs';
import { renderSVG } from './lib/svg.mjs';
import { readArticle, findMarkdown, motifPath, MOTIF_DIR } from './lib/article.mjs';
import {
  parseFragment, validateTree, serializeMotifDocument, parseMotifDocument,
  motifStamp, TOKENS, MOTIF_GRID,
} from './lib/motif.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..', '..');
const DESIGN = JSON.parse(fs.readFileSync(path.join(ROOT, '_data/preview/design.json'), 'utf8'));
const AI_YML = path.join(ROOT, '_data/ai.yml');

const EXIT_FAILED = 1;
const EXIT_NO_CREDENTIAL = 3;

const log = (m) => console.log(`[illustrate] ${m}`);
const warn = (m) => console.error(`[illustrate] WARN: ${m}`);

// The illustrator's model is a COST decision, made once, in _data/ai.yml
// (`illustrator_model`) — not here and not per call site. The fallback below is
// only for a checkout whose ai.yml predates the key.
const DEFAULT_MODEL = 'claude-sonnet-4-6';

function configuredModel() {
  try {
    const yml = fs.readFileSync(AI_YML, 'utf8');
    const m = yml.match(/^illustrator_model:\s*(\S+)/m);
    if (m) return m[1].replace(/^["']|["']$/g, '');
  } catch { /* ai.yml is optional for this path */ }
  return DEFAULT_MODEL;
}

// ── the brief ────────────────────────────────────────────────────────────────

const SYSTEM = [
  'You are a vector illustrator for lifehacker.dev, a technical publication with a',
  'dark, high-contrast, diagrammatic house style. You draw ONE picture of what an',
  'article is actually about — its concrete objects, structures, and process — as a',
  'fragment of SVG that will be composited into a banner someone else typeset.',
  'You never draw text, logos, faces, or generic technology collages.',
  'You answer with a CONCEPT line and one fenced svg block. Nothing else.',
].join(' ');

const ROLES = {
  ink: 'the brightest colour — the subject itself, the thing the eye should land on',
  cool: 'the primary signal colour of this section — flow, data, the working path',
  warm: 'the counter-colour — heat, failure, pressure, the thing going wrong',
  accent: "the section's highlight — use sparingly, for one detail that matters",
  grid: 'dim structural line-work — scaffolding, rails, the substrate',
  muted: 'secondary detail that should recede',
  bg0: 'the page behind everything — use only to knock a hole in a filled shape',
  bg1: 'a second background tone, same use',
};

function brief(article, sectionLabel) {
  const excerpt = article.body.slice(0, 1400);
  return `Draw the illustration for this article.

ARTICLE
  Section:     ${sectionLabel} (lifehacker.dev)
  Title:       ${article.title}
  Description: ${article.fields.description || '(none)'}
  Tags:        ${article.tags.join(', ') || '(none)'}
  Body excerpt:
---
${excerpt}
---

THE FRAME
  A ${MOTIF_GRID} x ${MOTIF_GRID} square. Coordinates run 0..${MOTIF_GRID} on both axes and
  everything you draw must live inside it. Compose to FILL the frame: the drawing
  must span at least 60% of both axes and sit centred near (500, 500).
  It is composited into the right-hand half of a wide banner, over a dim lattice
  field. The article's headline and byline are typeset separately, to the LEFT of
  your frame — do not draw them, do not leave room for them, do not letter anything.

THE PALETTE — the only colours that exist
${TOKENS.map((t) => `  ${t.padEnd(7)} ${ROLES[t]}`).join('\n')}
  Write them as attribute values: fill="cool", stroke="ink", fill="none".
  Raw hex, rgb(), and CSS colour names are rejected — the tokens resolve to this
  section's palette at render time, which is what keeps the site coherent.

HARD REQUIREMENTS
- Reply with ONE <g> element containing the whole drawing. No <svg> wrapper.
- Allowed elements only: g, path, circle, ellipse, rect, line, polyline, polygon,
  and defs/linearGradient/radialGradient/stop for gradients. No text, no images,
  no scripts, no filters, no external references of any kind.
- Between 10 and 60 shapes. Bold, flat, diagrammatic — the fewer shapes that
  carry the idea, the better it reads. Every stroke at least 6 units wide: this
  is seen at 300px in a card, where a hairline is nothing.
- At least two palette tokens, so the subject separates from its structure.
- Do NOT fill the frame with a background rectangle. The banner has a background;
  your drawing sits on it.

WHAT TO DRAW
  The specific subject of THIS article — the actual apparatus it describes: the
  pipeline, the cache layers, the failing check, the terminal, the wire, the loop.
  Somebody who reads the article should recognise the picture. A reader who has
  not should be able to guess what the piece is about. Generic circuit boards,
  lightbulbs, robots, brains, and rocket ships are failures, not illustrations.

FORMAT
CONCEPT: one sentence naming what the drawing depicts (it becomes the image's
accessible description, so describe the picture, not the article).
\`\`\`svg
<g> ... </g>
\`\`\``;
}

const RETRY = (previous, violations) => `Your drawing was rejected by the validator.

WHAT YOU SENT
\`\`\`svg
${previous.slice(0, 12000)}
\`\`\`

WHAT MUST CHANGE
${violations.map((v, i) => `${i + 1}. ${v}`).join('\n')}

Send the corrected drawing in full — the same CONCEPT line and one fenced svg
block containing the complete <g>. Do not send a diff or an explanation.`;

// ── the model call ───────────────────────────────────────────────────────────

// Drawing is slow — the model emits thousands of tokens of path data, and a cold
// CLI on a small runner adds a minute before the first one. The default is
// generous on purpose: a timeout here costs a whole attempt.
const CALL_TIMEOUT_MS = Number(process.env.LH_PREVIEW_TIMEOUT_MS) || 900000;

function callClaude(prompt, model, { timeoutMs = CALL_TIMEOUT_MS } = {}) {
  const outFile = path.join(os.tmpdir(), `lh-motif-${process.pid}-${Date.now()}.txt`);
  try {
    execFileSync('bash', [path.join(ROOT, 'scripts/ai/run.sh'),
      '--system', SYSTEM, '--prompt', prompt, '--out', outFile], {
      cwd: ROOT,
      env: { ...process.env, LH_AI_MODEL: model },
      encoding: 'utf8',
      timeout: timeoutMs,
      stdio: ['ignore', 'inherit', 'inherit'],
    });
    return fs.existsSync(outFile) ? fs.readFileSync(outFile, 'utf8') : '';
  } finally {
    if (fs.existsSync(outFile)) fs.unlinkSync(outFile);
  }
}

export function extractResponse(text) {
  const concept = (String(text).match(/^\s*CONCEPT:\s*(.+)$/mi) || [, ''])[1].trim();
  const fenced = String(text).match(/```(?:svg|xml|html)?\s*\n([\s\S]*?)```/);
  let art = fenced ? fenced[1] : String(text);
  // Tolerate a full document even though the brief asks for a fragment: strip the
  // wrapper rather than burning a retry on the one mistake that costs nothing.
  art = art.replace(/<\?[\s\S]*?\?>/g, '')
    .replace(/^[\s\S]*?<svg[^>]*>/, '')
    .replace(/<\/svg>[\s\S]*$/, '');
  const g = art.match(/<g[\s\S]*<\/g\s*>/);
  const defs = art.match(/<defs[\s\S]*?<\/defs\s*>/);
  const body = g ? `${defs && !g[0].includes('<defs') ? defs[0] : ''}${g[0]}` : art.trim();
  return { concept, body };
}

// ── one article ──────────────────────────────────────────────────────────────

function illustrate(article, { model, attempts, verbose }) {
  const sectionLabel = DESIGN.sections[article.section]?.label || article.section;
  const palette = (DESIGN.sections[article.section] || DESIGN.sections['field-notes']).palette;
  let prompt = brief(article, sectionLabel);
  let lastViolations = ['no response'];

  for (let attempt = 1; attempt <= attempts; attempt++) {
    const started = Date.now();
    const raw = callClaude(prompt, model);
    if (verbose) log(`  attempt ${attempt}: model replied in ${Math.round((Date.now() - started) / 1000)}s`);
    if (!raw.trim()) {
      const err = new Error('no output from scripts/ai/run.sh — set CLAUDE_CODE_OAUTH_TOKEN '
        + '(claude setup-token) or ANTHROPIC_API_KEY, or install the `claude` CLI');
      err.noCredential = true;
      throw err;
    }
    const { concept, body } = extractResponse(raw);
    let result;
    try {
      result = validateTree(parseFragment(body));
    } catch (e) {
      result = { ok: false, violations: [`the SVG did not parse: ${e.message}. Send one well-formed <g> element.`] };
    }
    if (result.ok) {
      if (verbose) {
        log(`  attempt ${attempt}: ${result.stats.drawables} shapes, `
          + `${(result.stats.span[0] * 100).toFixed(0)}%x${(result.stats.span[1] * 100).toFixed(0)}% of frame, `
          + `${result.stats.paints} tokens`);
      }
      return {
        document: serializeMotifDocument({
          tree: result.tree, concept, model, attempts: attempt, palette, title: article.title,
        }),
        concept,
        attempt,
        stats: result.stats,
      };
    }
    lastViolations = result.violations;
    warn(`attempt ${attempt}/${attempts} rejected: ${result.violations.join(' | ')}`);
    prompt = RETRY(body, result.violations);
  }
  throw new Error(`no valid drawing after ${attempts} attempts — last: ${lastViolations.join(' | ')}`);
}

// ── CLI ──────────────────────────────────────────────────────────────────────

const HELP = `Trace Bloom illustrator — Claude draws the article's subject

  -f, --file <path>   article to illustrate (repeatable)
      --changed       every git-new/modified markdown file
      --all           every article under pages/_posts and pages/_docs
      --section <s>   restrict --all to one section (hacks|tools|field-notes|wire|docs)
      --force         redraw an article that already has a motif
      --batch <n>     stop after n articles (default 4 for --all/--changed, 0 = no limit)
      --model <id>    override _data/ai.yml illustrator_model
      --attempts <n>  validation retries per article (default 3)
      --no-render     write the motif but do not re-render the banner
  -n, --dry-run       list what would be drawn; no model call, no writes
      --self-test     run the validator/compositor fixtures offline and exit
      --check         validate every committed motif; print findings as JSON
                      (what scripts/ci/lint_preview.rb runs — offline, no model)
  -v, --verbose
`;

function parseArgs(argv) {
  const a = {
    files: [], changed: false, all: false, section: null, force: false,
    batch: null, model: null, attempts: 3, render: true, dryRun: false,
    selfTest: false, check: false, verbose: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const v = argv[i];
    switch (v) {
      case '-f': case '--file': a.files.push(argv[++i]); break;
      case '--changed': a.changed = true; break;
      case '--all': a.all = true; break;
      case '--section': a.section = argv[++i]; break;
      case '--force': a.force = true; break;
      case '--batch': a.batch = Number(argv[++i]); break;
      case '--model': a.model = argv[++i]; break;
      case '--attempts': a.attempts = Math.max(1, Number(argv[++i]) || 3); break;
      case '--no-render': a.render = false; break;
      case '-n': case '--dry-run': a.dryRun = true; break;
      case '--self-test': a.selfTest = true; break;
      case '--check': a.check = true; break;
      case '-v': case '--verbose': a.verbose = true; break;
      case '-h': case '--help': a.help = true; break;
      default:
        if (v.startsWith('-')) { warn(`unknown flag ${v}`); a.bad = true; }
        else a.files.push(v);
    }
  }
  return a;
}

/** True when the article points at art that is NOT its own generated banner and
 *  that art exists — the one case where generate.mjs deliberately leaves the
 *  stamp alone. Mirrors the `bespoke` test in generate.mjs; keep them in step. */
function isBespoke(article) {
  const current = article.fields.preview || '';
  if (!current) return false;
  if (current === `/images/previews/${article.slug}.svg`) return false;
  if (current.startsWith('http')) return true;
  const clean = current.replace(/^\//, '');
  return fs.existsSync(path.join(ROOT, clean)) || fs.existsSync(path.join(ROOT, 'assets', clean));
}

function gitChanged() {
  try {
    return execFileSync('git', ['status', '--porcelain', '-uall'], { cwd: ROOT, encoding: 'utf8' })
      .split('\n')
      .filter((l) => l.length > 3 && !l.slice(0, 2).includes('D'))
      .map((l) => l.slice(3).trim())
      .map((p) => (p.includes(' -> ') ? p.split(' -> ')[1] : p))
      .map((p) => p.replace(/^"|"$/g, ''))
      .filter((p) => /\.(md|markdown)$/.test(p) && /^pages\//.test(p))
      .map((p) => path.join(ROOT, p))
      .filter((p) => fs.existsSync(p));
  } catch (e) {
    warn(`git status failed: ${e.message}`);
    return [];
  }
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) { process.stdout.write(HELP); return 0; }
  if (args.bad) return EXIT_FAILED;
  if (args.selfTest) return selfTest();
  if (args.check) return check();

  let targets = args.files.map((f) => (path.isAbsolute(f) ? f : path.join(ROOT, f)));
  const bulk = args.changed || args.all;
  if (args.changed) targets.push(...gitChanged());
  if (args.all) {
    targets.push(...findMarkdown(path.join(ROOT, 'pages/_posts')));
    targets.push(...findMarkdown(path.join(ROOT, 'pages/_docs')));
  }
  if (args.section) {
    targets = targets.filter((f) => f.replace(/\\/g, '/').includes(
      args.section === 'docs' ? '/_docs/' : `/_posts/${args.section}/`));
  }
  targets = [...new Set(targets)];
  if (!targets.length) { log('nothing to illustrate'); return 0; }

  const model = args.model || configuredModel();
  // A bulk run is capped by default. Drawing is the one part of this pipeline
  // that spends anything, and an unbounded --all is how a backfill turns into a
  // surprise: ask for more explicitly with --batch 0.
  const batch = args.batch === null ? (bulk ? 4 : 0) : args.batch;

  let drawn = 0, skipped = 0, failed = 0;
  const rendered = [];
  for (const file of targets) {
    if (batch && drawn >= batch) {
      log(`batch limit ${batch} reached — ${targets.length - drawn - skipped - failed} article(s) not considered; re-run to continue`);
      break;
    }
    let article;
    try {
      article = readArticle(file);
    } catch (e) {
      warn(`${file}: unreadable (${e.message})`); failed++; continue;
    }
    const rel = path.relative(ROOT, file);
    if (!article.hasFrontMatter || !article.slug) {
      if (args.verbose) log(`skip (no front matter): ${rel}`);
      skipped++; continue;
    }
    const dest = motifPath(ROOT, article.slug);
    if (fs.existsSync(dest) && !args.force) {
      if (args.verbose) log(`skip (already illustrated): ${rel}`);
      skipped++; continue;
    }
    // An article wearing BESPOKE art — a hand-picked screenshot, one of the
    // grandfathered AI-rendered PNGs — is somebody's real work, and generate.mjs
    // will not overwrite it. Drawing a motif for it anyway would spend a model
    // call on a picture no banner ever composites, and leave the gate reporting
    // `stale-motif` forever. Refuse here instead, and say what to do.
    if (isBespoke(article) && !args.force) {
      warn(`${rel} carries bespoke cover art (${article.fields.preview}) — the generated banner `
        + 'would not replace it, so a drawing here would never be composited. Re-run with --force '
        + 'to switch this article to a generated, illustrated banner.');
      skipped++; continue;
    }
    if (args.dryRun) {
      log(`[dry run] would draw ${rel} → ${MOTIF_DIR}/${article.slug}.svg (model ${model})`);
      drawn++; continue;
    }

    log(`drawing: ${article.title}`);
    try {
      const result = illustrate(article, { model, attempts: args.attempts, verbose: args.verbose });
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.writeFileSync(dest, result.document, 'utf8');
      log(`  ✓ ${MOTIF_DIR}/${article.slug}.svg — ${result.concept || '(no concept given)'}`);
      drawn++;
      rendered.push(file);
    } catch (e) {
      if (e.noCredential) {
        warn(e.message);
        return EXIT_NO_CREDENTIAL;
      }
      warn(`${rel}: ${e.message}`);
      failed++;
    }
  }

  // Re-composite the banners we just illustrated. generate.mjs is the ONLY thing
  // that writes a banner — one renderer, one skip policy, one place to fix.
  if (args.render && rendered.length) {
    const argv = ['scripts/preview/generate.mjs', ...rendered.flatMap((f) => ['-f', f])];
    try {
      execFileSync(process.execPath, argv, { cwd: ROOT, stdio: 'inherit' });
    } catch {
      warn('banner re-render failed — run node scripts/preview/generate.mjs -f <file>');
      failed++;
    }
  }

  log(`done: ${drawn} drawn, ${skipped} skipped, ${failed} failed`);
  return failed ? EXIT_FAILED : 0;
}

// ── the gate's half ──────────────────────────────────────────────────────────
// A motif is a COMMITTED INPUT to the renderer, so it needs the same treatment
// as the art itself: checked on every PR, by the harness, with findings that say
// what to run. Ruby owns the preview lint (scripts/ci/lint_preview.rb) but the
// validator lives here in JS, so this prints findings as JSON and the lint folds
// them into its own report rather than either side reimplementing the other.

function articleSlugs() {
  const slugs = new Map();
  for (const dir of ['pages/_posts', 'pages/_docs']) {
    for (const file of findMarkdown(path.join(ROOT, dir))) {
      try {
        const article = readArticle(file);
        if (article.hasFrontMatter && article.slug) {
          slugs.set(article.slug, { rel: path.relative(ROOT, file), bespoke: isBespoke(article) });
        }
      } catch { /* readArticle failures are lint_frontmatter's finding, not ours */ }
    }
  }
  return slugs;
}

function check() {
  const findings = [];
  const dir = path.join(ROOT, MOTIF_DIR);
  const files = fs.existsSync(dir)
    ? fs.readdirSync(dir).filter((f) => f.endsWith('.svg')).sort()
    : [];
  const slugs = files.length ? articleSlugs() : new Map();

  for (const name of files) {
    const rel = `${MOTIF_DIR}/${name}`;
    const slug = name.replace(/\.svg$/, '');
    let motif;
    try {
      motif = parseMotifDocument(fs.readFileSync(path.join(dir, name), 'utf8'));
    } catch (e) {
      findings.push({
        rule: 'invalid-motif', severity: 'error', file: rel,
        evidence: `${e.message} — a motif is composited into a banner, so an invalid one is a banner that cannot be rendered. Redraw it: node scripts/preview/illustrate.mjs --force -f <article>`,
      });
      continue;
    }
    if (!slugs.has(slug)) {
      findings.push({
        rule: 'orphan-motif', severity: 'warning', file: rel,
        evidence: 'no article has this slug — the drawing is never composited into anything. Delete it, or rename it to the slug of the article it belongs to.',
      });
      continue;
    }
    const banner = path.join(ROOT, 'assets/images/previews', `${slug}.svg`);
    const composited = fs.existsSync(banner)
      && fs.readFileSync(banner, 'utf8').includes(`data-motif="${motifStamp(motif)}"`);
    if (!composited) {
      const { rel: article, bespoke } = slugs.get(slug);
      findings.push({
        rule: 'stale-motif', severity: 'error', file: article,
        evidence: bespoke
          ? `${rel} was drawn but the article carries bespoke cover art, which the generator will not replace — so this drawing is composited into nothing. Delete the motif, or run: node scripts/preview/generate.mjs --force -f ${article}`
          : `${rel} was drawn or edited but its banner does not carry that drawing (digest ${motif.digest}) — the article still shows the un-illustrated cover. Run: node scripts/preview/generate.mjs -f ${article}`,
      });
    }
  }

  // The fixtures run here too: this is the only place in CI that proves the
  // whitelist still refuses a <script>, and it costs milliseconds.
  const failures = selfTest({ quiet: true });
  if (failures) {
    findings.push({
      rule: 'motif-selftest', severity: 'error', file: 'scripts/preview/illustrate.mjs',
      evidence: `${failures} motif self-test case(s) failed — the illustration whitelist or compositor has regressed. Run: node scripts/preview/illustrate.mjs --self-test`,
    });
  }

  process.stdout.write(`${JSON.stringify(findings)}\n`);
  return 0;   // findings are the output; the lint decides the gate
}

// ── self-test ────────────────────────────────────────────────────────────────
// Offline proof that the parts that must never be wrong are not wrong: the
// whitelist refuses what it must, the geometry checks catch the compositions
// that fail in a 300px card, and a composited banner is inert. No model call,
// no network — so this runs in the harness (scripts/ci/lint_preview.rb) on every
// PR, which is what stops this rung from rotting the way the last one did.

const GOOD = `<g>
  <rect x="180" y="180" width="640" height="120" rx="12" fill="none" stroke="grid" stroke-width="10"/>
  <rect x="180" y="340" width="640" height="120" rx="12" fill="none" stroke="cool" stroke-width="10"/>
  <rect x="180" y="500" width="640" height="120" rx="12" fill="none" stroke="cool" stroke-width="10"/>
  <rect x="180" y="660" width="640" height="120" rx="12" fill="warm" fill-opacity="0.25" stroke="warm" stroke-width="10"/>
  <path d="M240 240 L760 240" stroke="ink" stroke-width="8" fill="none"/>
  <circle cx="500" cy="720" r="34" fill="ink"/>
  <polyline points="300,400 420,400 420,560 620,560" fill="none" stroke="accent" stroke-width="8"/>
</g>`;

function selfTest({ quiet = false } = {}) {
  const say = (m) => { if (!quiet) console.log(m); };
  const cases = [
    ['a well-formed motif passes', GOOD, true, null],
    ['a script is refused', '<g><script>alert(1)</script>' + GOOD.slice(3), false, /<script> is not allowed/],
    ['an external image is refused', GOOD.replace('<circle', '<image href="https://x/y.png"/><circle'), false, /<image> is not allowed/],
    ['raw hex is refused', GOOD.replace('fill="ink"', 'fill="#ff0000"'), false, /not a palette token/],
    ['a foreignObject is refused', GOOD.replace('<circle', '<foreignObject width="10" height="10"/><circle'), false, /<foreignObject> is not allowed/],
    ['text is refused', GOOD.replace('<circle', '<text x="10" y="10">hi</text><circle'), false, /<text> is not allowed/],
    ['an off-frame drawing is refused', GOOD.replace('x="180" y="180"', 'x="1800" y="180"'), false, /must live inside/],
    ['a background plate is refused',
      '<g><rect x="0" y="0" width="1000" height="1000" fill="bg0"/>' + GOOD.slice(3), false, /covers most of the frame/],
    ['a lonely shape is refused', '<g><circle cx="500" cy="500" r="300" fill="ink"/></g>', false, /at least 6/],
    ['unbalanced markup is refused', '<g><circle cx="1" cy="1" r="1" fill="ink"></g>', false, /unbalanced tag|unclosed tag/],
    ['a hairline stroke is accepted (it gets clamped, not rejected)',
      GOOD.replace('stroke-width="10"', 'stroke-width="1"'), true, null],
  ];

  let failures = 0;
  const expect = (name, cond, detail) => {
    if (cond) { say(`  ok   ${name}`); return; }
    failures++;
    say(`  FAIL ${name}${detail ? ` — ${detail}` : ''}`);
  };

  say('[illustrate] self-test: validator');
  for (const [name, source, expectOk, expectRe] of cases) {
    let result;
    try {
      result = validateTree(parseFragment(source));
    } catch (e) {
      result = { ok: false, violations: [e.message] };
    }
    if (expectOk) {
      expect(name, result.ok, result.violations && result.violations.join(' | '));
    } else {
      const joined = (result.violations || []).join(' | ');
      expect(name, !result.ok && expectRe.test(joined), joined || 'accepted, but should not have been');
    }
  }

  say('[illustrate] self-test: compositor');
  const motif = parseMotifDocument(serializeMotifDocument({
    tree: parseFragment(GOOD),
    concept: 'A stack of cache layers with one invalidated.',
    model: 'self-test',
    attempts: 1,
    palette: DESIGN.sections.hacks.palette,
  }));
  const svg = renderFixtureBanner(motif);
  expect('banner carries the motif stamp', svg.includes(`data-motif="${motifStamp(motif)}"`));
  expect('banner is inert', !/<script|<foreignObject|<image\b/i.test(svg) && !/(?:href|src)\s*=\s*["']https?:/i.test(svg));
  expect('motif colours resolved to the section palette',
    svg.includes(DESIGN.sections.hacks.palette.cool) && !svg.includes('var(--cool)'));
  expect('headline still typeset', /<text[^>]*font-size="\d+"/.test(svg));
  const band = [DESIGN.layout.safeTop * DESIGN.canvas.height, DESIGN.layout.safeBottom * DESIGN.canvas.height];
  const ys = [...svg.matchAll(/<text[^>]*\sy="([\d.]+)"/g)].map((m) => Number(m[1]));
  expect('every headline baseline is inside the safe band',
    ys.length > 0 && ys.every((y) => y >= band[0] && y <= band[1]), ys.join(', '));
  expect('the drawing is placed in the art box, not over the headline plate',
    svg.includes(`translate(${DESIGN.motif.box.x} ${DESIGN.motif.box.y})`));
  // Regression guard, paid for in a banner that rendered one rectangle of a
  // 35-shape drawing: a clip-path and a transform on the SAME element makes the
  // clip resolve in the transformed space and eats the artwork.
  const clipped = svg.match(/<g[^>]*clip-path="url\(#motifclip\)"[^>]*>/);
  expect('the motif clip and its transform are on separate groups',
    !!clipped && !/transform=/.test(clipped[0]), clipped && clipped[0]);
  const round = parseMotifDocument(serializeMotifDocument({
    tree: motif.tree, concept: motif.concept, model: 'self-test', attempts: 1,
    palette: DESIGN.sections.wire.palette,
  }));
  expect('a motif round-trips to the same digest', round.digest === motif.digest,
    `${round.digest} vs ${motif.digest}`);
  const thin = serializeMotifDocument({
    tree: parseFragment(GOOD.replace('stroke-width="10"', 'stroke-width="1"')),
    concept: 'thin', model: 'self-test', attempts: 1, palette: DESIGN.sections.hacks.palette,
  });
  expect('a hairline stroke is clamped to the legibility floor',
    !thin.includes('stroke-width="1"') && thin.includes('stroke-width="4"'));

  say(failures ? `[illustrate] self-test: ${failures} FAILED` : '[illustrate] self-test: all passed');
  return quiet ? failures : (failures ? EXIT_FAILED : 0);
}

function renderFixtureBanner(motif) {
  const params = deriveParams({
    slug: 'self-test', title: 'Self Test', tags: ['test'], section: 'hacks', body: 'a self test',
  }, DESIGN);
  return renderSVG(buildScene(params, DESIGN), {
    title: 'Order your Dockerfile so the layer cache does its job',
    date: '2026-08-22', author: 'claude', sectionLabel: 'Hacks', motif,
  }, DESIGN);
}

process.exit(main());
