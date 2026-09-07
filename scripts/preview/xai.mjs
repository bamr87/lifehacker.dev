#!/usr/bin/env node
// Trace Bloom — OPT-IN xAI covers (OAuth first).
//
//   node scripts/preview/xai.mjs -f pages/_posts/hacks/2026-08-01-thing.md
//   node scripts/preview/xai.mjs --author cass                 # every cass byline
//   node scripts/preview/generate.mjs --provider xai --author cass
//
// Default cover art stays offline (generate.mjs). THIS path is the optional
// extra, authenticated OAuth-first. Default --format svg: Grok draws a motif
// fragment (same validator as illustrate.mjs), Trace Bloom typesets the title.
// --format raster is the Imagine JPEG path. A missing credential exits 3.
//
// Exit codes: 0 ok · 1 one or more articles failed · 3 no xAI credential.

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

import { readArticle, stampPreview, findMarkdown, motifPath, MOTIF_DIR } from './lib/article.mjs';
import { resolveXaiAuth, configuredXai } from './lib/xai_auth.mjs';
import { authorStyle, resolvePalette } from './lib/author-style.mjs';
import { parseFragment, validateTree, serializeMotifDocument } from './lib/motif.mjs';
import { SYSTEM, CONCEPT_SYSTEM, brief, conceptBrief, RETRY, extractResponse } from './illustrate.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..', '..');
const DESIGN = JSON.parse(fs.readFileSync(path.join(ROOT, '_data/preview/design.json'), 'utf8'));
const OUT_DIR = 'assets/images/previews';
const FM_VALUE_PREFIX = '/images/previews';
const EXIT_FAILED = 1;
const EXIT_NO_CREDENTIAL = 3;

const log = (m) => console.log(`[xai-preview] ${m}`);
const warn = (m) => console.error(`[xai-preview] WARN: ${m}`);
const die = (m, code = EXIT_FAILED) => { console.error(`[xai-preview] ERROR: ${m}`); process.exit(code); };

const HELP = `xAI preview covers — OAuth first, opt-in, no silent fallback

  -f, --file <path>   article to paint (repeatable)
      --changed       every git-new/modified markdown file under pages/
      --all           every article under pages/_posts and pages/_docs
      --author <key>  restrict to one authors.yml key (e.g. cass)
      --section <s>   restrict --all to one section
      --format <id>   svg (default: Grok draws a motif, Trace Bloom typesets)
                      raster (Imagine JPEG)
      --force         redraw an article that already has an xAI cover
      --batch <n>     stop after n articles (default 4 for --all/--changed, 0 = no limit)
      --model <id>    override _data/ai.yml xai_svg_model or xai_image_model
      --attempts <n>  SVG validator retries (default 3)
      --aspect <r>    Imagine aspect ratio (default 3:2)
      --resolution <r> 1k or 2k (default 1k)
      --quality <q>   low or medium (default medium)
      --jpeg-quality <n>  sips JPEG quality 0-100 (default 70)
      --compress-only recompress existing preview rasters; no Imagine calls
  -n, --dry-run       list what would be painted; no network, no writes
      --self-test     offline checks (prompt + auth resolution) and exit
  -v, --verbose
`;

