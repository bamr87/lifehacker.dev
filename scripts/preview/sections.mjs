#!/usr/bin/env node
// Trace Bloom — the SECTION banner generator.
//
//   node scripts/preview/sections.mjs                # regenerate all six
//   node scripts/preview/sections.mjs --section wire # just one
//   node scripts/preview/sections.mjs --check        # committed art == generated art?
//
// `_config.yml` stamps `/images/previews/section-<id>.svg` on every page that
// carries no `preview:` of its own, so these six files are the only art on the
// site that is NOT per-article — they are the fallback, and the one place the
// one-image-many-articles pathology is on purpose. They were originally hand-
// authored: section-hacks.svg was drawn by hand and the other five were forked
// from it with the palette and the label swapped, which is why all six shipped
// the identical lattice, the identical two blooms, and the identical emitter
// positions. Nothing could "regenerate" them, because nothing had generated
// them.
//
// This does. Same engine as the article banners (lib/core.mjs + lib/svg.mjs),
// same tokens (_data/preview/design.json), so a re-skin reaches the fallbacks
// too, and every section's own lattice actually shows up in its own banner.
//
// The subject of a section banner is the SECTION, so the copy comes from the
// section's real index page: its `description` feeds both the accessible <desc>
// and the decay tilt, exactly as an article's body does. Nothing is invented
// here that the site does not already say about itself.
//
// Deterministic and offline: seed = fnv1a("section-<id>"), so the same tokens
// and the same index copy always produce the same bytes.
//
// Exit codes: 0 ok · 1 a banner failed (or, under --check, drifted).

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { deriveParams, buildScene } from './lib/core.mjs';
import { renderSVG } from './lib/svg.mjs';
import { parseFrontMatter } from './lib/article.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..', '..');
const DESIGN = JSON.parse(fs.readFileSync(path.join(ROOT, '_data/preview/design.json'), 'utf8'));

const OUT_DIR = 'assets/images/previews';

// The roster IS design.json's section list — add a section there and it gets a
// fallback banner here for free. `index` is the page whose front matter says
// what the section is for; `scope` is the sentence tail that tells a screen
// reader (and the next maintainer) which pages actually wear this file.
const INDEX = {
  hacks: 'pages/news/hacks.md',
  tools: 'pages/news/tools.md',
  'field-notes': 'pages/news/field-notes.md',
  wire: 'pages/news/wire.md',
  posts: 'pages/news/index.md',
  docs: 'pages/_docs/index.md',
};
const SCOPE = {
  hacks: 'hacks posts that carry no banner of their own',
  tools: 'tool reviews that carry no banner of their own',
  'field-notes': 'field notes that carry no banner of their own',
  wire: 'wire dispatches that carry no banner of their own',
  posts: 'any post or page on the site that carries no banner of its own — the last fallback',
  docs: 'docs pages that carry no banner of their own',
};

const log = (m) => console.log(`[trace-bloom] ${m}`);
const warn = (m) => console.error(`[trace-bloom] WARN: ${m}`);

const HELP = `Trace Bloom section banners (the _config.yml fallbacks)

      --section <s>   only this one (${Object.keys(DESIGN.sections).join('|')})
      --check         fail if committed art differs from generated art
  -n, --dry-run       report what would be written
      --out-dir <d>   default ${OUT_DIR}
  -v, --verbose
`;

function parseArgs(argv) {
  const a = { section: null, check: false, dryRun: false, outDir: OUT_DIR, verbose: false };
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case '--section': a.section = argv[++i]; break;
      case '--check': a.check = true; break;
      case '-n': case '--dry-run': a.dryRun = true; break;
      case '--out-dir': a.outDir = argv[++i]; break;
      case '-v': case '--verbose': a.verbose = true; break;
      case '-h': case '--help': a.help = true; break;
      default: warn(`unknown flag ${argv[i]}`); a.bad = true;
    }
  }
  return a;
}

/** The section's own index page, as copy. Missing is fatal, never silent — a
 *  banner captioned with a guess is how generic wallpaper gets back in. */
function indexCopy(id) {
  const rel = INDEX[id];
  if (!rel) throw new Error(`no index page mapped for section "${id}" (add one to INDEX)`);
  const abs = path.join(ROOT, rel);
  if (!fs.existsSync(abs)) throw new Error(`${rel} is gone — the banner's copy lives there`);
  const { fields } = parseFrontMatter(fs.readFileSync(abs, 'utf8'));
  if (!fields.description) throw new Error(`${rel} has no description: to caption the banner with`);
  return { rel, description: String(fields.description).trim() };
}

export function renderSection(id) {
  const sec = DESIGN.sections[id];
  if (!sec) throw new Error(`unknown section "${id}" (not in design.json)`);
  const { rel, description } = indexCopy(id);
  const label = sec.label;

  // Same derivation an article gets: the seed is the filename, and the copy
  // tilts decay urgent/steady. A section that describes itself in failure words
  // gets a shorter-travelling field, which is the point of the tilt.
  const params = deriveParams({
    slug: `section-${id}`, title: label, tags: [id], section: id, body: description,
  }, DESIGN);
  const scene = buildScene(params, DESIGN);

  const desc = `Trace Bloom section banner for ${label} on lifehacker.dev. ${description} `
    + `A ${params.lattice} lattice probed by ${params.probes} emitters; interference blooms `
    + `mark where the wavefronts meet. Fallback cover for ${SCOPE[id] || `the ${id} section`}. `
    + `Seed ${params.seed}.`;

  const svg = renderSVG(scene, { title: label, sectionLabel: label, desc }, DESIGN);
  return { svg: svg + '\n', params, source: rel };
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) { process.stdout.write(HELP); return 0; }
  if (args.bad) return 1;

  let ids = Object.keys(DESIGN.sections);
  if (args.section) {
    if (!ids.includes(args.section)) { warn(`unknown section ${args.section}`); return 1; }
    ids = [args.section];
  }

  const outAbs = path.join(ROOT, args.outDir);
  let made = 0, drifted = 0, failed = 0;

  for (const id of ids) {
    let out;
    try {
      out = renderSection(id);
    } catch (e) {
      warn(`${id}: ${e.message}`); failed++; continue;
    }
    const file = path.join(outAbs, `section-${id}.svg`);
    const rel = path.relative(ROOT, file);
    const current = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : null;

    if (args.check) {
      if (current === out.svg) {
        if (args.verbose) log(`= ${rel}`);
      } else {
        warn(`${rel} differs from the generator${current === null ? ' (missing)' : ''} — run: node scripts/preview/sections.mjs`);
        drifted++;
      }
      continue;
    }
    if (args.dryRun) {
      log(`[dry run] ${rel}  (${out.params.lattice}, seed ${out.params.seed}, ${out.params.tone}, copy from ${out.source})`);
      made++; continue;
    }
    try {
      fs.mkdirSync(outAbs, { recursive: true });
      fs.writeFileSync(file, out.svg, 'utf8');
      made++;
      log(`✓ ${rel}  ${out.params.lattice}/${out.params.tone} seed ${out.params.seed} (${(out.svg.length / 1024).toFixed(1)} kB)`);
    } catch (e) {
      warn(`${rel}: ${e.message}`); failed++;
    }
  }

  if (args.check) {
    log(`check: ${ids.length - drifted - failed}/${ids.length} banners current`);
    return drifted || failed ? 1 : 0;
  }
  log(`done: ${made} written, ${failed} failed`);
  return failed ? 1 : 0;
}

process.exit(main());
