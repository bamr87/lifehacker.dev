# CI/CD — the tiered, continuous pipeline

> How the workflows gate, test and ship this site: the tiered `verify` pipeline, change-type routing, the autonomous content factory and its switches, token hygiene, and the one AI runner every lane shares.

Every workflow lives in `.github/workflows/`. The design goal: **tiered** (fast feedback first), **automatic** (the contract is exercised across stages on every change), and **continuous** (PR → merge → live-site verification), with one human merge gate no agent can bypass.

## Workflows at a glance

Every workflow — its triggers, `*_ENABLED` switch, repository variables and secrets, and the one-line summary from its header comment — is listed in [reference/workflows.md](reference/workflows.md), generated from the files by `ruby scripts/devops/workflow_reference.rb --write` (`check_drift.rb` fails the harness when it is stale). Each workflow's header comment is the full description of what it does and writes.

Only one of them gates a merge: the `verify` job of `pipeline.yml` (below). `mcp-tests.yml`, `site-quality.yml`, `ci.yml`, `conformance.yml`, `verify.yml` and `markdown-oneline.yml` report their own checks on a PR; everything else monitors (`deploy-verify.yml`, `nightly.yml`, `zer0-doctor.yml`) or is a loop behind its switch.

## The tiered pipeline (`pipeline.yml`)

One build, four tiers, each gating the next so feedback is fast and the build's artifact feeds everything downstream:

