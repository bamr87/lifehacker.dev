// =============================================================================
// frontmatter.ts — split a Jekyll page into front matter + body.
// -----------------------------------------------------------------------------
// Mirrors the semantics of scripts/ci/_lib.rb LH.parse: a leading `---` fenced
// YAML block, then the Markdown body. Kept deliberately small; the canonical
// schema enforcement still lives in scripts/ci/lint_frontmatter.rb (which the
// act-plane's validate_frontmatter tool shells).
// =============================================================================
import { parse as parseYaml } from "yaml";

export interface ParsedPage {
  frontMatter: Record<string, unknown>;
  body: string;
}

const FENCE = /^---\s*$/;

export function parsePage(raw: string): ParsedPage {
  const text = raw.replace(/^﻿/, ""); // strip BOM
  const lines = text.split("\n");

  if (lines.length === 0 || !FENCE.test(lines[0]!.trim())) {
    return { frontMatter: {}, body: text };
  }

  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (FENCE.test(lines[i]!.trim())) {
      end = i;
      break;
    }
  }
  if (end === -1) {
    // Opening fence with no closing fence — treat the whole thing as body.
    return { frontMatter: {}, body: text };
  }

  const yamlBlock = lines.slice(1, end).join("\n");
  const body = lines.slice(end + 1).join("\n");
  let frontMatter: Record<string, unknown> = {};
  try {
    const parsed = parseYaml(yamlBlock);
    if (parsed && typeof parsed === "object") frontMatter = parsed as Record<string, unknown>;
  } catch {
    // Malformed front matter → empty map (the CI linter is the source of truth
    // on validity; this reader stays lenient so it never crashes on a draft).
    frontMatter = {};
  }
  return { frontMatter, body };
}

/** Coerce a front-matter tags value (array or comma string) to string[]. */
export function asTags(value: unknown): string[] {
  if (Array.isArray(value)) return value.map(String);
  if (typeof value === "string") return value.split(",").map((t) => t.trim()).filter(Boolean);
  return [];
}
