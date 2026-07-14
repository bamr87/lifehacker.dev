// =============================================================================
// concepts.ts — the durable concept layer, read-side.
// -----------------------------------------------------------------------------
// Content rots; context evaporates; the concept is the layer worth keeping.
// _data/concepts.yml is the home that layer never had — the site's portable
// ideas, each pinned to the content that carries it. This module loads and
// searches it so a fresh session can pull "what this site has learned" in
// seconds instead of re-deriving it from 200+ posts. Read-only.
//   idea: /posts/2026/07/13/concepts-context-content-i-hoard-the-one-that-rots/
// =============================================================================
import type { RepoReader } from "./repo.js";

export interface ConceptSource {
  title: string;
  url: string;
}

export interface Concept {
  id: string;
  concept: string; // the one durable sentence
  gloss: string;
  tags: string[];
  captured: string | null;
  sources: ConceptSource[];
  external: Array<{ note: string; url: string }>;
}

function str(v: unknown): string {
  return v == null ? "" : String(v);
}

function asSources(v: unknown): ConceptSource[] {
  if (!Array.isArray(v)) return [];
  return v.map((s) => {
    const o = (s ?? {}) as Record<string, unknown>;
    return { title: str(o["title"]), url: str(o["url"]) };
  });
}

function normalize(raw: Record<string, unknown>): Concept {
  return {
    id: str(raw["id"]),
    concept: str(raw["concept"]),
    gloss: str(raw["gloss"]),
    tags: Array.isArray(raw["tags"]) ? raw["tags"].map(String) : [],
    captured: raw["captured"] != null ? str(raw["captured"]) : null,
    sources: asSources(raw["sources"]),
    external: Array.isArray(raw["external"])
      ? (raw["external"] as Array<Record<string, unknown>>).map((e) => ({ note: str(e["note"]), url: str(e["url"]) }))
      : [],
  };
}

/** Load the whole concept ledger (empty array if the file is absent). */
export function loadConcepts(reader: RepoReader): Concept[] {
  if (!reader.exists("_data/concepts.yml")) return [];
  const data = reader.readYaml<{ concepts?: Array<Record<string, unknown>> }>("_data/concepts.yml") ?? {};
  return (data.concepts ?? []).map(normalize);
}

/** Concepts filtered by tag (or all). */
export function listConcepts(reader: RepoReader, tag?: string): Concept[] {
  const all = loadConcepts(reader);
  if (!tag) return all;
  const t = tag.toLowerCase();
  return all.filter((c) => c.tags.map((x) => x.toLowerCase()).includes(t));
}

/** One concept by id, or null. */
export function getConcept(reader: RepoReader, id: string): Concept | null {
  return loadConcepts(reader).find((c) => c.id.toLowerCase() === id.toLowerCase()) ?? null;
}

export interface ConceptHit extends Concept {
  score: number;
}

/**
 * Rank concepts by a query over the sentence (5), gloss (3), tags (2). The query
 * is tokenized and scored per-word, so a conceptual query like "knowledge that
 * outlives its content" matches concepts containing any of its salient words —
 * not only an exact substring.
 */
export function findConcepts(reader: RepoReader, query: string, limit = 10): ConceptHit[] {
  const terms = query.toLowerCase().split(/[^a-z0-9]+/).filter((t) => t.length > 2);
  const hits: ConceptHit[] = [];
  for (const c of loadConcepts(reader)) {
    let score = 0;
    if (terms.length) {
      const concept = c.concept.toLowerCase();
      const gloss = c.gloss.toLowerCase();
      const tags = c.tags.map((t) => t.toLowerCase());
      for (const t of terms) {
        if (concept.includes(t)) score += 5;
        if (gloss.includes(t)) score += 3;
        if (tags.some((tag) => tag.includes(t))) score += 2;
      }
    } else {
      score = 1;
    }
    if (score > 0) hits.push({ ...c, score });
  }
  hits.sort((a, b) => b.score - a.score || a.id.localeCompare(b.id));
  return hits.slice(0, limit);
}