function parseArgs(argv) {
  const a = {
    files: [], changed: false, all: false, author: null, section: null, force: false,
    format: 'svg', batch: null, model: null, attempts: 3, aspect: null,
    resolution: null, quality: null, jpegQuality: 70, compressOnly: false,
    dryRun: false, selfTest: false, verbose: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const v = argv[i];
    switch (v) {
      case '-f': case '--file': a.files.push(argv[++i]); break;
      case '--changed': a.changed = true; break;
      case '--all': a.all = true; break;
      case '--author': a.author = argv[++i]; break;
      case '--section': a.section = argv[++i]; break;
      case '--format': a.format = argv[++i]; break;
      case '--force': a.force = true; break;
      case '--attempts': a.attempts = Math.max(1, Number(argv[++i]) || 3); break;
      case '--batch': a.batch = Number(argv[++i]); break;
      case '--model': a.model = argv[++i]; break;
      case '--aspect': a.aspect = argv[++i]; break;
      case '--resolution': a.resolution = argv[++i]; break;
      case '--quality': a.quality = argv[++i]; break;
      case '--jpeg-quality': a.jpegQuality = Math.max(1, Math.min(100, Number(argv[++i]) || 70)); break;
      case '--compress-only': a.compressOnly = true; break;
      case '-n': case '--dry-run': a.dryRun = true; break;
      case '--self-test': a.selfTest = true; break;
      case '-v': case '--verbose': a.verbose = true; break;
      case '-h': case '--help': a.help = true; break;
      default:
        if (v.startsWith('-')) { warn(`unknown flag ${v}`); a.bad = true; }
        else a.files.push(v);
    }
  }
  return a;
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

function isJpeg(buf) {
  return Buffer.isBuffer(buf) && buf.length > 2 && buf[0] === 0xff && buf[1] === 0xd8;
}

function isPng(buf) {
  return Buffer.isBuffer(buf) && buf.length > 8 && buf[0] === 0x89 && buf[1] === 0x50;
}

function isBespoke(article) {
  const current = article.fields.preview || '';
  if (!current) return false;
  const own = new Set([
    `${FM_VALUE_PREFIX}/${article.slug}.svg`,
    `${FM_VALUE_PREFIX}/${article.slug}.png`,
    `${FM_VALUE_PREFIX}/${article.slug}.jpg`,
    `${FM_VALUE_PREFIX}/${article.slug}.jpeg`,
  ]);
  if (own.has(current)) return false;
  if (current.startsWith('http')) return true;
  const clean = current.replace(/^\//, '');
  return fs.existsSync(path.join(ROOT, clean)) || fs.existsSync(path.join(ROOT, 'assets', clean));
}

function alreadyPainted(slug) {
  const jpg = path.join(ROOT, OUT_DIR, `${slug}.jpg`);
  return fs.existsSync(jpg) && fs.existsSync(`${jpg}.prompt.json`);
}

function compressRaster(buf, jpegQuality) {
  const tmp = path.join(os.tmpdir(), `lh-xai-${process.pid}-${Date.now()}`);
  try {
    if (isJpeg(buf)) {
      const src = `${tmp}.src.jpg`;
      const dest = `${tmp}.out.jpg`;
      fs.writeFileSync(src, buf);
      execFileSync('sips', ['-s', 'format', 'jpeg', '-s', 'formatOptions', String(jpegQuality), src, '--out', dest], {
        stdio: ['ignore', 'pipe', 'pipe'],
      });
      const out = fs.readFileSync(dest);
      return out.length && out.length < buf.length ? out : buf;
    }
    if (isPng(buf)) {
      const src = `${tmp}.src.png`;
      const dest = `${tmp}.out.png`;
      fs.writeFileSync(src, buf);
      execFileSync('pngquant', ['--quality=55-75', '--speed=1', '--skip-if-larger', '--force', '--output', dest, src], {
        stdio: ['ignore', 'pipe', 'pipe'],
      });
      if (fs.existsSync(dest)) {
        const out = fs.readFileSync(dest);
        return out.length && out.length < buf.length ? out : buf;
      }
    }
  } catch {
    return buf;
  } finally {
    for (const ext of ['.src.jpg', '.out.jpg', '.src.png', '.out.png']) {
      const p = `${tmp}${ext}`;
      if (fs.existsSync(p)) fs.unlinkSync(p);
    }
  }
  return buf;
}

function writeCover(article, raw, { jpegQuality, prompt, auth, cfg }) {
  const compressed = compressRaster(raw, jpegQuality);
  const jpeg = isJpeg(compressed);
  const ext = jpeg ? 'jpg' : 'png';
  const dest = path.join(ROOT, OUT_DIR, `${article.slug}.${ext}`);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, compressed);
  const sidecar = {
    source: 'xai',
    auth: auth.mode,
    model: cfg.model,
    aspect: cfg.aspect,
    resolution: cfg.resolution,
    quality: cfg.quality,
    jpeg_quality: jpeg ? jpegQuality : null,
    bytes: compressed.length,
    prompt,
    sha256: crypto.createHash('sha256').update(compressed).digest('hex'),
    generated: new Date().toISOString().slice(0, 10),
    note: 'AI-generated raster cover via xAI Imagine. generate.mjs will not overwrite this stamp unless --force.',
  };
  fs.writeFileSync(`${dest}.prompt.json`, `${JSON.stringify(sidecar, null, 2)}\n`);
  stampPreview(article.file, `${FM_VALUE_PREFIX}/${article.slug}.${ext}`);
  for (const leftoverExt of jpeg ? ['svg', 'png'] : ['svg']) {
    const leftover = path.join(ROOT, OUT_DIR, `${article.slug}.${leftoverExt}`);
    if (!fs.existsSync(leftover)) continue;
    if (leftoverExt === 'png' && isPng(fs.readFileSync(leftover))) continue;
    fs.unlinkSync(leftover);
    const side = `${leftover}.prompt.json`;
    if (fs.existsSync(side)) fs.unlinkSync(side);
  }
  return { dest, bytes: compressed.length, ext };
}

export function artPrompt(article, palette, sectionLabel) {
  const excerpt = String(article.body || '').slice(0, 500).replace(/\s+/g, ' ').trim();
  return `Cover illustration for a lifehacker.dev ${sectionLabel} article.

TITLE — typeset this exact headline, large, high-contrast, in the vertical middle 60% of the frame. No other words, no byline, no watermark, no logo:
${article.title}

SUBJECT
${article.fields.description || article.title}

${excerpt ? `NOTES\n${excerpt}` : ''}

ART DIRECTION
Trace Bloom: dark field ${palette.bg0} over ${palette.bg1}, lattice ${palette.grid}, signal ${palette.cool}, heat ${palette.warm}, ink ${palette.ink}, accent ${palette.accent}. Diagrammatic, high-contrast, cinematic 3:2 landscape. Draw the concrete apparatus this article is about — not a generic circuit board, robot, brain, or rocket. No faces. No UI chrome. No stock-tech collage. The still frame must read at 300px.`;
}

async function generateImage({ token, base, model, prompt, aspect, resolution, quality }) {
  const url = `${base.replace(/\/$/, '')}/images/generations`;
  const body = JSON.stringify({
    model, prompt, n: 1,
    aspect_ratio: aspect,
    resolution,
    quality,
    response_format: 'b64_json',
  });
  for (let attempt = 1; ; attempt++) {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body,
    });
    const text = await res.text().catch(() => '');
    if (res.ok) {
      let json;
      try { json = JSON.parse(text); } catch {
        throw new Error('images API returned non-JSON');
      }
      return json;
    }
    const retryable = res.status === 429 || res.status >= 500;
    if (retryable && attempt < 4) {
      const wait = res.status === 429 ? 15000 * attempt : 5000;
      warn(`${res.status} from the API — retrying in ${wait / 1000}s (attempt ${attempt}/4)`);
      await new Promise((r) => setTimeout(r, wait));
      continue;
    }
    throw new Error(`images API returned ${res.status}: ${text.slice(0, 400)}`);
  }
}

