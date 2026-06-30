# CI/CD — the tiered, continuous pipeline

Every workflow lives in `.github/workflows/`. The design goal: **tiered**
(fast feedback first), **automatic** (the contract is exercised across stages on
every change), and **continuous** (PR → merge → live-site verification), with one
human merge gate no agent can bypass.

## Workflows at a glance

| Workflow | Trigger | Gates a merge? | What it does / writes |
|---|---|---|---|
| `pipeline.yml` | PR, push to main, manual | **Yes — job `verify`** | The tiered pipeline (below). Writes `findings.jsonl`, `queue.json`, step summaries, sticky PR comment. |
| `deploy-verify.yml` | push to main, manual | No (monitors) | After Pages deploys, smoke-checks the **live** site; files one sev1 issue if production is non-200. |
| `triage.yml` | manual | No | Runs the harness, files deduped issues, opens a queue/dashboard PR. Build is fail-safe (a break → sev1 issue). |
| `nightly.yml` | cron, manual | No | External-link sweep + fresh-theme drift detection + full Prime-Directive run. Files one issue on failure. |
| `fleet-dispatch.yml` | manual | No | The dispatcher (plan-only unless `--apply`). Gated by `FLEET_ENABLED`; **no schedule**, **no `administration` scope**. |
| `devops-audit.yml` | manual | No | Deterministic CI/CD audit + (opt-in) the `devops-manager` agent to propose pipeline improvements. |
| `loop-tuner.yml` | manual (weekly cron, opt-in) | No | Always measures the loop's *observed* behaviour (`scripts/devops/loop_metrics.rb` — run times, failure/escalation rates, auto-fix attempts, recurring lint rules, conflicts); when `LOOP_TUNER_ENABLED` + key, the `loop-tuner` agent fixes the upstream cause and opens ONE PR. Content-agnostic. |

## The tiered pipeline (`pipeline.yml`)

One build, four tiers, each gating the next so feedback is fast and the build's
artifact feeds everything downstream:

```
TIER 1  fast         ── ruby scripts/devops/audit.rb   (pipeline wiring + guardrails)
        (no build,      ruby scripts/sim/simulate.rb   (E2E contract: 15 scenarios)
         seconds)       └▶ if this is red, stop before paying for a build
            │
TIER 2  verify       ── build-overlay (ONCE, continue-on-error)
        REQUIRED        run-all.sh (LH_BUILD_RC carries the build outcome → record_build → harness → aggregate)
        CHECK           ├▶ uploads `contract` artifact (test-results/ + _site/)
            │           └▶ gate: build + harness must pass
            ├────────────────────────────┐
TIER 2b brand-review  (conditional,       │   TIER 3  integration (needs verify)
        paid, comment-only, if key set)   │           ── downloads the `contract` artifact
                                          │              build_queue (FRESH findings, not committed)
                                          │              report.rb → GITHUB_STEP_SUMMARY (queue + fleet plan)
                                          ▼
                              ── sticky PR comment + Step Summary ──
```

After merge, `deploy-verify.yml` continues the flow against the live site.

### The required status check

`verify` (the Tier-2 job in `pipeline.yml`) is the required check. Branch
protection: require `verify` + 1 `CODEOWNERS` review, no self-approve, no
force-push. The check name is held stable so protection never drifts. (See
`docs/runbook-fleet.md` §2 for the `gh api` command.)

## Contract & artifact flow

The three layers are wired by **artifacts within one run**, not by whatever is
committed:

1. Tier 2 runs the harness → `test-results/findings.jsonl` → uploaded as `contract`.
2. Tier 3 downloads `contract`, runs `build_queue.rb` on the **fresh** findings →
   `queue.json` → renders the fleet plan into the Step Summary.

`scripts/devops/audit.rb` enforces this wiring (it fails CI if a harness
entrypoint can't produce the sev1 build finding, if the `verify` job is missing,
or if `queue.json` drops a required field), so a producer/consumer field rename
fails loudly instead of silently dropping data.

## Monitoring / reporting surfaces

