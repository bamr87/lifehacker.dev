#!/usr/bin/env node
// =============================================================================
// index.ts — the lifehacker-read MCP server entry point.
// -----------------------------------------------------------------------------
// A read-only, secretless MCP server that exposes lifehacker.dev as a navigable
// resource tree + read/query tools over stdio. Point any MCP client at it with
// LH_REPO_ROOT set to a local checkout. This is P0 of docs/proposals/
// mcp-integration.md — the low-blast-radius review/explore/query surface.
// =============================================================================
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { RepoReader } from "./repo.js";
import { registerResources } from "./resources.js";
import { registerTools } from "./tools.js";

async function main(): Promise<void> {
  const reader = new RepoReader();

  const server = new McpServer({
    name: "lifehacker-read",
    version: "0.1.0",
  });

  registerResources(server, reader);
  registerTools(server, reader);

  // stderr only — stdout is the JSON-RPC channel and must not be polluted.
  process.stderr.write(`[lifehacker-read] serving from ${reader.root}\n`);

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  process.stderr.write(`[lifehacker-read] fatal: ${err instanceof Error ? err.stack : String(err)}\n`);
  process.exit(1);
});
