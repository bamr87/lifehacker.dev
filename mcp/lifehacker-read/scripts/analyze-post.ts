// Ad-hoc: run the lifehacker-read MCP against one post and report what the
// durable-concept lens surfaces. Usage: node --import tsx scripts/analyze-post.ts <slug>
import { callJson, readResourceText, startHarness } from "../src/harness.js";

const SLUG = process.argv[2] ?? "concepts-context-content-i-hoard-the-one-that-rots";

// The durable concepts this post explicitly states (its "sentences worth keeping").
const CONCEPTS = [
  "make the durable layer durable on purpose",
  "put your style guide in git as data, not a PDF",
  "a placeholder only works if it's visibly incomplete",
  "the human is the rate limiter",
  "context you can rebuild on demand beats context you tried to freeze",
];

function h1(s: string) { process.stdout.write(`\n\x1b[1m${s}\x1b[0m\n`); }

const H = await startHarness();
try {
  h1("1. get_content_item(posts, slug) — the content layer");
  const item = await callJson<{ title: string; url: string; tags: string[]; body: string; author: string }>(
    H.client, "get_content_item", { collection: "posts", slug: SLUG },
  );
  console.log(`   title:  ${item.title}`);
  console.log(`   url:    ${item.url}`);
  console.log(`   author: ${item.author}    tags: ${item.tags.join(", ")}`);
  console.log(`   body:   ${item.body.length} chars`);

  h1("2. resolve_voice_profile(posts) — the context layer (how it's made)");
  const voice = await callJson<{ requested: string }>(H.client, "resolve_voice_profile", { collection: "posts" });
  console.log(`   voice profile the autopilot would use: ${voice.requested}`);

  h1("3. brand check on the post's key phrases (tier-1 glossary)");
  for (const w of ["context", "durable", "just", "seamless"]) {
    const v = await callJson<{ classification: string }>(H.client, "check_word", { word: w });
    console.log(`   "${w}" → ${v.classification}`);
  }

  h1("4. Where does each CONCEPT this post states currently live? (search_content)");
  for (const c of CONCEPTS) {
    // search on a few salient words from the concept
    const key = c.split(" ").filter((w) => w.length > 4).slice(0, 3).join(" ");
    const hits = await callJson<Array<{ collection: string; slug: string }>>(H.client, "search_content", { query: key, limit: 3 });
    const where = hits.length ? hits.map((x) => `${x.collection}/${x.slug}`).join(", ") : "— nothing";
    console.log(`   • "${c}"\n       carried by: ${where}`);
  }

  h1("5. Is there a durable CONCEPT layer to query? (the gap)");
  const { resources } = await H.client.listResources();
  const { tools } = await H.client.listTools();
  // NB: match the concept LAYER, not a post whose slug merely contains "concept".
  const hasConceptResource = resources.some((r) => r.uri.startsWith("lifehacker://concepts"));
  const hasConceptTool = tools.some((t) => t.name.endsWith("_concepts") || t.name === "get_concept");
  const retro = await readResourceText(H.client, "lifehacker://retrospectives").catch(() => "");
  const retroCount = (retro.match(/session_id/g) || []).length;
  console.log(`   concepts resource present? ${hasConceptResource ? "yes" : "NO"}`);
  console.log(`   list_concepts tool present? ${hasConceptTool ? "yes" : "NO"}`);
  console.log(`   retrospectives ledger entries (the only concept-catcher today): ${retroCount}`);
  console.log(`\n   → The post STATES ${CONCEPTS.length} durable concepts, but they live only inside`);
  console.log(`     the content that carried them. There is no queryable concept layer, so a`);
  console.log(`     fresh session cannot load "what this site has learned" in seconds.`);
} finally {
  await H.close();
}
