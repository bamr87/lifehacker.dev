# lifehacker-read

The **P0 read-only MCP server** for lifehacker.dev — the site exposed as a
navigable, queryable resource tree over the [Model Context Protocol](https://modelcontextprotocol.io).
Point any MCP client (Claude Desktop, an IDE, another agent) at it and
**review / explore / query / analyze** the site with near-zero blast radius.

This is Phase 0 of the design in
[`docs/proposals/mcp-integration.md`](../../docs/proposals/mcp-integration.md).
It is deliberately the *safe* half: **no secrets, no network, no `gh`, no Docker,
and no writes.** It reads a local checkout (git is the database). The mutation
and fleet-control tools live on a separate, opt-in `lifehacker-act` server that
does not exist yet.

## What it exposes

**Resources** (`lifehacker://…`) — the git-as-database tree:

- Content: `collections/{c}`, `hacks|tools|posts|docs|about/{slug}` (each list-enumerable)
- Concepts: `concepts`, `concepts/{id}`, `concepts/coverage`, `concepts/graph` — the durable concept layer + the concept engine's gap map and wiki graph
- Brand: `brand/identity|voice|glossary|accepted`
- Data & memory: `backlog`, `authors`, `config/effective`, `retrospectives`, `scout/ideas` *(quarantined)*
- Health: `health/queue|summary|findings` *(evidence quarantined)*, `metrics/history`, `analytics/summary` *(surfaces the known-stale flag)*
- Fleet: `fleet/budget|state|improvements`
- Fleet self-description: `agents/{name}`, `skills/{name}`

**Tools** — all read-only:

| Tool | What it does |
|---|---|
| `search_content` | Full-text/metadata search across all collections (filter by collection/tag) |
| `get_content_item` | One item's front matter + body by collection+slug |
| `list_collection` | All items in a collection with schema fields |
| `list_concepts` | The durable concepts (portable ideas), optionally by tag |
| `get_concept` | One concept by id — sentence, gloss, and its carrier content |
| `find_concepts` | Search the concept layer: "what has this site learned about X" |
| `relate_concept` | A concept → the content, tags, and sibling concepts around it |
| `concepts_for` | Reverse lookup: which concepts a slug / tag / text carries |
| `concept_coverage` | The gap map: thin concepts + high-frequency tags with no concept |
| `suggest_concept_growth` | Ranked next moves — concept-first prioritization for growth |
| `list_taxonomy` | Pooled tags (all collections) or categories (posts) |
| `query_backlog` | Filter the content backlog by status/kind/priority |
| `query_health_queue` | The RICE-ranked "what should we fix next" queue |
| `get_brand_identity` | Mission, pillars, Prime Directive, voice names |
| `check_word` | Classify a word against the glossary (banned-when-sincere / avoid / ok) |
| `resolve_voice_profile` | The voice profile the autopilot would use for a collection |

**Guardrails by absence:** there is no `create`/`update`/`propose`/`merge`/…
verb in this server at all — a property the smoke test asserts.

## Run it

```bash
cd mcp/lifehacker-read
npm install
npm run build
npm run smoke     # end-to-end: launches the server, exercises the real repo, asserts results
```

`npm run smoke` should print `ALL CHECKS PASSED`.

## Wire it into an MCP client

`LH_REPO_ROOT` defaults to the repo this package lives in; set it explicitly to
point at any checkout.

```jsonc
// Claude Desktop: claude_desktop_config.json
{
  "mcpServers": {
    "lifehacker-read": {
      "command": "node",
      "args": ["/absolute/path/to/lifehacker.dev/mcp/lifehacker-read/dist/index.js"],
      "env": { "LH_REPO_ROOT": "/absolute/path/to/lifehacker.dev" }
    }
  }
}
```

## Layout

```
src/
  index.ts        server entry (stdio transport)
  repo.ts         the git-as-database reader (the only filesystem access)
  frontmatter.ts  split a Jekyll page into front matter + body
  collections.ts  the content model: list / load / search / taxonomy
  brand.ts        read the machine-readable brand (check_word, voice)
  quarantine.ts   wrap externally-sourced text as data, not instructions
  resources.ts    register the lifehacker:// resource tree
  tools.ts        register the read/query tools
  smoke.ts        end-to-end self-test (also a CI gate)
```

## What's intentionally NOT here

Verification (needs Docker), any mutation, and fleet control — those belong on
the opt-in `lifehacker-act` server (Phases P2–P5 of the plan), where the token
scopes, the `gh` allowlist wrapper, and the guardrail-integrity CI gate live.
Keeping them out is the point: this server is safe to host and hand out.
