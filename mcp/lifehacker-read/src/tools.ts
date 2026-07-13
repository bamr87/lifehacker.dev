// =============================================================================
// tools.ts — read / query / analyze tools (P0, read plane).
// -----------------------------------------------------------------------------
// Every tool here is READ-ONLY: no secrets, no network, no writes. The brand
// helpers mirror the data the CI linter enforces, but the authoritative lint
// (lint_brand.rb / lint_frontmatter.rb) is shelled by the act plane, not here.
// =============================================================================
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { checkWord, resolveVoiceProfile, voiceForCollection } from "./brand.js";
import {
  listCollection,
  listTaxonomy,
  loadItem,
  searchContent,
  type CollectionName,
} from "./collections.js";
import type { RepoReader } from "./repo.js";

const CollectionEnum = z.enum(["hacks", "tools", "posts", "docs", "about"]);

function text(payload: unknown) {
  return {
    content: [
      {
        type: "text" as const,
        text: typeof payload === "string" ? payload : JSON.stringify(payload, null, 2),
      },
    ],
  };
}

export function registerTools(server: McpServer, reader: RepoReader): void {
  server.registerTool(
    "search_content",
    {
      title: "Search content",
      description:
        "Full-text/metadata search across hacks+tools+posts+docs+about (title/tags/description/excerpt/body). Filter by collection and/or tag.",
      inputSchema: {
        query: z.string().describe("Search terms. Empty string + a tag filter lists everything with that tag."),
        collection: CollectionEnum.optional(),
        tag: z.string().optional(),
        limit: z.number().int().positive().max(100).optional(),
      },
    },
    async ({ query, collection, tag, limit }) =>
      text(searchContent(reader, { query, collection: collection as CollectionName | undefined, tag, limit })),
  );

  server.registerTool(
    "get_content_item",
    {
      title: "Get content item",
      description: "Fetch one item's parsed front matter + Markdown body by collection + slug.",
      inputSchema: { collection: CollectionEnum, slug: z.string() },
    },
    async ({ collection, slug }) => {
      const item = loadItem(reader, collection as CollectionName, slug);
      return item ? text(item) : text({ error: `not found: ${collection}/${slug}` });
    },
  );

  server.registerTool(
    "list_collection",
    {
      title: "List collection",
      description: "List all items in a collection with schema-relevant fields (tags, verdict, date, url).",
      inputSchema: { collection: CollectionEnum },
    },
    async ({ collection }) => {
      const items = listCollection(reader, collection as CollectionName).map((it) => ({
        slug: it.slug, title: it.title, description: it.description, date: it.date,
        author: it.author, tags: it.tags, verdict: it.verdict, url: it.url,
      }));
      return text({ collection, count: items.length, items });
    },
  );

  server.registerTool(
    "list_taxonomy",
    {
      title: "List taxonomy",
      description: "Pooled tags (posts+hacks+tools+docs+about) or categories (posts only), each with member items.",
      inputSchema: { kind: z.enum(["tags", "categories"]) },
    },
    async ({ kind }) => text(listTaxonomy(reader, kind)),
  );

  server.registerTool(
    "query_backlog",
    {
      title: "Query backlog",
      description: "List/filter the content backlog by status, kind, and/or priority.",
      inputSchema: {
        status: z.enum(["todo", "drafting", "done", "blocked"]).optional(),
        kind: z.enum(["hack", "tool", "post", "doc"]).optional(),
        priority: z.enum(["P1", "P2", "P3"]).optional(),
      },
    },
    async ({ status, kind, priority }) => {
      const data = reader.readYaml<{ backlog?: Array<Record<string, unknown>> }>("_data/backlog.yml") ?? {};
      let items = data.backlog ?? [];
      if (status) items = items.filter((i) => i["status"] === status);
      if (kind) items = items.filter((i) => i["kind"] === kind);
      if (priority) items = items.filter((i) => i["priority"] === priority);
      return text({ count: items.length, items });
    },
  );

  server.registerTool(
    "query_health_queue",
    {
      title: "Query health queue",
      description: "List RICE-ranked findings ('what should we fix next'), filterable by severity/type/route.",
      inputSchema: {
        severity: z.string().optional(),
        type: z.string().optional(),
        route: z.enum(["local", "upstream"]).optional(),
        limit: z.number().int().positive().max(200).optional(),
      },
    },
    async ({ severity, type, route, limit }) => {
      const queue = reader.exists("_data/health/queue.json")
        ? reader.readJson<Array<Record<string, unknown>>>("_data/health/queue.json")
        : [];
      let items = queue;
      if (severity) items = items.filter((i) => i["severity"] === severity);
      if (type) items = items.filter((i) => String(i["type"]).includes(type));
      if (route) items = items.filter((i) => i["route"] === route);
      return text({ count: items.length, items: items.slice(0, limit ?? 25) });
    },
  );

  server.registerTool(
    "get_brand_identity",
    {
      title: "Get brand identity",
      description: "Mission, pillars (promise + collection), motifs, the Prime Directive, and the voice-profile names.",
      inputSchema: {},
    },
    async () => {
      const identity = reader.readYaml<Record<string, unknown>>("_data/brand/identity.yml") ?? {};
      const voice = reader.readYaml<Record<string, unknown>>("_data/brand/voice.yml") ?? {};
      return text({
        ...identity,
        voice_default: voice["default"] ?? null,
        voice_profiles: Object.keys((voice["profiles"] ?? {}) as Record<string, unknown>),
      });
    },
  );

  server.registerTool(
    "check_word",
    {
      title: "Check word",
      description: "Classify a word/phrase against the glossary: banned-when-sincere, avoid-phrase, or ok.",
      inputSchema: { word: z.string() },
    },
    async ({ word }) => text(checkWord(reader, word)),
  );

  server.registerTool(
    "resolve_voice_profile",
    {
      title: "Resolve voice profile",
      description: "Return the voice profile the autopilot would use for a collection (or a named profile).",
      inputSchema: {
        collection: CollectionEnum.optional(),
        profile: z.string().optional(),
      },
    },
    async ({ collection, profile }) => {
      const resolved = resolveVoiceProfile(reader, {
        profile,
        collection: collection as CollectionName | undefined,
      });
      const mappedFrom = collection ? { collection, maps_to: voiceForCollection(collection as CollectionName) } : undefined;
      return text({ ...resolved, mappedFrom });
    },
  );
}
