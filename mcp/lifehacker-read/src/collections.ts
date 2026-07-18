// =============================================================================
// collections.ts — the content model, read-side.
// -----------------------------------------------------------------------------
// The site's content, organized as five logical SECTIONS. Three of them are
// section subdirectories of Jekyll's `posts` collection (hacks, tools,
// field-notes live under pages/_posts/<section>/), and two are standalone page
// collections (docs, about). This module loads, lists, and searches them the way
// index.md / tags.md do in Liquid, and computes each item's public permalink.
// The public URLs are PRESERVED across the reorg — a hack is still /hacks/<slug>/,
// a field note is still /posts/<YYYY>/<MM>/<DD>/<slug>/. The canonical
// front-matter SCHEMA is enforced by scripts/ci/lint_frontmatter.rb — this module
// only reads.
// =============================================================================
import { asTags, parsePage } from "./frontmatter.js";
import type { RepoReader } from "./repo.js";

export type CollectionName = "hacks" | "tools" | "field-notes" | "docs" | "about";

const POST_FILE = /^(\d{4})-(\d{2})-(\d{2})-(.+)\.md$/;

interface CollectionDef {
  /** The repo-relative directory the section's *.md files live in. */
  dir: string;
  /** Filenames carry a `<YYYY-MM-DD>-` date prefix that the slug strips. */
  dated: boolean;
  /** The computed public permalink (front-matter `permalink` still wins). */
  urlFor: (slug: string, filename: string) => string;
}

export const COLLECTIONS: Record<CollectionName, CollectionDef> = {
  hacks: { dir: "pages/_posts/hacks", dated: true, urlFor: (slug) => `/hacks/${slug}/` },
  tools: { dir: "pages/_posts/tools", dated: true, urlFor: (slug) => `/tools/${slug}/` },
  "field-notes": {
    dir: "pages/_posts/field-notes",
    dated: true,
    urlFor: (slug, filename) => {
      const m = POST_FILE.exec(filename);
      return m ? `/posts/${m[1]}/${m[2]}/${m[3]}/${slug}/` : `/posts/${slug}/`;
    },
  },
  docs: { dir: "pages/_docs", dated: false, urlFor: (slug) => `/docs/${slug}/` },
  about: { dir: "pages/_about", dated: false, urlFor: (slug) => `/about/${slug}/` },
};

export const COLLECTION_NAMES = Object.keys(COLLECTIONS) as CollectionName[];

export interface ContentItem {
  collection: CollectionName;
  slug: string;
  path: string; // repo-relative
  title: string;
  description: string;
  excerpt: string;
  date: string | null;
  author: string | null;
  tags: string[];
  categories: string[];
  verdict: string | null; // tools only
  url: string;
  body: string;
}

/** The slug for a filename in a section (dated sections strip the leading date). */
function slugFor(collection: CollectionName, filename: string): string {
  if (COLLECTIONS[collection].dated) {
    const m = POST_FILE.exec(filename);
    if (m) return m[4]!;
  }
  return filename.replace(/\.md$/, "");
}

/** The public permalink for an item (front-matter `permalink` wins). */
function urlFor(
  collection: CollectionName,
  filename: string,
  slug: string,
  fm: Record<string, unknown>,
): string {
  const explicit = fm["permalink"];
  if (typeof explicit === "string" && explicit.length > 0) return explicit;
  return COLLECTIONS[collection].urlFor(slug, filename);
}

function str(v: unknown): string {
  if (v == null) return "";
  return String(v);
}

function toItem(
  collection: CollectionName,
  filename: string,
  relPath: string,
  raw: string,
): ContentItem {
  const { frontMatter: fm, body } = parsePage(raw);
  const slug = slugFor(collection, filename);
  return {
    collection,
    slug,
    path: relPath,
    title: str(fm["title"]),
    description: str(fm["description"]),
    excerpt: str(fm["excerpt"]),
    date: fm["date"] != null ? str(fm["date"]) : null,
    author: fm["author"] != null ? str(fm["author"]) : null,
    tags: asTags(fm["tags"]),
    categories: asTags(fm["categories"]),
    verdict: fm["verdict"] != null ? str(fm["verdict"]) : null,
    url: urlFor(collection, filename, slug, fm),
    body,
  };
}

