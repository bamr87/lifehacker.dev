// Irony Works engine library — harness, config, guardrails, genera.
import { readFileSync, appendFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { resolve, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
const yaml = createRequire(import.meta.url)("js-yaml"); // installed in-workflow: npm i js-yaml --no-save

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
export const cfg = yaml.load(readFileSync(join(ROOT, "engine", "seed.config.yml"), "utf8"));
export const root = (...p) => join(ROOT, ...p);

// ---------- guardrails: the engine's entire writable filesystem ----------
export function assertWritable(relPath) {
  const ok = (cfg.guardrails?.writable ?? []).some((w) =>
    w.endsWith("/") ? relPath.startsWith(w) : relPath === w
  );
  if (!ok) throw new Error(`GUARDRAIL: engine may not write "${relPath}". ${cfg.guardrails?.immutable_reason ?? ""}`);
  return relPath;
}
export function writeVaultFile(relPath, content) {
  assertWritable(relPath);
  mkdirSync(dirname(root(relPath)), { recursive: true });
  writeFileSync(root(relPath), content, "utf8");
}
export function appendCompost(row, rel = genusOf("irony").gate.compost) {
  assertWritable(rel);
  appendFileSync(root(rel), row.endsWith("\n") ? row : row + "\n", "utf8");
}

// ---------- genera: two schemas, one pipeline ----------
// A genus is a template, a prompt set (scout, scribe, gate), and a gate with its
// own threshold and compost ledger. Ironies and paradoxes share the nursery, the
// guardrails, and the human merge; everything else is looked up here.
export function genusOf(name = "irony") {
  const g = cfg.genera?.[name];
  if (!g) throw new Error(`unknown genus "${name}" — see engine/seed.config.yml → genera`);
  return { name, ...g };
}
// A rotation entry is a bare irony domain ("history-of-science") or a
// genus-qualified one ("paradox:logic-and-self-reference").
export function parseDomain(spec) {
  const [head, ...rest] = String(spec).split(":");
  return rest.length
    ? { genus: genusOf(head), domain: rest.join(":") }
    : { genus: genusOf("irony"), domain: head };
}

// ---------- prompts ----------
export const prompt = (name) => readFileSync(root("engine", "prompts", `${name}.md`), "utf8");

// ---------- usage metering ----------
// Every model call is metered the way lifehacker.dev meters its own: tokens and
// API-equivalent cost, appended to one JSON file per run. "API-equivalent" means
// what the tokens WOULD bill at list price — calls made on Claude Code
// subscription auth (OAuth) cost $0 marginal; only the metered-key path is spend.
const RUN_ID = process.env.GITHUB_RUN_ID ?? `local-${new Date().toISOString().slice(0, 10)}`;
const WORKFLOW = process.env.GITHUB_WORKFLOW ?? "local";

export function recordUsage(entry) {
  const rel = `_data/ai_usage/${RUN_ID}.json`;
  assertWritable(rel);
  const p = root(rel);
  mkdirSync(dirname(p), { recursive: true });
  let calls = [];
  if (existsSync(p)) {
    try { calls = JSON.parse(readFileSync(p, "utf8")).calls ?? []; } catch { /* corrupt file: start over */ }
  }
  calls.push({ at: new Date().toISOString(), ...entry });
  writeFileSync(p, JSON.stringify({ run_id: RUN_ID, workflow: WORKFLOW, calls }, null, 2) + "\n", "utf8");
}

// List-price accounting for the metered-key path, per million tokens.
const apiEquivalentCost = (model, usage) => {
  const rates = cfg.metering?.prices ?? {};
  const r = rates[model] ?? rates.default ?? { input: 3, output: 15 };
  return ((usage.input_tokens ?? 0) * r.input + (usage.output_tokens ?? 0) * r.output) / 1e6;
};

// ---------- harness ----------
// The wire is the Claude Code CLI, which carries its own OAuth credentials
// (keychain locally, CLAUDE_CODE_OAUTH_TOKEN in CI) — the same harness
// lifehacker.dev runs on. Fallback: the Anthropic API with ANTHROPIC_API_KEY.
// Prompts are the contract; the wire is a detail.
function claudeCodeAvailable() {
  try { execFileSync("claude", ["--version"], { stdio: "ignore" }); return true; } catch { return false; }
}

// `claude -p` runs the full agent, tools and all. Told to "output a Markdown
// file" it will try to WRITE one, then stall — a real cycle returned
// "Waiting for permission to write the file. The draft is ready…" in place of an
// entry. Disabling tools outright is worse: the model then emits raw
// <function_calls> markup as text. So the wire declares itself, and the five
// prompts stay wire-agnostic.
const WIRE_PREAMBLE = [
  "You are running as a text-completion harness, not an interactive agent.",
  "Do not use tools. Do not read or write files. Never ask for permission or confirmation.",
  "Your entire reply is consumed programmatically. Return only what the instructions below",
  "ask for — no preamble, no commentary, no tool-call syntax, no offers to proceed.",
].join(" ");

function harnessClaudeCode(system, user, h, label) {
  const raw = execFileSync(
    "claude",
    ["-p", "--model", h.model ?? "claude-sonnet-5-5",
     "--append-system-prompt", `${WIRE_PREAMBLE}\n\n${system}`,
     "--output-format", "json"],
    { input: user, encoding: "utf8", maxBuffer: 16 * 1024 * 1024 }
  );
  const r = JSON.parse(raw);
  if (r.is_error) throw new Error(`claude CLI: ${r.result ?? r.subtype ?? "unknown error"}`);
  const u = r.usage ?? {};
  recordUsage({
    label,
    provider: "claude-code",
    model: h.model ?? "claude-sonnet-5-5",
    input_tokens: u.input_tokens ?? 0,
    output_tokens: u.output_tokens ?? 0,
    cache_read_tokens: u.cache_read_input_tokens ?? 0,
    cache_creation_tokens: u.cache_creation_input_tokens ?? 0,
    cost_usd: r.total_cost_usd ?? 0,
    billed: false, // subscription OAuth — the cost column is API-equivalent, not spend
    duration_ms: r.duration_ms ?? null,
  });
  return String(r.result ?? "").trim();
}

async function harnessAnthropicAPI(system, user, h, label) {
  const key = process.env.ANTHROPIC_API_KEY;
  if (!key) throw new Error("no harness available: claude CLI not found and ANTHROPIC_API_KEY is not set");
  const model = h.model ?? "claude-sonnet-5-5";
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "content-type": "application/json", "x-api-key": key, "anthropic-version": "2023-06-01" },
    body: JSON.stringify({ model, max_tokens: h.max_tokens ?? 4000, system, messages: [{ role: "user", content: user }] }),
  });
  if (!res.ok) throw new Error(`harness ${res.status}: ${await res.text()}`);
  const data = await res.json();
  const u = data.usage ?? {};
  recordUsage({
    label,
    provider: "anthropic",
    model,
    input_tokens: u.input_tokens ?? 0,
    output_tokens: u.output_tokens ?? 0,
    cache_read_tokens: u.cache_read_input_tokens ?? 0,
    cache_creation_tokens: u.cache_creation_input_tokens ?? 0,
    cost_usd: apiEquivalentCost(model, u),
    billed: true, // metered key — this one is real spend
  });
  return data.content.filter((b) => b.type === "text").map((b) => b.text).join("\n");
}

