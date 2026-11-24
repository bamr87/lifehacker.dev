# ADR-0001: Centralized growth orchestration in the hub

**Status:** Accepted **Date:** 2026-06-18 **Deciders:** Repo owner (@bamr87)

## Context

The `year-of-ai` org is a set of **self-growing knowledge bases** — one repo per year (`1776`, `1777`, `1778`, `2005`–`2011`, …). Each researches and writes its own encyclopedic content one daily *tick* at a time, and each publishes its own GitHub Pages site.

The original model was **per-repo orchestration**: every year repo carried its own copy of the full growth toolkit — `grow.yml` (a daily cron), `lifecycle.yml` (policy + state machine), `seed.md` (concept + Evolution Log), and the complete `.github/` + `.claude/` agent framework (skills, prompts, agents, scripts). A "driver" repo forward-pollinated framework changes to the others peer-to-peer via `lineage.sh`.

Forces at play:
- **Drift & duplication.** N copies of the framework drifted; pollination was a cost center (telemetry: ~73% of turns / 62% of cost went to the shepherd path re-improvising git plumbing).
- **Scattered scheduling.** N crons, no single throttle or kill-switch.
- **Owner intent.** "The seed should live in the main hub repo, which also links to each individual year's Pages. Year repos should hold **only** the content, a GitHub Pages config, claude files, and telemetry." → centralize; keep year repos lean.
- **Cost shape.** Content generation is the expensive part and should run on a controlled cadence with model-tier escalation, not be re-paid per repo for mechanical framework upkeep.

## Decision

**Centralize all growth orchestration in the hub** (`year-of-ai.github.io`). The hub owns *what grows, how, and when*; year repos own *only their content + Pages*.

Hub holds:
- `lineage/seeds/<year>.md` — each year's concept (§1) + Evolution Log (§8, the tick clock).
- `lineage/policy.yml` — model tiers + cadence + auth contract.
- `lineage/framework/` — the **canonical** agent toolkit (Copilot layout: `prompts/`, `skills/`, `agents/`, `instructions/`, `scripts/`, `workflows/`).
- `.github/workflows/orchestrate.yml` — daily scheduler (refresh ledger → dispatch a grow tick per repo).
- `.github/workflows/grow-lineage.yml` — the growth engine (grows one repo/run).

Year repos hold: content + `_config.yml` + `.claude/` (**thin adapters**) + `telemetry/` + `CLAUDE.md` + `.gitignore`. No `seed.md`, `lifecycle.yml`, `.github/`, or per-repo cron.

A tick: hub checks out the target year repo → stages `lineage/framework/* → .github/` and `lineage/seeds/<repo>.md → seed.md` → runs the 3-tier escalation (`claude-haiku-4-5` draft → `claude-sonnet-4-6` expand → `claude-opus-4-8` enhance; `ANTHROPIC_API_KEY` fallback pass on empty-tree/`is_error`) → persists seed §8 back to the hub → strips hub-owned files → publishes **only** content + telemetry to the year repo.

### The framework mechanism — adapter + staging (the subtle part)

Year repos keep only **thin Claude-Code adapters** in `.claude/` (`.claude/skills/<n>/SKILL.md` ≈ 20 lines: *"canonical procedure: `.github/skills/<n>/SKILL.md` — read it and follow exactly"*; commands/agents likewise point to `.github/prompts/*` and `.github/agents/*`). The `claude` CLI **discovers** the adapter from `.claude/`; the adapter **delegates** to the canonical `.github/` file, which exists in the checkout **only because `grow-lineage.yml` staged it from the hub**. The staging is therefore **load-bearing**, not cosmetic, and it is stripped before publish so year repos stay lean. The hub is the single source of truth for the heavy procedures.

## Options Considered

### Option A: Per-repo orchestration (status quo ante)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Med (N crons, peer pollination) |
| Cost | High (framework upkeep re-paid per repo) |
| Scalability | Poor (drift grows with N) |
| Team familiarity | High (already running) |

**Pros:** repos are self-contained; no single point of failure. **Cons:** framework drift; duplicated heavy toolkit in every repo; no central throttle/kill-switch; pollination dominates cost.

### Option B: Centralized hub orchestration — adapter + staging (**chosen**)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Med (one engine, one scheduler; the adapter indirection must be understood) |
| Cost | Low (framework maintained once; agents spend only on content) |
| Scalability | Good (add a seed + enable Pages; no per-repo framework) |
| Team familiarity | Med (new mental model) |

