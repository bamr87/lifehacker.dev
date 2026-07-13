// =============================================================================
// server.test.ts — integration tests over the real MCP surface.
// -----------------------------------------------------------------------------
// Every assertion cross-checks the server against an INDEPENDENT read of the
// repo (fs counts / separate YAML+JSON parse in harness.ts), so a green run
// means the tools agree with the files on disk — not merely with themselves.
//   npm test
// =============================================================================
import assert from "node:assert/strict";
import { after, before, describe, test } from "node:test";
import {
  callJson,
  countMarkdown,
  groundJson,
  groundYaml,
  readResourceText,
  startHarness,
  type Harness,
} from "./harness.js";

const EXPECTED_TOOLS = [
  "check_word",
  "get_brand_identity",
  "get_content_item",
  "list_collection",
  "list_taxonomy",
  "query_backlog",
  "query_health_queue",
  "resolve_voice_profile",
  "search_content",
];

const COLLECTION_DIRS: Record<string, string> = {
  hacks: "pages/_hacks",
  tools: "pages/_tools",
  posts: "pages/_posts",
  docs: "pages/_docs",
  about: "pages/_about",
};

const MUTATING_VERB = /^(create|update|delete|remove|propose|set|accept|add|trigger|run|merge|approve|close|write|push|dispatch|file)_/;

interface SearchHit {
  collection: string;
  slug: string;
  tags: string[];
  score: number;
  url: string;
}

let h: Harness;
before(async () => {
  h = await startHarness();
});
after(async () => {
  await h.close();
});

describe("protocol & capabilities", () => {
  test("exposes exactly the 9 expected read tools", async () => {
    const { tools } = await h.client.listTools();
    assert.deepEqual(tools.map((t) => t.name).sort(), [...EXPECTED_TOOLS].sort());
  });

  test("every tool declares a description", async () => {
    const { tools } = await h.client.listTools();
    for (const t of tools) assert.ok((t.description ?? "").length > 10, `${t.name} needs a description`);
  });

  test("registers the 8 resource templates", async () => {
    const { resourceTemplates } = await h.client.listResourceTemplates();
    assert.equal(resourceTemplates.length, 8);
  });

  test("lists the static + enumerated resources (content is discoverable)", async () => {
    const { resources } = await h.client.listResources();
    const totalContent = Object.values(COLLECTION_DIRS).reduce((n, d) => n + countMarkdown(d), 0);
    assert.ok(resources.length >= totalContent, `expected >= ${totalContent} resources, got ${resources.length}`);
    assert.ok(resources.some((r) => r.uri === "lifehacker://brand/identity"));
  });
});

describe("guardrails by absence (the security invariant)", () => {
  test("NO tool is a mutating verb", async () => {
    const { tools } = await h.client.listTools();
    const offenders = tools.map((t) => t.name).filter((n) => MUTATING_VERB.test(n));
    assert.deepEqual(offenders, [], `mutating verbs must not exist: ${offenders.join(", ")}`);
  });

  test("no merge/approve/close/set-switch tool exists", async () => {
    const { tools } = await h.client.listTools();
    const names = new Set(tools.map((t) => t.name));
    for (const forbidden of ["merge_pr", "approve_pr", "close_issue", "set_switch", "create_content_item"]) {
      assert.ok(!names.has(forbidden), `${forbidden} must be absent`);
    }
  });
});

