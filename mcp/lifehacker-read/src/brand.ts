// =============================================================================
// brand.ts — read the machine-readable brand (_data/brand/*.yml).
// -----------------------------------------------------------------------------
// The brand is data: identity (mission/pillars/Prime Directive), voice profiles,
// and the "banned-when-sincere" glossary. These helpers let an AI write on-voice
// and pre-check word choices. The authoritative brand LINT is tier-1
// scripts/ci/lint_brand.rb (shelled by the act plane); this is the read view.
// =============================================================================
import type { CollectionName } from "./collections.js";
import type { RepoReader } from "./repo.js";

/** The voice profile the autopilot would pick for a collection (per grow-lifehacker). */
export function voiceForCollection(collection: CollectionName): string {
  switch (collection) {
    case "hacks":
      return "how-to-practical";
    case "tools":
      return "tool-review-honest";
    case "posts":
    case "docs":
      return "meta-confession";
    default:
      return "satire-deadpan";
  }
}

export interface WordVerdict {
  word: string;
  classification: "banned-when-sincere" | "avoid-phrase" | "ok";
  note: string;
}

function lowerList(v: unknown): string[] {
  return Array.isArray(v) ? v.map((x) => String(x).toLowerCase()) : [];
}

/** Classify one word/phrase against the glossary. */
export function checkWord(reader: RepoReader, word: string): WordVerdict {
  const glossary = reader.readYaml<Record<string, unknown>>("_data/brand/glossary.yml") ?? {};
  const w = word.trim().toLowerCase();
  const banned = lowerList(glossary["banned_when_sincere"]);
  const avoid = lowerList(glossary["avoid_phrases"]);

  // banned entries can carry an inline comment after the term (e.g. "leverage").
  const bannedHit = banned.find((b) => b === w || b.split(/\s+#/)[0]!.trim() === w);
  if (bannedHit) {
    return {
      word,
      classification: "banned-when-sincere",
      note: "Banned only when used sincerely. Allowed as the punchline inside a clearly-flagged satire bit (fake-infomercial voice, scare quotes).",
    };
  }
  if (avoid.some((a) => w.includes(a) || a.includes(w))) {
    return {
      word,
      classification: "avoid-phrase",
      note: "Weasel phrase — delete or replace with a number/fact.",
    };
  }
  return { word, classification: "ok", note: "Not on the banned or avoid lists." };
}

export interface VoiceProfile {
  requested: string;
  profile: unknown;
  defaultProfile: string;
  available: string[];
}

/** Resolve a voice profile by name, or by the collection default. */
export function resolveVoiceProfile(
  reader: RepoReader,
  opts: { profile?: string; collection?: CollectionName },
): VoiceProfile {
  const voice = reader.readYaml<Record<string, unknown>>("_data/brand/voice.yml") ?? {};
  const profiles = (voice["profiles"] ?? {}) as Record<string, unknown>;
  const name = opts.profile ?? (opts.collection ? voiceForCollection(opts.collection) : String(voice["default"] ?? "satire-deadpan"));
  return {
    requested: name,
    profile: profiles[name] ?? null,
    defaultProfile: String(voice["default"] ?? "satire-deadpan"),
    available: Object.keys(profiles),
  };
}