**Pros:** single source of truth; lean year repos matching owner intent; one cadence/throttle; cheap to add a new era. **Cons:** the adapter→`.github`→staging indirection is non-obvious (a reader can wrongly conclude the staging is "inert" because discovery uses `.claude/` — see Consequences); the hub is a single point of failure for growth; cross-repo push needs `LIFECYCLE_PAT`.

#### Sub-options for the framework mechanism (within B)
- **B1 — adapter + staging (chosen):** year `.claude/` = pointers; hub `lineage/framework/` = canonical; staged into `.github/` at tick time. Lean repos, true centralization.
- **B2 — sync framework INTO each `.claude/` and publish it:** "true sync." Makes the canonical toolkit live in each repo. *Rejected:* fattens every repo, and a naive overwrite from the recovered hub copy would **regress** the live adapters (verified: hub `framework/` and year `.claude/` are different *representations*, not copies — overwriting loses fidelity).
- **B3 — drop staging, year `.claude/` is authoritative; hub copy is reference only:** *Rejected:* the adapters dangle (they point at `.github/` files that would no longer exist at tick time), **breaking growth**, and it abandons the "centralize the framework in the hub" goal.

### Option C: Monorepo (all years in one repo)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Low-Med |
| Cost | Low |
| Scalability | Poor (one Pages site; loses per-year sites + independent histories) |
| Team familiarity | High |

**Pros:** trivially no drift; one place for everything. **Cons:** loses the per-year Pages sites and independent identities that are the product; one giant history; coupled blast radius.

## Trade-off Analysis

The decisive forces were **owner intent** (lean year repos; seed + orchestration in the hub) and **cost** (stop re-paying for framework upkeep N times). A and C fail intent — A duplicates the framework; C destroys the per-year sites. Within B, the real fork is the framework mechanism: B2 and B3 are the "obvious" alternatives but each breaks something (B2 fattens/regresses repos; B3 breaks the adapters). **B1 keeps repos lean *and* the hub authoritative** by separating *discovery* (`.claude/` adapters, shipped in the repo) from *the procedure* (hub canonical, staged transiently). The price is one non-obvious indirection, paid down by this ADR + the inline workflow comments.

## Consequences

**Easier**
- Add a new era: write `lineage/seeds/<year>.md`, enable Pages — no per-repo framework. (Tangential auto-spawning is the next build.)
- Change a procedure/model once in the hub; every repo gets it next tick.
- One cadence, one throttle, one place to pause growth (don't dispatch).

**Harder / watch-outs**
- The adapter→staging indirection is easy to misread. (During this work it was twice mis-assessed as "inert dead weight" before the adapter delegation was traced — hence this ADR.) **Do not** "sync framework into `.claude/`" or drop the staging without re-reading this.
- The hub is a single point of failure for growth, and cross-repo writes depend on `LIFECYCLE_PAT`. If it's unset, the hub tracks but does not grow.
- Agent-written artifacts can drift in format. The first live tick wrote its §8 entry as an `h2` instead of `h3`, which the ledger parser missed (fixed: the parser now tolerates h2/h3 and the enhance prompt pins the exact format).

**To revisit**
- If the org grows to many dozens of repos, reconsider B2 (publish a synced `.claude/`) so a human can run a tick locally without the hub stage step.
- If hub-as-SPOF becomes a reliability problem, a thin per-repo fallback cron could re-enable degraded self-growth.

## Action Items

1. [x] Centralize seeds, policy, and framework into `lineage/`.
2. [x] Build `grow-lineage.yml` (3-tier escalation + API-key fallback + telemetry artifact) and rewire `orchestrate.yml` to dispatch it per repo.
3. [x] Reduce all 10 year repos to content + `_config.yml` + `.claude` + `telemetry`; enable Pages.
4. [x] Validate end-to-end on a live repo (`1778`, 2026-06-18) and fix the tick-clock format bug it surfaced.
5. [ ] Seed first content into the remaining `seeded` repos (paced rollout).
6. [ ] Build **tangential new-era spawning** from the frontier (uses `lineage/seed-package/` + an Opus subject pick) — the one unbuilt feature.
7. [ ] Keep `CLAUDE_CODE_OAUTH_TOKEN` valid (primary model auth); it is the growth blocker when it expires.
