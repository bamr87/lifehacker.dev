#!/usr/bin/env node
// Standalone gate for PR checks: scores changed vault entries against the
// rubric of their genus — ironies at the Alanis Gate, paradoxes (type: paradox)
// at the Epimenides Gate. Notes with no schema fields to score (forms, ledgers,
// framework documents) are reported UNGATED rather than misjudged.
// Usage: node engine/scripts/gate.mjs file1.md file2.md ...
import { readFileSync } from "node:fs";
import { genusOf, prompt, harness, parseJSON } from "./lib.mjs";

const files = process.argv.slice(2).filter((f) => f.endsWith(".md"));
if (!files.length) { console.log("No entry files to gate."); process.exit(0); }

const rows = ["| Entry | Gate | Score | Verdict | Reason |", "|---|---|---|---|---|"];
for (const f of files) {
  const src = readFileSync(f, "utf8");
  const head = src.match(/^---\r?\n([\s\S]*?)\r?\n---/)?.[1] ?? "";
  if (!/^(expectation|premises):/m.test(head)) {
    rows.push(`| \`${f}\` | — | — | UNGATED | no expectation or premises to score |`);
    continue;
  }
  const genus = genusOf(/^type:\s*paradox\b/m.test(head) ? "paradox" : "irony");
  const fields = genus.name === "paradox" ? "premises/inference/conclusion/collision" : "expectation/reversal";
  try {
    const v = parseJSON(await harness(prompt(genus.prompts.gate),
      `Candidate entry (full file, score the frontmatter ${fields} against the body):\n\n${src}\nThreshold: ${genus.gate.threshold}`, `${genus.prompts.gate}-pr`));
    rows.push(`| \`${f}\` | ${genus.name} | ${v.score}/10 | ${v.verdict} | ${v.reason} |`);
  } catch (e) {
    rows.push(`| \`${f}\` | ${genus.name} | — | UNGATED | ${String(e.message).slice(0, 120)} |`);
  }
}
console.log(["## 🚪 Gate report", "", ...rows, "", "_Advisory: the gates score; humans merge. Ironies face the Alanis Gate, paradoxes the Epimenides Gate._"].join("\n"));
