// =============================================================================
// repo.ts — the git-as-database reader.
// -----------------------------------------------------------------------------
// lifehacker.dev has no server and no database: every fact the autopilot knows
// is committed YAML / JSONL / Markdown. This module is the ONLY place that
// touches the filesystem. It resolves the repo root once, then reads committed
// files. It holds no secrets, opens no network, and never writes — that is what
// makes lifehacker-read safe to hand to any external AI.
// =============================================================================
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

const HERE = dirname(fileURLToPath(import.meta.url));

/** Resolve the repo root: LH_REPO_ROOT if set, else walk up to a dir with _config.yml. */
export function resolveRepoRoot(): string {
  const fromEnv = process.env.LH_REPO_ROOT;
  if (fromEnv) {
    const root = resolve(fromEnv);
    if (!existsSync(join(root, "_config.yml"))) {
      throw new Error(`LH_REPO_ROOT=${root} does not look like the lifehacker.dev repo (no _config.yml)`);
    }
    return root;
  }
  // Default: the server ships under <repo>/mcp/lifehacker-read/dist|src, so walk up.
  let dir = HERE;
  for (let i = 0; i < 8; i++) {
    if (existsSync(join(dir, "_config.yml"))) return dir;
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  throw new Error(
    "Could not locate the lifehacker.dev repo root. Set LH_REPO_ROOT to the checkout path.",
  );
}

export class RepoReader {
  readonly root: string;

  constructor(root?: string) {
    this.root = root ?? resolveRepoRoot();
  }

  /** Absolute path for a repo-relative path. */
  abs(relPath: string): string {
    return join(this.root, relPath);
  }

  exists(relPath: string): boolean {
    return existsSync(this.abs(relPath));
  }

  /** Read a UTF-8 text file. Throws a clean error if missing. */
  readText(relPath: string): string {
    const p = this.abs(relPath);
    if (!existsSync(p)) throw new Error(`not found: ${relPath}`);
    return readFileSync(p, "utf8");
  }

  /** Parse a YAML file into a plain object (safe parse — no code execution). */
  readYaml<T = unknown>(relPath: string): T {
    return parseYaml(this.readText(relPath)) as T;
  }

  /** Read a .jsonl file into an array of parsed objects (blank lines skipped). */
  readJsonl<T = unknown>(relPath: string): T[] {
    return this.readText(relPath)
      .split("\n")
      .map((l) => l.trim())
      .filter((l) => l.length > 0)
      .map((l) => JSON.parse(l) as T);
  }

  readJson<T = unknown>(relPath: string): T {
    return JSON.parse(this.readText(relPath)) as T;
  }

  /** List filenames (not paths) directly inside a repo-relative dir. */
  listDir(relDir: string): string[] {
    const p = this.abs(relDir);
    if (!existsSync(p) || !statSync(p).isDirectory()) return [];
    return readdirSync(p);
  }
}