async function decodeImage(json) {
  const item = json && json.data && json.data[0];
  if (item && item.b64_json) return Buffer.from(item.b64_json, 'base64');
  const href = item && (item.url || item.image_url);
  if (href) {
    const res = await fetch(href);
    if (!res.ok) throw new Error(`image download returned ${res.status}`);
    return Buffer.from(await res.arrayBuffer());
  }
  throw new Error(`API response carried no image data: ${JSON.stringify(json).slice(0, 300)}`);
}

async function chatXai({ token, base, model, system, prompt, temperature = 0.4 }) {
  const url = `${base.replace(/\/$/, '')}/chat/completions`;
  const body = JSON.stringify({
    model,
    temperature,
    max_tokens: 8000,
    messages: [
      { role: 'system', content: system },
      { role: 'user', content: prompt },
    ],
  });
  for (let attempt = 1; ; attempt++) {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body,
    });
    const text = await res.text().catch(() => '');
    if (res.ok) {
      let json;
      try { json = JSON.parse(text); } catch {
        throw new Error('chat API returned non-JSON');
      }
      const content = json.choices && json.choices[0] && json.choices[0].message
        && json.choices[0].message.content;
      if (!content) throw new Error('chat API returned no message content');
      return content;
    }
    const retryable = res.status === 429 || res.status >= 500;
    if (retryable && attempt < 4) {
      const wait = res.status === 429 ? 15000 * attempt : 5000;
      warn(`${res.status} from chat — retrying in ${wait / 1000}s (attempt ${attempt}/4)`);
      await new Promise((r) => setTimeout(r, wait));
      continue;
    }
    throw new Error(`chat API returned ${res.status}: ${text.slice(0, 400)}`);
  }
}

function parseConcept(text) {
  const grab = (label) => {
    const m = String(text).match(new RegExp(`^\\s*${label}:\\s*(.+)$`, 'mi'));
    return m ? m[1].trim() : '';
  };
  return {
    concept: grab('CONCEPT'),
    objects: grab('OBJECTS'),
    refuse: grab('REFUSE'),
  };
}