- **PR sticky comment** — the harness gate verdict + findings table.
- **`GITHUB_STEP_SUMMARY`** — every workflow renders a live dashboard (gate,
  queue top-N, dispatch decision) so health is visible without opening artifacts.
- **`/docs/health/`** — the reader-facing dashboard, rendered from `_data/health/`.
- **`SITE_HEALTH.md`** — the committed snapshot for the repo/PR view.

## Secrets & least privilege

| Secret / var | Used by | Why |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` *or* `ANTHROPIC_API_KEY` | every AI step (brand-review, content-factory, explore, auto-fix, devops-manager) | Claude auth. The OAuth token (`claude setup-token`, subscription auth) is the preferred CI credential and drives the Claude Code path; an API key works too and is the **only** credential the Claude API fallback can use. **Optional** — the deterministic gate runs without either. |
| `FLEET_TOKEN` (bot PAT) | upstream issue filing | The bot identity; scoped to contents/issues/PRs, **no** `administration`/`workflows`. |
| `FLEET_ENABLED` (repo **variable**) | `fleet-dispatch.yml` | The kill switch — instant, no merge; the bot can't set it. |

Workflows run on `pull_request` (not `pull_request_target`), so secrets are never
exposed to fork PRs. No workflow grants `administration` or `workflows` scope.

## Throughput notes

- The safe-mode build runs **once** per pipeline (Tier 2) and its artifact feeds
  Tier 3 — no duplicate PR-time builds.
- `bundler-cache: true` + a date-keyed theme-clone cache; `concurrency:` groups on
  every workflow cancel superseded runs.
- The DevOps audit reports remaining duplicate builds across distinct-trigger
  workflows (currently 3: pipeline, triage, nightly) as *info* — they run at
  different times for different purposes.

## Change-type routing (efficiency)

The pipeline runs only the tier each change needs. A `changes` job classifies the
PR diff with `scripts/ci/classify_changes.rb` into `content` / `deps` / `pipeline`
/ `data`, and the tiers gate on it:

| Change kind | Examples | Runs |
|---|---|---|
| **content** | `pages/**`, `_data/brand|navigation`, backlog, root content pages, assets | `verify` (build + content gate) + `content-review` |
| **deps** | `Gemfile*`, `_config*.yml` | `verify` + `fast` (build + harness + audit + sim) |
| **pipeline** | `scripts/**`, `.github/**`, `.claude/**` | `verify` + `fast` (audit + sim test the changed machinery) |
| **data** | `_data/health|fleet|analytics`, `SITE_HEALTH.md` | `verify` only |

`verify` (the required check) always runs so branch protection stays meaningful;
`fast` is skipped for content-only PRs. An empty/unclassifiable diff fails safe to
"run everything".

## The autonomous content factory

A daily, opt-in loop that generates content, reviews it, tests the live site, and
(when enabled) merges and fixes itself:

| Workflow | Trigger | Gate | What it does |
|---|---|---|---|
| `content-factory.yml` | daily cron, manual | `CONTENT_FACTORY_ENABLED` + key | One `grow-lifehacker` run per collection → one `auto:content` PR each. |
| `content-review` (in `pipeline.yml`) | content PRs | key | The `content-reviewer` agent improves the draft and backlogs bigger ideas. |
| `explore.yml` | manual (cron commented) | `EXPLORER_ENABLED` + key | The `site-explorer` browses the live site as beginner/intermediate/expert and files deduped issues + backlog ideas. |
| `auto-merge.yml` | after `pipeline`, sweep, manual | `AUTO_MERGE_ENABLED` | Squash-merges green `auto:content` PRs — **only** content-only diffs (the smuggle guard refuses deps/pipeline). |
| `auto-update.yml` | after `pipeline`, sweep, manual | `AUTO_UPDATE_ENABLED` + `FLEET_TOKEN` | Merges `main` into each open `auto:content` PR in a runner (where the `_data/backlog.yml` `merge=union` driver actually fires — GitHub's merge button never runs it) and pushes, so colliding siblings stay mergeable. Real conflicts → `needs-human`. |
| `auto-fix.yml` | `pipeline` failure | `AUTO_FIX_ENABLED` + key | `fleet-bugfix` attempts a content-only fix; after 3 tries, labels `needs-human`. |

**The smuggle guard** is the load-bearing safety: `auto-merge.yml` re-classifies
every candidate PR's diff and declines (labels `needs-human`) anything touching
`deps`/`pipeline`, even if it's labeled `auto:content`. So auto-merge can only ever
ship pure content; dependency, pipeline, and workflow changes are **always**
human-gated. `scripts/devops/audit.rb` enforces both the per-workflow `*_ENABLED`
gates and the smuggle guard, so these invariants fail CI if they regress.

## Turning on continuous autonomy (deliberate)

Each capability is its own switch, off by default. Turn on only what you trust:

```
gh variable set FLEET_ENABLED true              # the fix/grow fleet
gh variable set CONTENT_FACTORY_ENABLED true    # daily content generation
gh variable set EXPLORER_ENABLED true           # live-site persona QA
gh variable set AUTO_FIX_ENABLED true           # auto-fix failing content PRs
gh variable set AUTO_UPDATE_ENABLED true        # keep colliding content PRs mergeable (union-merges main in; needs FLEET_TOKEN)
gh variable set AUTO_MERGE_ENABLED true         # auto-merge green content PRs (retires human content review)
gh variable set LOOP_TUNER_ENABLED true         # let the loop-tuner agent open improvement PRs from the metrics (measure runs regardless)
```

Enabling `AUTO_MERGE_ENABLED` (or uncommenting any `schedule:`) is a guardrail
change — add a dated line to `/about/colophon/` in the same PR. The agent steps
need Claude auth — set **either** `CLAUDE_CODE_OAUTH_TOKEN` (run `claude
setup-token`, then `gh secret set CLAUDE_CODE_OAUTH_TOKEN`) **or**
`ANTHROPIC_API_KEY`; upstream issue filing needs `FLEET_TOKEN`.

## Universal AI wiring (Claude Code → Claude API fallback)

Everything that calls a model — every workflow agent step *and* every skill —
goes through **one** path, so the model, auth, and fallback are configured in a
single place:

- **`_data/ai.yml`** — the one config: `model` (default `claude-opus-4-8`),
  `fallback_model`, `max_tokens`, the API version/base. Change the model here and
  it changes everywhere.
- **`scripts/ai/run.sh`** — the universal runner. Tries **Claude Code** (`claude -p`
  with tools/MCP — the full agent) first; if the CLI is missing or the run fails,
  falls back to **`scripts/ai/api_call.rb`**, a stdlib-only (`net/http`, no gem)
  single-shot call to the Claude API (`POST /v1/messages`, `anthropic-version
  2023-06-01`, with refusal/429/5xx handling). The fallback is a degraded path —
  it returns the model's text but can't run tools, so fully agentic steps rely on
  Claude Code; analysis/review/draft steps work on either.
- **`.github/actions/claude-run`** — the composite action workflows use instead of
  hand-rolling `npm install` + `claude -p`. It installs Claude Code and calls
  `run.sh`. Inputs: `prompt`, `tools`, `mcp`, `system`, `out`.

Every AI step (brand-review, content-review, content-factory, explore, auto-fix,
devops-manager, and the fleet spawns) uses the action or `run.sh` — **no workflow
calls `claude -p` directly**, and `scripts/devops/audit.rb` fails CI if one does.

**Auth** is one secret, set once: either `CLAUDE_CODE_OAUTH_TOKEN` (from `claude
setup-token` — subscription auth, the preferred CI credential, drives the Claude
Code path) **or** `ANTHROPIC_API_KEY` (pay-per-use; also the only credential the
API fallback can use). `run.sh` prefers the OAuth token when both are present.
With neither, AI steps are clean no-ops. To switch the whole fleet to a cheaper
model, set `model:` in `_data/ai.yml` (or `LH_AI_MODEL` for one run) — one edit,
everywhere.
