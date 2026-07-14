// =============================================================================
// engine.ts — the concept engine.
// -----------------------------------------------------------------------------
// The concept layer (concepts.ts) is the store. This is the engine that connects
// it to the rest of the site — tags, collections, categories, keywords — and
// turns "what has this site learned" into a lever for growth:
//
//   relate_concept       concept  -> the content/tags/concepts around it
//   concepts_for         content/tag/text -> the concepts it carries
//   concept_coverage     where concepts are thin or missing (the gap map)
//   suggest_concept_growth  ranked next moves that strengthen the durable layer
//   concept_graph        the concept <-> tag <-> concept wiki graph
//
// All read-only + deterministic. The scoring is a small, explainable heuristic
// (shared tags weigh more than loose keyword hits), not a black box.
// =============================================================================
import {
  COLLECTION_NAMES,
  listCollection,
  listTaxonomy,
  loadItem,
  type CollectionName,
  type ContentItem,
} from "./collections.js";
import { getConcept, loadConcepts, type Concept, type ConceptSource } from "./concepts.js";
import type { RepoReader } from "./repo.js";

const STOPWORDS = new Set(
  "the a an of to in on and or but is are be it its that this you your with for from as at by not into onto only every some most into than then so how what when where which who whom whose why now here there also still both each only own same such very".split(
    /\s+/,
  ),
);

const lc = (s: string) => s.toLowerCase();
const uniq = <T>(a: T[]) => [...new Set(a)];

function tokenize(s: string): string[] {
  return uniq(s.toLowerCase().split(/[^a-z0-9]+/).filter((t) => t.length > 3 && !STOPWORDS.has(t)));
}

/** The matching terms for a concept: explicit keywords (or salient words) + tags. */
export function conceptTerms(c: Concept): string[] {
  const base = c.keywords.length ? c.keywords.map(lc) : tokenize(`${c.concept} ${c.gloss}`);
  return uniq([...base, ...c.tags.map(lc)]);
}

/** Load every content item once (the engine relates against the whole corpus). */
export function loadAllContent(reader: RepoReader): ContentItem[] {
  return COLLECTION_NAMES.flatMap((c) => listCollection(reader, c));
}

export interface ContentMatch {
  collection: CollectionName;
  slug: string;
  title: string;
  url: string;
  score: number;
  sharedTags: string[];
}

/** Score one content item against a concept: shared tags x3, keyword hits x1. */
function scoreItem(terms: string[], cTags: Set<string>, item: ContentItem): ContentMatch | null {
  const sharedTags = item.tags.map(lc).filter((t) => cTags.has(t));
  const hay = `${item.title} ${item.tags.join(" ")} ${item.excerpt} ${item.description}`.toLowerCase();
  const kwHits = terms.filter((k) => hay.includes(k)).length;
  const score = sharedTags.length * 3 + kwHits;
  if (score < 3) return null;
  return { collection: item.collection, slug: item.slug, title: item.title, url: item.url, score, sharedTags };
}

export interface ConceptRelations {
  concept: Concept;
  curated: ConceptSource[];
  derived: ContentMatch[];
  relatedTags: Array<{ tag: string; count: number }>;
  relatedConcepts: Array<{ id: string; concept: string; shared: string[]; explicit: boolean }>;
}