export async function harness(system, user, label = "unlabeled") {
  const h = cfg.harness ?? {};
  // "lifehacker" is an alias, not a separate wire. lifehacker.dev has no completion
  // API — it runs Claude Code on OAuth, which is exactly the claude-code path below.
  if (h.provider === "anthropic") return harnessAnthropicAPI(system, user, h, label);
  if (claudeCodeAvailable()) {
    try {
      return harnessClaudeCode(system, user, h, label);
    } catch (e) {
      if (!process.env.ANTHROPIC_API_KEY) throw e;
      console.error(`claude CLI failed (${String(e.message).split("\n")[0]}); falling back to ANTHROPIC_API_KEY`);
    }
  }
  return harnessAnthropicAPI(system, user, h, label);
}

// ---------- helpers ----------
// Extract the first balanced JSON value from model output. The gate prompt asks
// for a structural check *before* the verdict, so the model reasonably narrates
// step zero and then emits JSON — stripping fences alone is not enough. Scans
// for the first { or [ and returns the balanced span, ignoring braces in strings.
export const parseJSON = (text) => {
  const t = String(text).replace(/```json|```/g, "");
  const start = t.search(/[{[]/);
  if (start === -1) throw new Error(`no JSON in model output: ${t.slice(0, 200)}`);
  const open = t[start];
  const close = open === "{" ? "}" : "]";
  let depth = 0, inStr = false, esc = false;
  for (let i = start; i < t.length; i++) {
    const ch = t[i];
    if (inStr) {
      if (esc) esc = false;
      else if (ch === "\\") esc = true;
      else if (ch === '"') inStr = false;
      continue;
    }
    if (ch === '"') inStr = true;
    else if (ch === open) depth++;
    else if (ch === close && --depth === 0) return JSON.parse(t.slice(start, i + 1));
  }
  throw new Error(`unbalanced JSON in model output: ${t.slice(start, start + 200)}`);
};
export const slugify = (s) =>
  s.toLowerCase().replace(/['".:,!?()]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
export const today = () => new Date().toISOString().slice(0, 10);