async function illustrateSvg(article, { auth, cfg, attempts, verbose }) {
  const sectionLabel = DESIGN.sections[article.section]?.label || article.section;
  const style = authorStyle(DESIGN, article.author);
  const palette = resolvePalette(DESIGN, article.section, article.author);
  const model = cfg.svgModel;
  const direction = style && style.direction;

  const startedConcept = Date.now();
  const conceptRaw = await chatXai({
    token: auth.token, base: cfg.base, model, system: CONCEPT_SYSTEM,
    prompt: conceptBrief(article, sectionLabel, direction),
    temperature: 0.8,
  });
  const approved = parseConcept(conceptRaw);
  if (!approved.concept) {
    throw new Error('concept pass returned no CONCEPT line — refusing to draw a guess');
  }
  if (verbose) {
    log(`  concept in ${Math.round((Date.now() - startedConcept) / 1000)}s: ${approved.concept}`);
  }

  let prompt = brief(article, sectionLabel, direction, approved);
  let lastViolations = ['no response'];

  for (let attempt = 1; attempt <= attempts; attempt++) {
    const started = Date.now();
    const raw = await chatXai({
      token: auth.token, base: cfg.base, model, system: SYSTEM, prompt, temperature: 0.25,
    });
    if (verbose) log(`  draw ${attempt}: model replied in ${Math.round((Date.now() - started) / 1000)}s`);
    const { concept, body } = extractResponse(raw);
    let result;
    try {
      result = validateTree(parseFragment(body), { minElements: 16, maxElements: 80 });
    } catch (e) {
      result = { ok: false, violations: [`the SVG did not parse: ${e.message}. Send one well-formed <g> element.`] };
    }
    if (result.ok) {
      if (verbose) {
        log(`  draw ${attempt}: ${result.stats.drawables} shapes, `
          + `${(result.stats.span[0] * 100).toFixed(0)}%x${(result.stats.span[1] * 100).toFixed(0)}% of frame`);
      }
      return {
        document: serializeMotifDocument({
          tree: result.tree,
          concept: approved.concept || concept,
          model, attempts: attempt, palette, title: article.title,
        }),
        concept: approved.concept || concept,
      };
    }
    lastViolations = result.violations;
    warn(`draw ${attempt}/${attempts} rejected: ${result.violations.join(' | ')}`);
    prompt = RETRY(body, result.violations);
  }
  throw new Error(`no valid drawing after ${attempts} attempts — last: ${lastViolations.join(' | ')}`);
}

function dropRasterCover(article) {
  for (const ext of ['jpg', 'jpeg', 'png']) {
    const leftover = path.join(ROOT, OUT_DIR, `${article.slug}.${ext}`);
    if (fs.existsSync(leftover)) fs.unlinkSync(leftover);
    const side = `${leftover}.prompt.json`;
    if (fs.existsSync(side)) fs.unlinkSync(side);
  }
}

async function paint(article, { auth, cfg, verbose }) {
  const sectionLabel = DESIGN.sections[article.section]?.label || article.section;
  const palette = (DESIGN.sections[article.section] || DESIGN.sections['field-notes']).palette;
  const prompt = artPrompt(article, palette, sectionLabel);
  if (verbose) log(`  prompt ${prompt.length} chars, model ${cfg.model} ${cfg.aspect} ${cfg.resolution}`);
  const json = await generateImage({
    token: auth.token, base: cfg.base, model: cfg.model, prompt,
    aspect: cfg.aspect, resolution: cfg.resolution, quality: cfg.quality,
  });
  const png = await decodeImage(json);
  return { png, prompt };
}