/** Expand a concept into its neighborhood: carrier content, tags, sibling concepts. */
export function relateConcept(reader: RepoReader, id: string, content?: ContentItem[]): ConceptRelations | null {
  const concept = getConcept(reader, id);
  if (!concept) return null;
  const terms = conceptTerms(concept);
  const cTags = new Set(concept.tags.map(lc));
  const curatedUrls = new Set(concept.sources.map((s) => s.url));
  const items = content ?? loadAllContent(reader);

  const derived: ContentMatch[] = [];
  const tagFreq = new Map<string, number>();
  for (const item of items) {
    for (const t of item.tags.map(lc)) if (cTags.has(t) && curatedUrls.has(item.url)) tagFreq.set(t, (tagFreq.get(t) ?? 0) + 1);
    if (curatedUrls.has(item.url)) continue;
    const m = scoreItem(terms, cTags, item);
    if (m) {
      derived.push(m);
      for (const t of m.sharedTags) tagFreq.set(t, (tagFreq.get(t) ?? 0) + 1);
    }
  }
  derived.sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));

  const relatedTags = uniq([...concept.tags.map(lc), ...tagFreq.keys()])
    .map((tag) => ({ tag, count: tagFreq.get(tag) ?? 0 }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 12);

  const relatedConcepts = loadConcepts(reader)
    .filter((o) => o.id !== concept.id)
    .map((o) => {
      const explicit = concept.related.includes(o.id) || o.related.includes(concept.id);
      const shared = uniq([...o.tags.map(lc), ...conceptTerms(o)]).filter((t) => terms.includes(t) || cTags.has(t));
      return { id: o.id, concept: o.concept, shared, explicit };
    })
    .filter((r) => r.explicit || r.shared.length > 0)
    .sort((a, b) => Number(b.explicit) - Number(a.explicit) || b.shared.length - a.shared.length)
    .slice(0, 8);

  return { concept, curated: concept.sources, derived: derived.slice(0, 12), relatedTags, relatedConcepts };
}

export interface ConceptForHit {
  id: string;
  concept: string;
  score: number;
  via: string[];
}

/** Reverse lookup: which concepts does a piece of content / a tag / some text carry? */
export function conceptsFor(reader: RepoReader, input: { slug?: string; tag?: string; text?: string }): ConceptForHit[] {
  const tags = new Set<string>();
  const terms = new Set<string>();

  if (input.tag) {
    tags.add(lc(input.tag));
    terms.add(lc(input.tag));
  }
  if (input.text) for (const t of tokenize(input.text)) terms.add(t);
  if (input.slug) {
    for (const coll of COLLECTION_NAMES) {
      const item = loadItem(reader, coll, input.slug);
      if (item) {
        for (const t of item.tags.map(lc)) tags.add(t);
        for (const t of tokenize(`${item.title} ${item.excerpt} ${item.description}`)) terms.add(t);
        break;
      }
    }
  }

  const hits: ConceptForHit[] = [];
  for (const c of loadConcepts(reader)) {
    const via: string[] = [];
    let score = 0;
    for (const t of c.tags.map(lc)) if (tags.has(t)) { score += 4; via.push(`tag:${t}`); }
    for (const k of conceptTerms(c)) if (terms.has(k)) { score += 2; via.push(k); }
    if (input.text) {
      const hay = `${c.concept} ${c.gloss}`.toLowerCase();
      for (const t of terms) if (hay.includes(t)) { score += 1; via.push(t); }
    }
    if (score > 0) hits.push({ id: c.id, concept: c.concept, score, via: uniq(via) });
  }
  hits.sort((a, b) => b.score - a.score || a.id.localeCompare(b.id));
  return hits;
}

export interface CoverageReport {
  totalConcepts: number;
  totalContent: number;
  perConcept: Array<{ id: string; concept: string; curated: number; derived: number; carriers: number }>;
  weakConcepts: Array<{ id: string; concept: string; curated: number; derived: number }>;
  uncoveredTags: Array<{ tag: string; count: number }>;
  captureCandidates: Array<{ concept: string; collection: string; slug: string; title: string; url: string; score: number }>;
}

const TAG_COVERAGE_FLOOR = 6; // a tag with >= this many items and no concept is a growth signal

