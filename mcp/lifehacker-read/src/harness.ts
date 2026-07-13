// =============================================================================
// harness.ts — shared test scaffolding.
// -----------------------------------------------------------------------------
// Spins up the REAL server (registerResources + registerTools) wired to an
// in-memory transport, so tests exercise the true MCP surface without a
// subprocess. Also provides "ground truth" helpers that read the repo directly
// (fs / independent YAML parse) so tests cross-check the server against an
// INDEPENDENT source — not against its own logic.
// =============================================================================
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { parse as parseYaml } from "yaml";
import { RepoReader } from "./repo.js";
import { registerResources } from "./resources.js";
import { registerTools } from "./tools.js";

export interface Harness {
  client: Client;
  reader: RepoReader;
  root: string;
  close(): Promise<void>;
}

export async function startHarness(): Promise<Harness> {
  const reader = new RepoReader();
  const server = new McpServer({ name: "lifehacker-read", version: "test" });
  registerResources(server, reader);
  registerTools(server, reader);

  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  const client = new Client({ name: "lifehacker-read-tests", version: "test" });
  await Promise.all([server.connect(serverTransport), client.connect(clientTransport)]);

  return {
    client,
    reader,
    root: reader.root,
    close: async () => {
      await client.close();
      await server.close();
    },
  };
}

// --- MCP result helpers ------------------------------------------------------

export function toolText(result: unknown): string {
  const content = (result as { content?: Array<{ type: string; text?: string }> }).content;
  return content?.find((c) => c.type === "text")?.text ?? "";
}

export function resourceText(result: unknown): string {
  const contents = (result as { contents?: Array<{ text?: string }> }).contents;
  return contents?.[0]?.text ?? "";
}

export async function callJson<T = unknown>(client: Client, name: string, args: Record<string, unknown> = {}): Promise<T> {
  const res = await client.callTool({ name, arguments: args });
  return JSON.parse(toolText(res)) as T;
}

export async function readResourceText(client: Client, uri: string): Promise<string> {
  const res = await client.readResource({ uri });
  return resourceText(res);
}

// --- Ground truth (independent of the server's own code paths) ---------------

const ROOT = new RepoReader().root;

export function repoRoot(): string {
  return ROOT;
}

/** Count *.md files directly on disk for a collection dir. */
export function countMarkdown(relDir: string): number {
  return readdirSync(join(ROOT, relDir)).filter((f) => f.endsWith(".md")).length;
}

/** Independently parse a repo YAML file (does not touch RepoReader/brand.ts). */
export function groundYaml<T = unknown>(rel: string): T {
  return parseYaml(readFileSync(join(ROOT, rel), "utf8")) as T;
}

/** Independently parse a repo JSON file. */
export function groundJson<T = unknown>(rel: string): T {
  return JSON.parse(readFileSync(join(ROOT, rel), "utf8")) as T;
}

/** Count regex hits in a raw file (independent count for cross-checks). */
export function countInFile(rel: string, re: RegExp): number {
  const text = readFileSync(join(ROOT, rel), "utf8");
  const matches = text.match(new RegExp(re.source, re.flags.includes("g") ? re.flags : re.flags + "g"));
  return matches ? matches.length : 0;
}
