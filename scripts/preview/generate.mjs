#!/usr/bin/env node
// Trace Bloom — the preview-banner generator.
//
//   node scripts/preview/generate.mjs -f pages/_posts/hacks/2026-08-01-thing.md
//   node scripts/preview/generate.mjs --changed          # git-new/modified .md
//   node scripts/preview/generate.mjs --all --force      # rebuild the whole site
//   node scripts/preview/generate.mjs --scene -f <file>  # dump the scene as JSON
//
// Replaces scripts/generate-preview-images.sh + scripts/claude_svg_banner.py.
// No gem, no API key, no rasterizer, no network: the art is COMPUTED from the
// article, so the same article always yields the same banner and two articles
// can never share one. There is no template fallback, because a fallback that
// ships generic wallpaper is how 200 of 243 articles ended up wearing four
// pictures between them. See docs/PREVIEW-IMAGES.md.
//
// Exit codes: 0 ok · 1 one or more articles failed.

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

import { deriveParams, buildScene } from './lib/core.mjs';
import { renderSVG, GENERATOR } from './lib/svg.mjs';
import { readArticle, stampPreview, findMarkdown, slugify } from './lib/article.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..', '..');
const DESIGN = JSON.parse(fs.readFileSync(path.join(ROOT, '_data/preview/design.json'), 'utf8'));

const OUT_DIR = 'assets/images/previews';
const FM_VALUE_PREFIX = '/images/previews';   // theme adds /assets back

const log = (m) => console.log(`[trace-bloom] ${m}`);
const warn = (m) => console.error(`[trace-bloom] WARN: ${m}`);

// ── args ─────────────────────────────────────────────────────────────────────
function parseArgs(argv) {
  const a = {
    files: [], changed: false, all: false, section: null, force: false,
    dryRun: false, scene: false, verbose: false, seed: null, outDir: OUT_DIR,
  };
  for (let i = 0; i < argv.length; i++) {
    const v = argv[i];
    switch (v) {
      case '-f': case '--file': a.files.push(argv[++i]); break;
      case '--changed': a.changed = true; break;
      case '--all': a.all = true; break;
      case '--section': a.section = argv[++i]; break;
      case '--force': a.force = true; break;
      case '-n': case '--dry-run': a.dryRun = true; break;
      case '--scene': a.scene = true; break;
      case '-v': case '--verbose': a.verbose = true; break;
      case '--seed': a.seed = Number(argv[++i]); break;
      case '--out-dir': a.outDir = argv[++i]; break;
      case '-h': case '--help': a.help = true; break;
      default:
        if (v.startsWith('-')) { warn(`unknown flag ${v}`); a.bad = true; }
        else a.files.push(v);
    }
  }
  return a;
}

const HELP = `Trace Bloom preview banners

  -f, --file <path>   article to illustrate (repeatable)
      --changed       every git-new/modified markdown file
      --all           every article under pages/_posts and pages/_docs
      --section <s>   restrict --all to one section (hacks|tools|field-notes|docs)
      --force         regenerate even when the banner already exists
  -n, --dry-run       report what would be written
      --scene         print the generated scene as JSON (no files written)
      --seed <n>      override the derived seed (exploration only)
  -v, --verbose
`;

function gitChanged() {
  try {
    const out = execFileSync('git', ['status', '--porcelain', '-uall'], { cwd: ROOT, encoding: 'utf8' });
    return out.split('\n')
      .filter((l) => l.length > 3 && !/^(D |ception D)/.test(l.slice(0, 2)))
      .map((l) => l.slice(3).trim())
      .map((p) => (p.includes(' -> ') ? p.split(' -> ')[1] : p))
      .map((p) => p.replace(/^"|"$/g, ''))
      .filter((p) => /\.(md|markdown)$/.test(p))
      .map((p) => path.join(ROOT, p))
      .filter((p) => fs.existsSync(p));
  } catch (e) {
    warn(`git status failed: ${e.message}`);
    return [];
  }
}