function compressOnly(jpegQuality, dryRun) {
  const dir = path.join(ROOT, OUT_DIR);
  const files = fs.readdirSync(dir).filter((f) => /\.(png|jpe?g)$/i.test(f)).sort();
  let changed = 0, skipped = 0;
  for (const name of files) {
    const src = path.join(dir, name);
    const raw = fs.readFileSync(src);
    const compressed = compressRaster(raw, jpegQuality);
    const jpeg = isJpeg(compressed);
    const destName = jpeg ? name.replace(/\.png$/i, '.jpg') : name;
    const dest = path.join(dir, destName);
    if (compressed.length >= raw.length && destName === name) {
      skipped++; continue;
    }
    if (dryRun) {
      log(`[dry run] ${name} ${(raw.length / 1024).toFixed(0)} kB → ${destName} ${(compressed.length / 1024).toFixed(0)} kB`);
      changed++; continue;
    }
    fs.writeFileSync(dest, compressed);
    if (dest !== src) {
      fs.unlinkSync(src);
      const oldSide = `${src}.prompt.json`;
      const newSide = `${dest}.prompt.json`;
      if (fs.existsSync(oldSide)) fs.renameSync(oldSide, newSide);
      const slug = name.replace(/\.(png|jpe?g)$/i, '');
      for (const file of [
        ...findMarkdown(path.join(ROOT, 'pages/_posts')),
        ...findMarkdown(path.join(ROOT, 'pages/_docs')),
      ]) {
        try {
          const article = readArticle(file);
          if (article.fields.preview === `${FM_VALUE_PREFIX}/${slug}.png`) {
            stampPreview(file, `${FM_VALUE_PREFIX}/${slug}.jpg`);
          }
        } catch { /* skip unreadable */ }
      }
    }
    log(`compressed ${name} ${(raw.length / 1024).toFixed(0)} kB → ${destName} ${(compressed.length / 1024).toFixed(0)} kB`);
    changed++;
  }
  log(`done: ${changed} compressed, ${skipped} already small`);
  return 0;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) { process.stdout.write(HELP); return 0; }
  if (args.bad) return EXIT_FAILED;
  if (args.selfTest) return selfTest();
  if (args.compressOnly) return compressOnly(args.jpegQuality, args.dryRun);
  if (args.format !== 'svg' && args.format !== 'raster') {
    warn(`unknown --format ${args.format} (want svg or raster)`);
    return EXIT_FAILED;
  }

  const impliedAuthorAll = !!(args.author && !args.files.length && !args.changed && !args.all);
  if (impliedAuthorAll) args.all = true;

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
  if (!targets.length) { log('nothing to paint'); return 0; }

  const cfg = configuredXai(ROOT);
  if (args.model) {
    if (args.format === 'svg') cfg.svgModel = args.model;
    else cfg.model = args.model;
  }
  if (args.aspect) cfg.aspect = args.aspect;
  if (args.resolution) cfg.resolution = args.resolution;
  if (args.quality) cfg.quality = args.quality;
  const batch = args.batch === null ? (impliedAuthorAll ? 0 : (bulk ? 4 : 0)) : args.batch;

  let auth = null;
  if (!args.dryRun) {
    try {
      auth = await resolveXaiAuth();
    } catch (e) {
      if (e.noCredential) {
        warn(e.message);
        return EXIT_NO_CREDENTIAL;
      }
      die(e.message, EXIT_NO_CREDENTIAL);
    }
    log(`auth ${auth.mode} via ${auth.source}`);
  }

  let painted = 0, skipped = 0, failed = 0;
  for (const file of targets) {
    if (batch && painted >= batch) {
      log(`batch limit ${batch} reached — ${targets.length - painted - skipped - failed} article(s) not considered; re-run to continue`);
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
    if (args.author && article.author !== args.author) {
      skipped++; continue;
    }
    if (isBespoke(article) && !args.force) {
      if (args.verbose) log(`skip (bespoke): ${rel}`);
      skipped++; continue;
    }
    const svgMode = args.format === 'svg';
    const destMotif = motifPath(ROOT, article.slug);
    if (svgMode && fs.existsSync(destMotif) && !args.force) {
      if (args.verbose) log(`skip (already illustrated): ${rel}`);
      skipped++; continue;
    }
    if (!svgMode && alreadyPainted(article.slug) && !args.force) {
      if (args.verbose) log(`skip (already painted): ${rel}`);
      skipped++; continue;
    }
    if (args.dryRun) {
      const out = svgMode
        ? `${MOTIF_DIR}/${article.slug}.svg (model ${cfg.svgModel})`
        : `${OUT_DIR}/${article.slug}.jpg (model ${cfg.model})`;
      log(`[dry run] would paint ${rel} → ${out}`);
      painted++; continue;
    }

    log(`${svgMode ? 'drawing' : 'painting'}: ${article.title}`);
    try {
      if (svgMode) {
        const result = await illustrateSvg(article, {
          auth, cfg, attempts: args.attempts, verbose: args.verbose,
        });
        fs.mkdirSync(path.dirname(destMotif), { recursive: true });
        fs.writeFileSync(destMotif, result.document, 'utf8');
        dropRasterCover(article);
        execFileSync(process.execPath, [path.join(HERE, 'generate.mjs'), '--force', '-f', file], {
          cwd: ROOT, stdio: 'inherit',
        });
        log(`  ✓ ${MOTIF_DIR}/${article.slug}.svg — ${result.concept || '(no concept given)'}`);
      } else {
        const result = await paint(article, { auth, cfg, verbose: args.verbose });
        const written = writeCover(article, result.png, {
          jpegQuality: args.jpegQuality, prompt: result.prompt, auth, cfg,
        });
        log(`  ✓ ${path.relative(ROOT, written.dest)} (${(written.bytes / 1024).toFixed(0)} kB)`);
      }
      painted++;
      await new Promise((r) => setTimeout(r, 800));
    } catch (e) {
      warn(`${rel}: ${e.message}`);
      failed++;
    }
  }

  log(`done: ${painted} painted, ${skipped} skipped, ${failed} failed`);
  return failed ? EXIT_FAILED : 0;
}