/** Every item in a collection, newest first. */
export function listCollection(reader: RepoReader, collection: CollectionName): ContentItem[] {
  const { dir } = COLLECTIONS[collection];
  const items = reader
    .listDir(dir)
    .filter((f) => f.endsWith(".md"))
    .map((f) => toItem(collection, f, `${dir}/${f}`, reader.readText(`${dir}/${f}`)));
  return items.sort((a, b) => (b.date ?? "").localeCompare(a.date ?? ""));
}

/** Load one item by collection + slug, or null if absent. */
export function loadItem(
  reader: RepoReader,
  collection: CollectionName,
  slug: string,
): ContentItem | null {
  const { dir } = COLLECTIONS[collection];
  for (const f of reader.listDir(dir)) {
    if (!f.endsWith(".md")) continue;
    if (slugFor(collection, f) === slug) {
      return toItem(collection, f, `${dir}/${f}`, reader.readText(`${dir}/${f}`));
    }
  }
  return null;
}

export interface SearchHit {
  collection: CollectionName;
  slug: string;
  title: string;
  description: string;
  url: string;
  tags: string[];
  score: number;
}

export interface SearchOpts {
  query: string;
  collection?: CollectionName;
  tag?: string;
  limit?: number;
}

/** Full-text / metadata search across collections (title/desc/excerpt/tags/body). */
export function searchContent(reader: RepoReader, opts: SearchOpts): SearchHit[] {
  const q = opts.query.trim().toLowerCase();
  const targets = opts.collection ? [opts.collection] : COLLECTION_NAMES;
  const hits: SearchHit[] = [];

  for (const collection of targets) {
    for (const item of listCollection(reader, collection)) {
      if (opts.tag && !item.tags.map((t) => t.toLowerCase()).includes(opts.tag.toLowerCase())) {
        continue;
      }
      // Weighted match: title 5, tags 4, description 2, excerpt 2, body 1.
      let score = 0;
      if (q) {
        if (item.title.toLowerCase().includes(q)) score += 5;
        if (item.tags.some((t) => t.toLowerCase().includes(q))) score += 4;
        if (item.description.toLowerCase().includes(q)) score += 2;
        if (item.excerpt.toLowerCase().includes(q)) score += 2;
        if (item.body.toLowerCase().includes(q)) score += 1;
      } else {
        score = 1; // empty query + tag filter → list everything matching the tag
      }
      if (score > 0) {
        hits.push({
          collection,
          slug: item.slug,
          title: item.title,
          description: item.description,
          url: item.url,
          tags: item.tags,
          score,
        });
      }
    }
  }

  hits.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));
  return hits.slice(0, opts.limit ?? 20);
}

export interface TaxonomyEntry {
  name: string;
  count: number;
  items: { collection: CollectionName; slug: string; url: string }[];
}

/** Pooled tags (all sections) or categories (the section label carried in front matter). */
export function listTaxonomy(reader: RepoReader, kind: "tags" | "categories"): TaxonomyEntry[] {
  const pool = new Map<string, TaxonomyEntry>();
  for (const collection of COLLECTION_NAMES) {
    for (const item of listCollection(reader, collection)) {
      const values = kind === "tags" ? item.tags : item.categories;
      for (const v of values) {
        const key = v.trim();
        if (!key) continue;
        let entry = pool.get(key);
        if (!entry) {
          entry = { name: key, count: 0, items: [] };
          pool.set(key, entry);
        }
        entry.count += 1;
        entry.items.push({ collection, slug: item.slug, url: item.url });
      }
    }
  }
  return [...pool.values()].sort((a, b) => b.count - a.count || a.name.localeCompare(b.name));
}