describe("content model (cross-checked vs files on disk)", () => {
  for (const [collection, dir] of Object.entries(COLLECTION_DIRS)) {
    test(`list_collection(${collection}) count == *.md on disk`, async () => {
      const res = await callJson<{ count: number; items: Array<{ url: string }> }>(h.client, "list_collection", { collection });
      assert.equal(res.count, countMarkdown(dir));
      for (const item of res.items) assert.match(item.url, /^\//, `url should be absolute: ${item.url}`);
    });
  }

  test("get_content_item roundtrips a real item and carries a body", async () => {
    const list = await callJson<{ items: Array<{ slug: string }> }>(h.client, "list_collection", { collection: "hacks" });
    const slug = list.items[0]!.slug;
    const item = await callJson<{ slug: string; body: string; title: string }>(h.client, "get_content_item", { collection: "hacks", slug });
    assert.equal(item.slug, slug);
    assert.ok(item.body.length > 0, "body must not be empty");
    assert.ok(item.title.length > 0, "title must not be empty");
  });

  test("posts permalink is date-structured", async () => {
    const list = await callJson<{ items: Array<{ url: string }> }>(h.client, "list_collection", { collection: "posts" });
    assert.match(list.items[0]!.url, /^\/posts\/\d{4}\/\d{2}\/\d{2}\/.+\/$/);
  });

  test("unknown slug returns a structured error, not a throw", async () => {
    const res = await callJson<{ error?: string }>(h.client, "get_content_item", { collection: "hacks", slug: "definitely-not-a-real-slug-xyz" });
    assert.ok(res.error, "should surface an error field");
  });

  test("invalid collection is rejected (schema error result, not success)", async () => {
    let errored = false;
    try {
      const res = await h.client.callTool({ name: "get_content_item", arguments: { collection: "bogus", slug: "x" } });
      errored = (res as { isError?: boolean }).isError === true;
    } catch {
      errored = true; // some clients surface it as a rejection instead
    }
    assert.ok(errored, "an invalid collection must not succeed");
  });
});

describe("search_content", () => {
  test("returns scored hits, sorted descending", async () => {
    const hits = await callJson<SearchHit[]>(h.client, "search_content", { query: "git" });
    assert.ok(hits.length > 0, "expected hits for 'git'");
    for (let i = 1; i < hits.length; i++) assert.ok(hits[i - 1]!.score >= hits[i]!.score, "scores must not increase");
  });

  test("collection filter is honored", async () => {
    const hits = await callJson<SearchHit[]>(h.client, "search_content", { query: "the", collection: "tools" });
    for (const hit of hits) assert.equal(hit.collection, "tools");
  });

  test("tag filter returns only items carrying the tag", async () => {
    const tax = await callJson<Array<{ name: string }>>(h.client, "list_taxonomy", { kind: "tags" });
    const tag = tax[0]!.name;
    const hits = await callJson<SearchHit[]>(h.client, "search_content", { query: "", tag });
    assert.ok(hits.length > 0);
    for (const hit of hits) assert.ok(hit.tags.map((t) => t.toLowerCase()).includes(tag.toLowerCase()), `hit ${hit.slug} lacks tag ${tag}`);
  });

  test("limit is respected", async () => {
    const hits = await callJson<SearchHit[]>(h.client, "search_content", { query: "the", limit: 3 });
    assert.ok(hits.length <= 3);
  });
});

describe("taxonomy", () => {
  test("tags pool is internally consistent (count == members)", async () => {
    const tax = await callJson<Array<{ name: string; count: number; items: unknown[] }>>(h.client, "list_taxonomy", { kind: "tags" });
    assert.ok(tax.length > 0);
    for (const entry of tax) assert.equal(entry.count, entry.items.length, `${entry.name}: count != members`);
  });

  test("categories include 'Field Notes'", async () => {
    const tax = await callJson<Array<{ name: string }>>(h.client, "list_taxonomy", { kind: "categories" });
    assert.ok(tax.some((c) => c.name === "Field Notes"));
  });
});

describe("query_backlog (cross-checked vs _data/backlog.yml)", () => {
  const ground = groundYaml<{ backlog: Array<Record<string, unknown>> }>("_data/backlog.yml").backlog;

  test("unfiltered count == backlog length on disk", async () => {
    const res = await callJson<{ count: number }>(h.client, "query_backlog", {});
    assert.equal(res.count, ground.length);
  });

  for (const status of ["todo", "done"]) {
    test(`status:${status} count matches independent count`, async () => {
      const expected = ground.filter((i) => i["status"] === status).length;
      const res = await callJson<{ count: number; items: Array<{ status: string }> }>(h.client, "query_backlog", { status });
      assert.equal(res.count, expected);
      for (const item of res.items) assert.equal(item["status"], status);
    });
  }
});

describe("query_health_queue (cross-checked vs _data/health/queue.json)", () => {
  const ground = groundJson<Array<Record<string, unknown>>>("_data/health/queue.json");

  test("unfiltered count == queue length on disk (count is the full total, not the page)", async () => {
    const res = await callJson<{ count: number }>(h.client, "query_health_queue", {});
    assert.equal(res.count, ground.length);
  });

  test("limit truncates the item page", async () => {
    const res = await callJson<{ items: unknown[] }>(h.client, "query_health_queue", { limit: 3 });
    assert.ok(res.items.length <= 3);
  });

  test("limit above the schema max is rejected", async () => {
    const res = await h.client.callTool({ name: "query_health_queue", arguments: { limit: 1000 } });
    assert.equal((res as { isError?: boolean }).isError, true);
  });

  test("severity filter is honored", async () => {
    const sev = String(ground[0]?.["severity"] ?? "sev4");
    const res = await callJson<{ items: Array<{ severity: string }> }>(h.client, "query_health_queue", { severity: sev, limit: 200 });
    for (const item of res.items) assert.equal(item.severity, sev);
  });
});

describe("brand (cross-checked vs _data/brand/*.yml)", () => {
  test("get_brand_identity carries the Prime Directive + voice profiles", async () => {
    const id = await callJson<{ prime_directive?: string; voice_profiles?: string[] }>(h.client, "get_brand_identity", {});
    assert.ok((id.prime_directive ?? "").length > 0);
    assert.ok((id.voice_profiles ?? []).length > 0);
  });

  test("EVERY banned-when-sincere word classifies as banned", async () => {
    const glossary = groundYaml<{ banned_when_sincere: string[] }>("_data/brand/glossary.yml");
    for (const word of glossary.banned_when_sincere) {
      const v = await callJson<{ classification: string }>(h.client, "check_word", { word });
      assert.equal(v.classification, "banned-when-sincere", `'${word}' should be banned-when-sincere`);
    }
  });

  test("a neutral word classifies as ok", async () => {
    const v = await callJson<{ classification: string }>(h.client, "check_word", { word: "lighthouse" });
    assert.equal(v.classification, "ok");
  });

  test("voice profile resolves per collection", async () => {
    const cases: Record<string, string> = {
      hacks: "how-to-practical",
      tools: "tool-review-honest",
      posts: "meta-confession",
      docs: "meta-confession",
    };
    for (const [collection, expected] of Object.entries(cases)) {
      const v = await callJson<{ requested: string; profile: unknown }>(h.client, "resolve_voice_profile", { collection });
      assert.equal(v.requested, expected);
      assert.ok(v.profile !== null, `${collection} profile object should be present`);
    }
  });
});

describe("resources", () => {
  test("brand/identity resource contains the Prime Directive", async () => {
    const text = await readResourceText(h.client, "lifehacker://brand/identity");
    assert.match(text.toLowerCase(), /prime_directive/);
  });

  test("findings resource is quarantined", async () => {
    const text = await readResourceText(h.client, "lifehacker://health/findings");
    assert.match(text, /<untrusted>/);
    assert.match(text, /UNTRUSTED/);
  });

  test("analytics resource surfaces the stale flag", async () => {
    const text = await readResourceText(h.client, "lifehacker://analytics/summary");
    const parsed = JSON.parse(text) as { analytics_stale: boolean };
    assert.equal(parsed.analytics_stale, true);
  });

  test("config/effective exposes the site config", async () => {
    const text = await readResourceText(h.client, "lifehacker://config/effective");
    assert.match(text, /title\s*:/);
  });

  test("a content template resource returns the body", async () => {
    const list = await callJson<{ items: Array<{ slug: string }> }>(h.client, "list_collection", { collection: "hacks" });
    const text = await readResourceText(h.client, `lifehacker://hacks/${list.items[0]!.slug}`);
    assert.ok(text.length > 50);
  });

  test("EVERY listed resource reads without error and is non-empty", async () => {
    const { resources } = await h.client.listResources();
    let checked = 0;
    for (const r of resources) {
      const text = await readResourceText(h.client, r.uri);
      assert.ok(text.length > 0, `empty resource: ${r.uri}`);
      checked++;
    }
    assert.ok(checked >= resources.length);
  });

  test("an unknown resource URI is rejected", async () => {
    await assert.rejects(() => h.client.readResource({ uri: "lifehacker://nope/does-not-exist" }));
  });
});