```
TIER 1  fast         ── ruby scripts/devops/audit.rb   (pipeline wiring + guardrails)
        (no build,      ruby scripts/sim/simulate.rb   (E2E contract: 15 scenarios)
         seconds)       ruby scripts/ci/test_auto_update_gate.rb
                                                       (auto-update's Gate, executed: 4 token states)
                        └▶ if this is red, stop before paying for a build
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

`verify` (the Tier-2 job in `pipeline.yml`) is the required check. Branch protection: require `verify` + 1 `CODEOWNERS` review, no self-approve, no force-push. The check name is held stable so protection never drifts. (See `docs/runbook-fleet.md` §2 for the `gh api` command.)

## Contract & artifact flow

The three layers are wired by **artifacts within one run**, not by whatever is committed:

1. Tier 2 runs the harness → `test-results/findings.jsonl` → uploaded as `contract`.
2. Tier 3 downloads `contract`, runs `build_queue.rb` on the **fresh** findings → `queue.json` → renders the fleet plan into the Step Summary.

`scripts/devops/audit.rb` enforces this wiring (it fails CI if a harness entrypoint can't produce the sev1 build finding, if the `verify` job is missing, or if `queue.json` drops a required field), so a producer/consumer field rename fails loudly instead of silently dropping data.

## Monitoring / reporting surfaces

- **PR sticky comment** — the harness gate verdict + findings table.
- **`GITHUB_STEP_SUMMARY`** — every workflow renders a live dashboard (gate, queue top-N, dispatch decision) so health is visible without opening artifacts.
- **`/docs/health/`** — the reader-facing dashboard, rendered from `_data/health/`.
- **`SITE_HEALTH.md`** — the committed snapshot for the repo/PR view.

## Secrets & least privilege

| Secret / var | Used by | Why |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` *or* `ANTHROPIC_API_KEY` | every AI step (brand-review, content-factory, explore, auto-fix, devops-manager) | Claude auth. The OAuth token (`claude setup-token`, subscription auth) is the preferred CI credential and drives the Claude Code path; an API key works too and is the **only** credential the Claude API fallback can use. **Optional** — the deterministic gate runs without either. |
| `XAI_OAUTH_TOKEN` *or* `XAI_API_KEY` | local/operator `scripts/preview/xai.mjs` (`--provider xai`) | Optional xAI Imagine covers. OAuth first (Kilo's xAI login also works on a laptop); the API key is last-resort and is never sent when OAuth is present. Not wired into any fleet cron. |
| `FLEET_TOKEN` (bot PAT) | upstream issue filing | The bot identity; scoped to contents/issues/PRs, **no** `administration`/`workflows`. |
| `FLEET_ENABLED` (repo **variable**) | `fleet-dispatch.yml` | The kill switch — instant, no merge; the bot can't set it. |

Workflows run on `pull_request` (not `pull_request_target`), so secrets are never exposed to fork PRs. No workflow grants `administration` or `workflows` scope.

### Token validity: presence is not validity

**Never write `GH_TOKEN: ${{ secrets.FLEET_TOKEN || github.token }}`.** `||` in an Actions expression returns the first **non-empty** operand, not the first *working* one. An expired PAT is a perfectly non-empty string, so it wins the `||` and `github.token` is never reached — the "degrade to a human-reviewed PR" fallback that these lines are usually commented with is unreachable, and an expired secret becomes strictly worse than no secret.

This is not hypothetical. When `FLEET_TOKEN` expired around 2026-07-24, it took out four workflows at once with two different signatures, and `content-scout` failed for **11 consecutive days** (2026-07-25 → 08-04) — each run buying ~10 minutes of agent browse, pushing its branch, then 401'ing on `gh pr create` and leaving an orphan `scout/*` ref with no PR. 13 orphan branches accumulated before anyone noticed (bamr87/bamr87#53).

Use the preflight instead, which **probes** the credential and degrades loudly:

```yaml
steps:
  - uses: actions/checkout@v7            # required: the action is local to this repo
  - name: Resolve a usable GitHub token
    id: tok
    uses: ./.github/actions/resolve-gh-token
    with:
      candidate: ${{ secrets.FLEET_TOKEN }}
      fallback: ${{ github.token }}
  # every later step now sees a GH_TOKEN that actually authenticates
```

It runs `gh api user`, exports `GH_TOKEN` to the rest of the job, and sets the output `source` to `fleet` or `default`. On the degraded path it emits `::warning::FLEET_TOKEN is set but REJECTED by the API` in the first seconds and the run still completes and still opens its PR (for a human, without auto-merge). Worked examples: `content-scout.yml` and `triage.yml` — the two workflows migrated so far. Unit tests: `scripts/ci/test_resolve_gh_token.sh`.

**Delete the job-level `env: GH_TOKEN:` — do not merely supplement it.** The composite exports `GH_TOKEN` through `$GITHUB_ENV`, and a job-level `env:` entry of the same name takes precedence over that. Adding the resolve step while leaving the old line in place looks correct, passes review, and changes nothing: the expired PAT still wins. Both migrated workflows carry a "deliberately NOT set here" comment where the `env` block used to be, for exactly this reason.

`scripts/ci/lint_tokens.rb` (harness check `tokens`) enforces this. The trap cannot be introduced anywhere new — that's an **error** and blocks the gate — while the workflows that still carry it from before the check existed are listed in its `MIGRATING` array and reported as **warnings**, so the remaining debt is visible on every run instead of buried in a PR description. Migrating a workflow means deleting its line from `MIGRATING` in the same PR; the check fails if you forget.

For `actions/checkout`'s `token:` the same idiom is still wrong but fails *fast* (`could not read Username`) rather than silently, and fixing it needs the probe to run before checkout — which a repo-local composite action cannot do. Those are tracked separately, at warning severity.

## Throughput notes

- The safe-mode build runs **once** per pipeline (Tier 2) and its artifact feeds Tier 3 — no duplicate PR-time builds.
- `bundler-cache: true` + a date-keyed theme-clone cache; `concurrency:` groups on every workflow cancel superseded runs.
- The DevOps audit reports the remaining duplicate builds across distinct-trigger workflows (`pipeline.yml`, `site-quality.yml`, `triage.yml`, `nightly.yml`) as *info* — they run at different times for different purposes.

## Change-type routing (efficiency)

The pipeline runs only the tier each change needs. A `changes` job classifies the PR diff with `scripts/ci/classify_changes.rb` into `content` / `deps` / `pipeline` / `data`, and the tiers gate on it:

| Change kind | Examples | Runs |
|---|---|---|
| **content** | `pages/**`, `_data/brand|navigation`, backlog, `_data/wire/sources.yml`, root content pages, assets | `verify` (build + content gate) + `content-review` |
| **deps** | `Gemfile*`, `_config*.yml` | `verify` + `fast` (build + harness + audit + sim) |
| **pipeline** | `scripts/**`, `.github/**`, `.claude/**` | `verify` + `fast` (audit + sim test the changed machinery) |
| **data** | `_data/health|fleet|analytics`, `SITE_HEALTH.md` | `verify` only |

`verify` (the required check) always runs so branch protection stays meaningful; `fast` is skipped for content-only PRs. An empty/unclassifiable diff fails safe to "run everything".

## The autonomous content factory

A daily, opt-in loop that generates content, reviews it, tests the live site, and (when enabled) merges and fixes itself:

| Workflow | Trigger | Gate | What it does |
|---|---|---|---|
| `content-scout.yml` | daily cron (before the factory), manual | `CONTENT_SCOUT_ENABLED` + key | Crawls a sister site (it-journey.dev by default; `SCOUT_SOURCES`) via WebFetch, proposes on-brand topics, and opens one `auto:content` PR appending `status: todo` backlog items — **each pinned to its source it-journey.dev page**. Scheduled runs apply; manual runs default to dry-run. |
| `wire-scout.yml` | daily cron (after content-scout, before the factory), manual | `WIRE_SCOUT_ENABLED` + key | Crawls the model-beat news sources configured in `_data/wire/sources.yml` (per-source frequency / trust tier / filters, validated by the harness's `wire` check) via WebFetch under the press charter + quarantine, and opens one `auto:content` PR appending `kind: wire` backlog items — **each pinned to the story URL it was reported from**, bylined `author: rhea`. Scheduled runs apply; manual runs default to dry-run. |
| `content-factory.yml` | daily cron, manual | `CONTENT_FACTORY_ENABLED` + key | One `grow-lifehacker` run per collection → one `auto:content` PR each. |
| `weekly-epic.yml` | weekly cron (Mon, before the factory), manual | `WEEKLY_EPIC_ENABLED` + key | One `weekly-epic` run → the illustrated recap of the prior week's publications, `_data/top_story.yml` repointed → one `auto:content` + `weekly-epic` PR that becomes the homepage hero on merge. |
| `content-review` (in `pipeline.yml`) | content PRs | key | The `content-reviewer` agent improves the draft and backlogs bigger ideas. |
| `explore.yml` | daily cron, manual | `EXPLORER_ENABLED` + key | The `site-explorer` browses the live site as beginner/intermediate/expert and files deduped issues + backlog ideas. Scheduled runs apply; manual runs default to dry-run. |
| `auto-merge.yml` | after `pipeline`, sweep, manual | `AUTO_MERGE_ENABLED` | Squash-merges green `auto:content` PRs — **only** content-only diffs (the smuggle guard refuses deps/pipeline). |
| `auto-update.yml` | after `pipeline`, sweep, manual | `AUTO_UPDATE_ENABLED` + `FLEET_TOKEN` | Merges `main` into each open `auto:content` PR in a runner (where the `_data/backlog.yml` `merge=backlog` driver actually fires — GitHub's merge button never runs it) and pushes, so colliding siblings stay mergeable. Real conflicts, duplicate backlog ids, and any merge that fails `lint_artifacts.rb` → `needs-human`, never pushed. Its `Gate` tests the token's **validity**, not merely its presence: a `FLEET_TOKEN` that is set but rejected fails the run with an `::error::` naming expiry, instead of passing the gate and dying in `Checkout` with `could not read Username`. `scripts/ci/test_auto_update_gate.rb` executes that Gate through all four token states in Tier 1. |
| `auto-fix.yml` | `pipeline` failure | `AUTO_FIX_ENABLED` + key | `fleet-bugfix` attempts a content-only fix; after 3 tries, labels `needs-human`. |

**The smuggle guard** is the load-bearing safety: `auto-merge.yml` re-classifies every candidate PR's diff and declines (labels `needs-human`) anything touching `deps`/`pipeline`, even if it's labeled `auto:content`. So auto-merge can only ever ship pure content; dependency, pipeline, and workflow changes are **always** human-gated. `scripts/devops/audit.rb` enforces both the per-workflow `*_ENABLED` gates and the smuggle guard, so these invariants fail CI if they regress.

## Turning on continuous autonomy (deliberate)

Each capability is its own switch, off by default. Turn on only what you trust — every switch, and the workflow that reads it, is in [reference/workflows.md](reference/workflows.md#repository-variables):

```
gh variable set CONTENT_FACTORY_ENABLED true    # e.g. daily content generation
```

What the generated list cannot show:

- `AUTO_MERGE_ENABLED` retires human content review for green, content-only `auto:content` PRs.
- `CONTENT_SCOUT_ENABLED`, `WIRE_SCOUT_ENABLED` and `AUTO_UPDATE_ENABLED` need a working `FLEET_TOKEN` (the scouts need it to auto-merge; auto-update cannot push without it); `THEME_SCOUT_ENABLED` needs it to file upstream.
- The weekly epic's painted hero image is double-gated: `OPENAI_IMAGES_ENABLED` **and** the `OPENAI_API_KEY` secret. `WEEKLY_EPIC_MODEL` overrides that loop's model; `SCOUT_SOURCES` retargets the content scout.
- `LOOP_TUNER_ENABLED` only lets the agent open PRs — the loop-tuner's measure runs regardless.

**The variable IS the switch** (colophon, 2026-07-01): every autonomy loop's cron is wired and idles behind its `*_ENABLED` variable, so turning a variable on is the single deliberate act that starts that loop — no workflow edit needed. The one exception is `fleet-dispatch.yml`, which stays schedule-free by guardrail (the audit and the simulation both fail if a schedule appears there). Enabling `AUTO_MERGE_ENABLED` (or any `*_ENABLED` variable) is a guardrail change — add a dated line to `/about/colophon/` when you flip one. The agent steps need Claude auth — set **either** `CLAUDE_CODE_OAUTH_TOKEN` (run `claude setup-token`, then `gh secret set CLAUDE_CODE_OAUTH_TOKEN`) **or** `ANTHROPIC_API_KEY`; upstream issue filing needs `FLEET_TOKEN`.

## Universal AI wiring (Claude Code → Claude API fallback)

Everything that calls a model — every workflow agent step *and* every skill — goes through **one** path, so the model, auth, and fallback are configured in a single place:

- **`_data/ai.yml`** — the one config: `model` (default `claude-opus-5-5`),
`fallback_model`, `max_tokens`, the API version/base. Change the model here and it changes everywhere.
- **The fleet's runner** — `bamr87/bamr87` `.github/actions/claude-run` (hub kit `ai-runner`), consumed by reference as `uses: bamr87/bamr87/.github/actions/claude-run@main`. Tries **Claude Code** (`claude -p` with tools/MCP — the full agent) first; if the CLI is missing or the run fails, falls back to this repo's **`scripts/ai/api_call.rb`**, a stdlib-only (`net/http`, no gem) single-shot call to the Claude API (`POST /v1/messages`, `anthropic-version 2023-06-01`, with refusal/429/5xx handling). The fallback is a degraded path — it returns the model's text but can't run tools, so fully agentic steps rely on Claude Code; analysis/review/draft steps work on either. Inputs: `prompt`, `agent`, `tools`, `mcp`, `system`, `out`, `model`, `max-turns`. This repo held the runner's source until 2026-09-08 and remains the kit's reference consumer; `scripts/ai/run.sh` is now a shim to the hub copy for the two non-workflow callers (`illustrate.mjs`, `launch.json`).

**A failed call is red, and it says why.** `claude -p --output-format json` writes its *failure* to stdout too — a payload naming what the API refused. `run.sh` prints that reason (secrets scrubbed), adds a one-line hint for the causes that recur here (quota exhausted, credential rejected, model unavailable, API overloaded), records it on the usage record as `error.{subtype,message}`, and — when the call was attempted and failed with no `ANTHROPIC_API_KEY` to fall back to — **exits non-zero**. A true no-op (nothing ever attempted) still exits 0, so a skill run locally without credentials degrades gracefully. The hub's `templates/ai-runner/tests/contract.sh` pins both halves against a stubbed `claude`, run by its `ai-runner-contract` workflow on every change to the runner.

> Colophon, 2026-08-23: this replaced a silent `exit 0`. From 2026-08-17 the content factory's five daily legs each died in ~1.8s with zero tokens spent, the AI step went green, and the failure surfaced one step later as `no PR was opened — auth? duplicate? build failure?` with the error payload already deleted. Six days of runs, five identical mystery reds a day, and no line anywhere saying what the API had actually said.

Every AI step (brand-review, content-review, content-factory, explore, auto-fix, devops-manager, and the fleet spawns) uses the hub action — **no workflow calls `claude -p` directly, and none carries a local copy of the action**; `scripts/devops/audit.rb` fails CI if one does.

**Auth** is one secret, set once: either `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token` — subscription auth, the preferred CI credential, drives the Claude Code path) **or** `ANTHROPIC_API_KEY` (pay-per-use; also the only credential the API fallback can use). `run.sh` prefers the OAuth token when both are present — and when the OAuth token exists it *removes* the API key from the CLI's environment, so a metered key can never be silently billed for work the subscription covers. With neither, AI steps are clean no-ops. Presence is not validity, though: a token that is *set* but expired, revoked, or out of quota passes every gate in this repo and only fails at the call — read the reason `run.sh` now prints, then mint a fresh one. To switch the whole fleet to a cheaper model, set `model:` in `_data/ai.yml` (or `AI_MODEL` for one run) — one edit, everywhere.

## AI metering (tokens + cost, per call, per PR)

Because every model call already flows through `run.sh`, metering rides the same choke point: `run.sh` asks Claude Code for a JSON result and `scripts/ai/usage.rb` records one JSONL record per call (tokens in/out/cache, per-model split, `total_cost_usd` as reported by the CLI, auth mode, workflow/job/run context). At the end of each AI job, `scripts/ai/usage_report.rb` (wired into the `claude-run` composite — consumers get it for free) publishes the records three ways: the run's step summary, an `ai-usage-*` artifact, and a sticky **AI usage & cost** comment on the PR the job worked on — resolved from the event, or from the `pr-result.txt` the factory/fleet agents write, so a PR's comment shows its *creation* cost and every downstream review/fix separately. `ai-usage.yml` makes it durable and public (see the workflows table; dashboard at `/docs/ai-usage/`). Dollars are **API-equivalent** (list prices) — OAuth subscription runs have zero marginal cost and are labeled as such; API-fallback records are estimated from `_data/ai_pricing.yml`. `scripts/devops/audit.rb` fails CI if the metering is ever unwired (run.sh without usage.rb, a claude-code-action workflow without a usage_report step, etc.). Full design: `docs/AI-USAGE.md`.
