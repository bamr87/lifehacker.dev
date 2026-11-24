#!/usr/bin/env node
// Vault → Jekyll collection for zer0-mistakes publishing.
// Resolves [[wikilinks]] to permalinks *labelled with the target's title*,
// de-duplicates the H1 the layout already renders, and derives the frontmatter
// the theme and search engines expect. Writes vault/* into _entries/.
import { readdirSync, readFileSync, writeFileSync, mkdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { createRequire } from "node:module";
import { root, slugify } from "./lib.mjs";

const yaml = createRequire(import.meta.url)("js-yaml");
const config = yaml.load(readFileSync(root("_config.yml"), "utf8"));
const base = (config.baseurl ?? "").replace(/\/$/, "");

const OUT = root("_entries");
mkdirSync(OUT, { recursive: true });

// ---------- pass 1: read every note, parse frontmatter, build the title index ----------
const notes = [];
const skip = new Set(["templates"]);
for (const dir of readdirSync(root("vault"))) {
  const full = root("vault", dir);
  if (!statSync(full).isDirectory()) {
    if (dir.endsWith(".md")) notes.push({ dir: "", file: dir });
    continue;
  }
  if (skip.has(dir) || dir.startsWith(".")) continue;
  for (const f of readdirSync(full).filter((f) => f.endsWith(".md"))) notes.push({ dir, file: f });
}

// Frontmatter that does not parse is an error, not an empty mapping: dropped
// silently, the note publishes with its slug for a title and no date, which
// Jekyll then fills with the build's — so it ships as planted on every build day.
const unreadable = [];
const splitFrontmatter = (src, file) => {
  const m = src.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!m) return { data: {}, body: src };
  try {
    return { data: yaml.load(m[1]) ?? {}, body: m[2] };
  } catch (error) {
    // js-yaml counts lines from 0 inside the block; the file has the opening `---` above it.
    unreadable.push({ file, reason: error.reason ?? error.message, line: error.mark ? error.mark.line + 2 : "?" });
    return { data: {}, body: m[2] };
  }
};

const bySlug = new Map();   // slug -> note
const index = new Map();    // lowercased title OR slug -> slug
for (const n of notes) {
  const src = readFileSync(root("vault", n.dir, n.file), "utf8");
  const { data, body } = splitFrontmatter(src, join("vault", n.dir, n.file));
  n.slug = n.file.replace(/\.md$/, "");
  n.data = data;
  n.body = body;
  n.title = String(data.title ?? n.slug);
  index.set(n.title.toLowerCase(), n.slug);
  index.set(n.slug.toLowerCase(), n.slug);
  bySlug.set(n.slug, n);
}

if (unreadable.length) {
  console.error(`✗ ${unreadable.length} note(s) whose frontmatter is not YAML — nothing transplanted:`);
  for (const u of unreadable) console.error(`   ${u.file}:${u.line}: ${u.reason}`);
  console.error("   Quote a value that contains `: ` or starts with a YAML indicator.");
  process.exit(1);
}

// ---------- helpers ----------
// The vault's Home note is its index — the Obsidian entry point. It is *not*
// the site's landing page; index.md owns `/`. Home publishes as an entry so
// both audiences get the front door they expect.
const isHome = (n) => n.slug === "Home";
const hrefFor = (slug) => `${base}/entries/${slug.toLowerCase()}/`;

// Folder names are legitimate link targets in Obsidian ([[mirrors]]) but have no
// note of their own; they resolve to their section of the browse page.
const folders = new Set(
  notes.map((n) => n.dir).filter(Boolean).map((d) => d.toLowerCase())
);

const dead = [];

// A bare [[target]] used to render as its raw slug ("the-kodak-moment"). Label it
// with the target's real title instead; explicit [[target|label]] always wins.
const link = (target, label, from) => {
  const key = target.trim().toLowerCase();

  if (folders.has(key)) return `[${label ?? target}](${base}/entries/#${key})`;

  const slug = index.get(key);
  if (!slug) {
    // Never ship a 404. Degrade to plain text and report it — a broken wikilink
    // is a promise the vault must keep or delete, and silence lets it ship.
    dead.push({ target, from });
    return label ?? target;
  }
  return `[${label ?? bySlug.get(slug)?.title ?? target}](${hrefFor(slug)})`;
};

const oneLine = (s) => String(s ?? "").replace(/\s+/g, " ").trim();
const clip = (s, n = 155) => (s.length <= n ? s : s.slice(0, s.lastIndexOf(" ", n)).trim() + "…");

// Reduce Markdown to plain prose for the description: drop callouts, quotes and
// headings, unwrap [text](url) to text, then strip emphasis markers only —
// never a bare hyphen, which lives inside slugs and prose alike. Stops at the
// first paragraph, so a description never runs the opening line into the link
// list that follows it.
const firstParagraph = (md) => {
  const cleaned = md
    .replace(/```[\s\S]*?```/g, "")
    .replace(/^\s*>.*$/gm, "")
    .replace(/^\s*#{1,6}\s.*$/gm, "");
  for (const chunk of cleaned.split(/\n\s*\n/)) {
    const text = oneLine(
      chunk.replace(/\[([^\]]+)\]\([^)]*\)/g, "$1").replace(/[*_`]/g, "")
    );
    // Skip list-ish or link-dump chunks; we want a sentence.
    if (text.length > 25 && !/^[-·*|]/.test(text)) return text;
  }
  return "";
};

// ---------- pass 2: rewrite and emit ----------
let count = 0;
for (const n of notes) {
  let body = n.body
    .replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, (_, t, l) => link(t, l, n.slug))
    .replace(/\[\[([^\]]+)\]\]/g, (_, t) => link(t, null, n.slug));

  // The layout already prints the title as the page H1 — drop the body's leading
  // H1 so entries don't render the same heading twice.
  body = body.replace(/^\s*#\s+.+?\r?\n+/, "");

  const fm = { ...n.data };
  fm.title = isHome(n) ? "The Vault Index" : n.title;
  fm.layout = fm.layout ?? "default";
  // `slug` lets pages address a specific entry (the landing page's featured list).
  fm.slug = n.slug.toLowerCase();

  // Section drives the browse page's grouping.
  fm.section = n.dir || "root";

  // Search engines and the theme's cards both want a description; the
  // expectation is the best one-line summary an irony already contains, and
  // the conclusion is a paradox's.
  if (!fm.description) {
    const summary = oneLine(fm.expectation) || oneLine(fm.conclusion) || firstParagraph(body);
    if (summary) fm.description = clip(summary);
  }

  // `planted` is the vault's word for a publication date.
  if (!fm.date && fm.planted) fm.date = fm.planted;

  // The theme's hero reads `preview`; without it the banner renders as a grey
  // slab. preview.mjs renders one deterministic plate per slug.
  if (!fm.preview) fm.preview = `/assets/images/previews/${n.slug.toLowerCase()}.svg`;

  const out = `---\n${yaml.dump(fm, { lineWidth: 100, noRefs: true }).trimEnd()}\n---\n\n${body.trimStart()}`;
  writeFileSync(join(OUT, `${n.slug}.md`), out, "utf8");
  count++;
}
console.log(`Transplanted ${count} notes → _entries/`);

if (dead.length) {
  console.error(`\n⚠️  ${dead.length} unresolved wikilink(s) — rendered as plain text, not links:`);
  for (const d of dead) console.error(`   [[${d.target}]] in ${d.from}`);
  console.error("   Keep the promise (add the note) or delete the link.");
}
