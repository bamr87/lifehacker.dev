// Trace Bloom — article I/O.
//
// Reads just enough front matter to seed the art, and stamps `preview:` back.
// Deliberately NOT a general YAML parser: this repo's front matter is scalars,
// inline arrays, and block lists, and a hand-rolled reader keeps the whole
// pipeline dependency-free (see docs/PREVIEW-IMAGES.md "no gem, no API key").

import fs from 'node:fs';
import path from 'node:path';

/** Matches the legacy engine's generate_filename() so regenerating an existing
 *  article keeps its existing banner path — no dangling references, no churn. */
export function slugify(title) {
  return String(title)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 50);
}

const FM_RE = /^---\s*\r?\n([\s\S]*?)\r?\n---\s*\r?\n?/;

export function parseFrontMatter(text) {
  const m = text.match(FM_RE);
  if (!m) return { fields: {}, raw: '', body: text, end: 0 };
  const fields = {};
  const lines = m[1].split(/\r?\n/);
  let listKey = null;
  for (const line of lines) {
    const item = line.match(/^\s*-\s+(.*)$/);
    if (item && listKey) { fields[listKey].push(unquote(item[1])); continue; }
    const kv = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (!kv) continue;
    const [, key, rawVal] = kv;
    const val = rawVal.trim();
    if (val === '') { listKey = key; fields[key] = []; continue; }
    listKey = null;
    if (val.startsWith('[')) {
      fields[key] = val.replace(/^\[|\]$/g, '').split(',')
        .map((s) => unquote(s.trim())).filter(Boolean);
    } else {
      fields[key] = unquote(val);
    }
  }
  return { fields, raw: m[1], body: text.slice(m[0].length), end: m[0].length };
}

const unquote = (s) => s.replace(/^['"]|['"]$/g, '').trim();

/** Body text with front matter, code fences, and markup stripped — the corpus
 *  the decay tilt is measured against. */
export function plainBody(text) {
  return text.replace(FM_RE, '')
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/`[^`]*`/g, ' ')
    .replace(/!?\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/[#>*_|-]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Section from the file's own location — the collection can't tell us, because
 *  issue #337 folded hacks/tools/field-notes into one `posts` collection. */
export function sectionFor(file) {
  const p = file.replace(/\\/g, '/');
  const m = p.match(/_posts\/([^/]+)\//);
  if (m) return m[1];
  if (p.includes('/_docs/')) return 'docs';
  return 'field-notes';
}

export function readArticle(file) {
  const text = fs.readFileSync(file, 'utf8');
  const { fields } = parseFrontMatter(text);
  const title = fields.title || path.basename(file, path.extname(file)).replace(/^\d{4}-\d{2}-\d{2}-/, '').replace(/-/g, ' ');
  const tags = [].concat(fields.tags || [], fields.categories || []);
  return {
    file, text, fields, title, tags,
    slug: slugify(title),
    section: sectionFor(file),
    date: (fields.date || '').slice(0, 10),
    author: fields.author || '',
    body: plainBody(text),
    hasFrontMatter: FM_RE.test(text),
  };
}

/** Write `preview:` into the front matter, replacing any existing value.
 *  Returns true when the file changed. */
export function stampPreview(file, value, key = 'preview') {
  const text = fs.readFileSync(file, 'utf8');
  const m = text.match(FM_RE);
  if (!m) return false;
  const block = m[1];
  const line = `${key}: ${value}`;
  let next;
  const existing = new RegExp(`^${key}:.*$`, 'm');
  // EVERY replacement below is a FUNCTION, never a string. A string replacement
  // expands `$1`, `$&`, `$'` and `` $` `` — and front matter is prose, so a
  // description reading "the $1 capture syntax" would splice the whole matched
  // block back into itself. That is not hypothetical: it corrupted
  // pages/_posts/tools/2026-07-02-sd-honest-review.md the first time this ran.
  if (existing.test(block)) {
    if (block.match(existing)[0] === line) return false;      // already correct
    next = block.replace(existing, () => line);
  } else {
    // Place it after `date:` when present so front matter keeps a stable shape.
    next = /^date:.*$/m.test(block)
      ? block.replace(/^date:.*$/m, (d) => `${d}\n${line}`)
      : `${block}\n${line}`;
  }
  fs.writeFileSync(file, text.replace(FM_RE, () => `---\n${next}\n---\n`), 'utf8');
  return true;
}

/** Recursively collect markdown under a directory. */
export function findMarkdown(dir) {
  const out = [];
  const walk = (d) => {
    for (const entry of fs.readdirSync(d, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
      const full = path.join(d, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (/\.(md|markdown)$/.test(entry.name)) out.push(full);
    }
  };
  if (fs.existsSync(dir)) walk(dir);
  return out;
}