// ── main ─────────────────────────────────────────────────────────────────────
function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) { process.stdout.write(HELP); return 0; }
  if (args.bad) return 1;

  let targets = args.files.map((f) => (path.isAbsolute(f) ? f : path.join(ROOT, f)));
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

  const outAbs = path.join(ROOT, args.outDir);
  let made = 0, skipped = 0, failed = 0;

  for (const file of targets) {
    let article;
    try {
      article = readArticle(file);
    } catch (e) {
      warn(`${file}: unreadable (${e.message})`); failed++; continue;
    }
    const rel = path.relative(ROOT, file);
    if (!article.hasFrontMatter) {
      if (args.verbose) log(`skip (no front matter): ${rel}`);
      skipped++; continue;
    }
    if (!article.slug) { warn(`${rel}: cannot derive a slug from the title`); failed++; continue; }

    const svgPath = path.join(outAbs, `${article.slug}.svg`);
    const stamp = `${FM_VALUE_PREFIX}/${article.slug}.svg`;
    const current = article.fields.preview || '';
    // "Owns a banner" is about CONTENT, not filename. An article whose stamp
    // already points at <slug>.svg can still be carrying art from a previous
    // generation — that is how the old template output survived a rewrite. Only
    // a file bearing the current generator version counts as up to date.
    const isOwnPath = current === stamp;
    const ownsBanner = isOwnPath && fs.existsSync(svgPath)
      && fs.readFileSync(svgPath, 'utf8').includes(`data-generator="${GENERATOR}"`);
    // A SHARED placeholder is the thing we exist to replace; a bespoke image
    // (the grandfathered AI-rendered PNGs, a hand-picked screenshot) is somebody's
    // real work and is left alone unless --force says otherwise.
    // A stamp pointing at a file that does not exist is a broken banner, not a
    // bespoke one — the article renders no cover at all, so it needs generating.
    const currentExists = current.startsWith('http')
      || (!!current && (fs.existsSync(path.join(ROOT, current.replace(/^\//, '')))
        || fs.existsSync(path.join(ROOT, 'assets', current.replace(/^\//, '')))));
    const isPlaceholder = !current || !currentExists || /\/section-[a-z-]+\.(svg|png)$/.test(current);
    // Bespoke = art that is NOT this article's own generated banner. An article
    // already pointing at its own slug is ours to refresh, however stale.
    const bespoke = !isOwnPath && !isPlaceholder;
    if (!args.force && !args.scene && (ownsBanner || bespoke)) {
      if (args.verbose) log(`skip (${bespoke ? 'bespoke preview' : 'has its own banner'}): ${rel}`);
      skipped++; continue;
    }

    const params = deriveParams({
      slug: article.slug, title: article.title, tags: article.tags,
      section: article.section, body: article.body,
    }, DESIGN);
    if (args.seed !== null && Number.isFinite(args.seed)) params.seed = args.seed;

    const scene = buildScene(params, DESIGN);

    if (args.scene) {
      process.stdout.write(JSON.stringify({ article: rel, params, scene }, null, 2) + '\n');
      made++; continue;
    }
    if (args.dryRun) {
      log(`[dry run] ${rel} → ${args.outDir}/${article.slug}.svg  (${params.lattice}, seed ${params.seed}, ${params.tone})`);
      made++; continue;
    }

    const svg = renderSVG(scene, {
      title: article.title,
      date: article.date,
      author: article.author,
      sectionLabel: DESIGN.sections[params.section]?.label,
    }, DESIGN);

    try {
      fs.mkdirSync(outAbs, { recursive: true });
      fs.writeFileSync(svgPath, svg + '\n', 'utf8');
      stampPreview(file, stamp);
      made++;
      log(`✓ ${args.outDir}/${article.slug}.svg  ${params.lattice}/${params.tone} seed ${params.seed} (${(svg.length / 1024).toFixed(1)} kB)`);
    } catch (e) {
      warn(`${rel}: ${e.message}`); failed++;
    }
  }

  log(`done: ${made} generated, ${skipped} skipped, ${failed} failed`);
  return failed ? 1 : 0;
}

process.exit(main());