function selfTest() {
  let failures = 0;
  const say = (name, cond, detail) => {
    if (cond) { console.log(`  ok   ${name}`); return; }
    failures++;
    console.log(`  FAIL ${name}${detail ? ` — ${detail}` : ''}`);
  };
  console.log('[xai-preview] self-test');
  const article = {
    title: 'Order your Dockerfile so the layer cache does its job',
    fields: { description: 'Put the rarely-changing layers first.' },
    body: 'A dockerfile is a stack of cache layers.',
    section: 'hacks',
  };
  const palette = DESIGN.sections.hacks.palette;
  const prompt = artPrompt(article, palette, 'Hacks');
  say('prompt carries the title', prompt.includes(article.title));
  say('prompt carries the section palette', prompt.includes(palette.cool) && prompt.includes(palette.bg0));
  say('prompt forbids generic collage', /no faces/i.test(prompt));
  const cfg = configuredXai(ROOT);
  say('default raster model is grok-imagine-image-2.0', cfg.model === 'grok-imagine-image-2.0', cfg.model);
  say('default svg model is grok-4', cfg.svgModel === 'grok-4', cfg.svgModel);
  say('default aspect is 3:2', cfg.aspect === '3:2', cfg.aspect);
  const cass = authorStyle(DESIGN, 'cass');
  say('cass author style exists', !!(cass && cass.format === 'svg' && cass.lattice === 'isometric'));
  say('cass palette is not the hacks palette', cass && cass.palette.cool !== DESIGN.sections.hacks.palette.cool);
  const cassConcept = conceptBrief(
    { title: 'Threat-model your dotfiles', fields: { description: 'x' }, body: 'x', tags: [] },
    'Hacks', cass.direction,
  );
  say('concept pass forbids stock padlocks', /padlock/.test(cassConcept) && /CONCEPT:/.test(cassConcept));
  const cassDraw = brief(
    { title: 'Threat-model your dotfiles', fields: { description: 'x' }, body: 'x', tags: [] },
    'Hacks', cass.direction,
    { concept: 'a ssh config leaking through a cracked laptop hinge', objects: 'ssh config; laptop; known_hosts', refuse: 'padlock; skull' },
  );
  say('draw pass pins the approved concept', cassDraw.includes('cracked laptop hinge') && cassDraw.includes('APPROVED CONCEPT'));

  const prev = process.env.XAI_OAUTH_TOKEN;
  process.env.XAI_OAUTH_TOKEN = 'test-oauth-token';
  return resolveXaiAuth().then((auth) => {
    say('XAI_OAUTH_TOKEN wins', auth.mode === 'oauth' && auth.source === 'XAI_OAUTH_TOKEN');
    if (prev === undefined) delete process.env.XAI_OAUTH_TOKEN;
    else process.env.XAI_OAUTH_TOKEN = prev;
    console.log(failures ? `[xai-preview] self-test: ${failures} FAILED` : '[xai-preview] self-test: all passed');
    return failures ? EXIT_FAILED : 0;
  }).catch((e) => {
    if (prev === undefined) delete process.env.XAI_OAUTH_TOKEN;
    else process.env.XAI_OAUTH_TOKEN = prev;
    say('auth resolution', false, e.message);
    return EXIT_FAILED;
  });
}

main().then((code) => process.exit(code)).catch((e) => die(e && e.stack ? e.stack : String(e)));
