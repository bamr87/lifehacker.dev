// =============================================================================
// smoke.ts — end-to-end verification of lifehacker-read.
// -----------------------------------------------------------------------------
// Launches the BUILT server (dist/index.js) over stdio via the SDK client, then
// exercises the real surface against the real repo: list tools/resources, read a
// couple of resources, and call a few tools. Exits non-zero on any failure so it
// can gate CI. Run:  npm run build && npm run smoke
// =============================================================================
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { resolveRepoRoot } from "./repo.js";

const HERE = dirname(fileURLToPath(import.meta.url));
const SERVER = join(HERE, "..", "dist", "index.js");

let failures = 0;
function check(label: string, ok: boolean, detail = ""): void {
  const mark = ok ? "PASS" : "FAIL";
  if (!ok) failures++;
  process.stdout.write(`  [${mark}] ${label}${detail ? ` — ${detail}` : ""}\n`);
}

function firstToolText(result: unknown): string {
  const content = (result as { content?: Array<{ type: string; text?: string }> }).content;
  return content?.find((x) => x.type === "text")?.text ?? "";
}

function firstResourceText(result: unknown): string {
  const contents = (result as { contents?: Array<{ text?: string }> }).contents;
  return contents?.[0]?.text ?? "";
}

async function main(): Promise<void> {
  const root = resolveRepoRoot();
  const transport = new StdioClientTransport({
    command: process.execPath,
    args: [SERVER],
    env: { ...process.env, LH_REPO_ROOT: root },
  });
  const client = new Client({ name: "lifehacker-read-smoke", version: "0.1.0" });
  await client.connect(transport);
  process.stdout.write(`\nlifehacker-read smoke test (repo: ${root})\n\n`);

  // --- tools -----------------------------------------------------------------
  const tools = await client.listTools();
  const toolNames = tools.tools.map((t) => t.name).sort();
  process.stdout.write(`Tools (${toolNames.length}): ${toolNames.join(", ")}\n`);
  check("expected read tools present", ["search_content", "get_content_item", "query_backlog", "query_health_queue", "check_word"].every((n) => toolNames.includes(n)));
  check("NO mutating verb exists", !toolNames.some((n) => /^(create|update|delete|propose|set|accept|trigger|run|merge|approve|close)_/.test(n)), "guardrails-by-absence");

  // --- resources -------------------------------------------------------------
  const resources = await client.listResources();
  const templates = await client.listResourceTemplates();
  process.stdout.write(`\nStatic resources: ${resources.resources.length}; templates: ${templates.resourceTemplates.length}\n`);
  check("brand/identity resource listed or templated", resources.resources.some((r) => r.uri === "lifehacker://brand/identity"));

  const identity = await client.readResource({ uri: "lifehacker://brand/identity" });
  check("brand/identity has a Prime Directive", firstResourceText(identity).toLowerCase().includes("prime_directive"));

  const queue = await client.readResource({ uri: "lifehacker://health/queue" });
  check("health/queue reads as JSON array", firstResourceText(queue).trim().startsWith("["));

  // --- content roundtrip via search → get ------------------------------------
  const search = JSON.parse(firstToolText(await client.callTool({ name: "search_content", arguments: { query: "git" } })));
  process.stdout.write(`\nsearch_content("git"): ${search.length} hits; top: ${search[0] ? `${search[0].collection}/${search[0].slug}` : "—"}\n`);
  check("search returns hits", Array.isArray(search) && search.length > 0);

  if (search[0]) {
    const item = JSON.parse(firstToolText(await client.callTool({ name: "get_content_item", arguments: { collection: search[0].collection, slug: search[0].slug } })));
    check("get_content_item roundtrips the top hit", item.slug === search[0].slug && typeof item.body === "string" && item.body.length > 0);
  }

  // --- backlog / health / brand tools ----------------------------------------
  const todo = JSON.parse(firstToolText(await client.callTool({ name: "query_backlog", arguments: { status: "todo" } })));
  process.stdout.write(`query_backlog(todo): ${todo.count} items\n`);
  check("query_backlog(todo) returns a count", typeof todo.count === "number");

  const hq = JSON.parse(firstToolText(await client.callTool({ name: "query_health_queue", arguments: { limit: 3 } })));
  check("query_health_queue returns items", Array.isArray(hq.items));

  const word = JSON.parse(firstToolText(await client.callTool({ name: "check_word", arguments: { word: "just" } })));
  process.stdout.write(`check_word("just"): ${word.classification}\n`);
  check("check_word('just') is banned-when-sincere", word.classification === "banned-when-sincere");

  const voice = JSON.parse(firstToolText(await client.callTool({ name: "resolve_voice_profile", arguments: { collection: "tools" } })));
  check("resolve_voice_profile(tools) = tool-review-honest", voice.requested === "tool-review-honest");

  const tax = JSON.parse(firstToolText(await client.callTool({ name: "list_taxonomy", arguments: { kind: "tags" } })));
  process.stdout.write(`list_taxonomy(tags): ${tax.length} distinct tags\n`);
  check("taxonomy has tags", Array.isArray(tax) && tax.length > 0);

  // --- the durable concept layer ---------------------------------------------
  const concepts = JSON.parse(firstToolText(await client.callTool({ name: "list_concepts", arguments: {} })));
  process.stdout.write(`list_concepts: ${concepts.count} durable concepts\n`);
  check("concept layer is present and every concept has a source", concepts.count > 0 && concepts.concepts.every((c: { sources: unknown[] }) => c.sources.length >= 1));
  const found = JSON.parse(firstToolText(await client.callTool({ name: "find_concepts", arguments: { query: "review bottleneck throughput" } })));
  check("find_concepts('review bottleneck throughput') → the rate-limiter concept", found[0]?.id === "CONCEPT-003");

  // --- the concept engine ----------------------------------------------------
  const growth = JSON.parse(firstToolText(await client.callTool({ name: "suggest_concept_growth", arguments: { limit: 5 } })));
  process.stdout.write(`suggest_concept_growth: top move → ${growth[0]?.action ?? "—"}\n`);
  check("concept engine suggests ranked growth moves", Array.isArray(growth) && growth.length > 0 && typeof growth[0].score === "number");

  await client.close();

  process.stdout.write(`\n${failures === 0 ? "ALL CHECKS PASSED" : `${failures} CHECK(S) FAILED`}\n`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((err) => {
  process.stderr.write(`smoke fatal: ${err instanceof Error ? err.stack : String(err)}\n`);
  process.exit(1);
});
