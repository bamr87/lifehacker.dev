#!/usr/bin/env node
// One germination cycle: scout → gate → scribe → nursery + compost.
// Two genera share the cycle: a bare rotation entry grows ironies through the
// Alanis Gate; a `paradox:` family grows paradoxes through the Epimenides Gate.
// Usage: node engine/scripts/germinate.mjs [batch]
//   GERMINATE_DOMAIN=paradox:time-and-physics   overrides the rotation for one run
import { readdirSync, readFileSync, statSync } from "node:fs";
import { cfg, root, prompt, harness, parseJSON, slugify, today, writeVaultFile, appendCompost, parseDomain } from "./lib.mjs";

const batch = Number(process.argv[2] ?? cfg.batch ?? 3);
const cycle = Number(process.env.GITHUB_RUN_NUMBER ?? 0);
const spec = process.env.GERMINATE_DOMAIN || cfg.domains[cycle % cfg.domains.length];
const { genus, domain } = parseDomain(spec);

// Existing titles across every branch of the vault, for dedupe and for
// Rhymes-with links — which may cross genera.
const existing = [];
for (const dir of readdirSync(root("vault"))) {
  if (dir.startsWith(".") || dir === "templates" || dir === "compost") continue;
  if (!statSync(root("vault", dir)).isDirectory()) continue;
  for (const f of readdirSync(root("vault", dir)).filter((f) => f.endsWith(".md"))) {
    const head = readFileSync(root("vault", dir, f), "utf8").slice(0, 400);
    existing.push(head.match(/^title:\s*"?(.+?)"?\s*$/m)?.[1] ?? f.replace(/\.md$/, ""));
  }
}

console.log(`Cycle ${cycle} · genus: ${genus.name} · domain: ${domain} · batch: ${batch}\n`);

const candidates = parseJSON(
  await harness(prompt(genus.prompts.scout), `DOMAIN: ${domain}\nBATCH: ${batch}\nEXISTING:\n${existing.join("\n")}`, genus.prompts.scout)
);

const summary = [];
for (const c of candidates.slice(0, batch)) {
  const verdictRaw = await harness(
    prompt(genus.prompts.gate),
    `Candidate:\n${JSON.stringify(c, null, 2)}\nThreshold: ${genus.gate.threshold}`,
    genus.prompts.gate
  );
  const v = parseJSON(verdictRaw);

  if (v.score >= genus.gate.threshold && v.verdict === "PASS") {
    let entry = await harness(prompt(genus.prompts.scribe), `Candidate:\n${JSON.stringify(c, null, 2)}\nGate: ${JSON.stringify(v)}\nEXISTING titles for Rhymes-with links:\n${existing.join("\n")}\nToday: ${today()}`, genus.prompts.scribe);
    entry = entry.replace(/^```(markdown)?\n?|```$/g, "");
    const rel = `vault/nursery/${slugify(c.title)}.md`;
    writeVaultFile(rel, entry);
    summary.push(`🌱 PASS ${v.score}/10 — ${c.title} → ${rel}`);
  } else {
    appendCompost(`| ${today()} | ${c.title} | ${v.score}/10 | ${v.verdict} | ${v.reason} |`, genus.gate.compost);
    summary.push(`🍂 ${v.verdict} ${v.score}/10 — ${c.title} (composted: ${v.reason})`);
  }
}

const report = summary.join("\n");
console.log("\n" + report);
if (process.env.GITHUB_OUTPUT) {
  const fs = await import("node:fs");
  fs.appendFileSync(process.env.GITHUB_OUTPUT, `report<<EOM\n${report}\nEOM\ndomain=${spec}\ngenus=${genus.name}\n`);
}