/** The gap map: where the durable layer is thin, and which tags have no concept. */
export function conceptCoverage(reader: RepoReader): CoverageReport {
  const concepts = loadConcepts(reader);
  const content = loadAllContent(reader);

  // What terms/tags do the concepts, together, cover?
  const covered = new Set<string>();
  for (const c of concepts) for (const t of [...c.tags.map(lc), ...conceptTerms(c)]) covered.add(t);

  const perConcept: CoverageReport["perConcept"] = [];
  const captureCandidates: CoverageReport["captureCandidates"] = [];
  const weakConcepts: CoverageReport["weakConcepts"] = [];

  for (const c of concepts) {
    const rel = relateConcept(reader, c.id, content)!;
    const curated = rel.curated.length;
    const derived = rel.derived.length;
    perConcept.push({ id: c.id, concept: c.concept, curated, derived, carriers: curated + derived });
    if (curated <= 1 && derived < 3) weakConcepts.push({ id: c.id, concept: c.concept, curated, derived });
    for (const d of rel.derived.slice(0, 2)) {
      captureCandidates.push({ concept: c.id, collection: d.collection, slug: d.slug, title: d.title, url: d.url, score: d.score });
    }
  }

  const uncoveredTags = listTaxonomy(reader, "tags")
    .filter((t) => t.count >= TAG_COVERAGE_FLOOR && !covered.has(lc(t.name)))
    .map((t) => ({ tag: t.name, count: t.count }))
    .slice(0, 15);

  captureCandidates.sort((a, b) => b.score - a.score);

  return {
    totalConcepts: concepts.length,
    totalContent: content.length,
    perConcept: perConcept.sort((a, b) => a.carriers - b.carriers),
    weakConcepts,
    uncoveredTags,
    captureCandidates: captureCandidates.slice(0, 8),
  };
}

export interface Suggestion {
  kind: "capture" | "reinforce" | "pin";
  score: number;
  action: string;
  detail: string;
}

/** Turn the coverage map into ranked next moves that strengthen the concept layer. */
export function suggestConceptGrowth(reader: RepoReader, limit = 10): Suggestion[] {
  const cov = conceptCoverage(reader);
  const out: Suggestion[] = [];

  for (const t of cov.uncoveredTags) {
    out.push({
      kind: "capture",
      score: t.count,
      action: `Capture a concept for the "${t.tag}" cluster`,
      detail: `${t.count} pieces of content are tagged "${t.tag}", but no concept covers it — a durable lesson is probably hiding there.`,
    });
  }
  for (const w of cov.weakConcepts) {
    out.push({
      kind: "reinforce",
      score: 7 - w.curated - w.derived,
      action: `Reinforce ${w.id}`,
      detail: `"${w.concept}" rests on ${w.curated} pinned + ${w.derived} related carriers — thin enough that losing one page could lose the idea.`,
    });
  }
  for (const c of cov.captureCandidates.slice(0, 5)) {
    out.push({
      kind: "pin",
      score: Math.min(c.score, 6),
      action: `Pin ${c.collection}/${c.slug} to ${c.concept}`,
      detail: `"${c.title}" strongly matches ${c.concept} (score ${c.score}) but isn't listed as one of its sources.`,
    });
  }

  return out.sort((a, b) => b.score - a.score).slice(0, limit);
}

export interface ConceptGraph {
  nodes: Array<{ id: string; type: "concept" | "tag"; label: string }>;
  edges: Array<{ from: string; to: string; rel: "tagged" | "related" }>;
}

/** The concept <-> tag <-> concept graph (the wiki view of the layer). */
export function conceptGraph(reader: RepoReader): ConceptGraph {
  const concepts = loadConcepts(reader);
  const tags = uniq(concepts.flatMap((c) => c.tags.map(lc)));
  const nodes: ConceptGraph["nodes"] = [
    ...concepts.map((c) => ({ id: c.id, type: "concept" as const, label: c.concept })),
    ...tags.map((t) => ({ id: `tag:${t}`, type: "tag" as const, label: t })),
  ];
  const edges: ConceptGraph["edges"] = [];
  for (const c of concepts) {
    for (const t of c.tags.map(lc)) edges.push({ from: c.id, to: `tag:${t}`, rel: "tagged" });
    for (const r of c.related) edges.push({ from: c.id, to: r, rel: "related" });
  }
  return { nodes, edges };
}
