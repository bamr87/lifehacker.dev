# AI Usage Metering — every token, every dollar, every PR

lifehacker.dev is built by AI agents, and AI effort is measured in tokens. This
document is the design reference for the metering system: how every model call
in the repo gets captured, attributed, published, and audited. The public face
is [/docs/ai-usage/](https://lifehacker.dev/docs/ai-usage/); the committed
snapshot is [`AI_USAGE.md`](../AI_USAGE.md) at the repo root.

## Goals

1. **Comprehensive** — every AI integration point is metered. Nothing spends
   tokens off the books.
2. **Attributed** — a pull request knows what it cost: the run that *created*
   it, plus every review, auto-fix, brand adjudication, and check that ran on
   it afterward.
3. **Transparent** — per-run step summaries, a per-PR sticky comment, a
   committed ledger, and a public dashboard page.
4. **OAuth-first** — every integration point authenticates with Claude Code
   subscription auth (`CLAUDE_CODE_OAUTH_TOKEN`) by default. When the OAuth
   token exists, `run.sh` strips `ANTHROPIC_API_KEY` from the CLI's environment
   so metered billing can't happen by accident.
5. **Self-enforcing** — `scripts/devops/audit.rb` fails CI when metering is
   unwired, so the system can't silently rot.

## Cost semantics (read this before quoting numbers)

The Claude Code CLI reports `total_cost_usd` for every run: **what the tokens
would bill at Anthropic's API list prices**. Under subscription (OAuth) auth
the marginal dollar cost is $0 — the subscription covers it — so every figure
this system publishes is labeled **API-equivalent**. It's the honest comparable
unit for "how much AI effort went into this," and it becomes real dollars the
moment a run falls back to a metered API key (`by_auth` in the summary breaks
that share out).

Two cost sources, marked on every record:

- `reported` — the CLI's own `total_cost_usd`. Authoritative.
- `estimated` — computed from [`_data/ai_pricing.yml`](../_data/ai_pricing.yml)
  for paths that report tokens but not dollars (the raw-API fallback). The
  estimator reproduces the CLI's arithmetic — `input×in + output×out +
  cache_read×0.1×in + cache_write(5m)×1.25×in + cache_write(1h)×2×in` — and was
  validated to the cent against a live run (2026-07-14).

## The pipeline: capture → report → ledger → publish

```
 every AI call                end of each AI job              daily sweep
┌─────────────────┐   ┌────────────────────────────┐   ┌──────────────────────┐
│ scripts/ai/     │   │ scripts/ai/usage_report.rb │   │ ai-usage.yml +       │
│ run.sh          │──▶│  • $GITHUB_STEP_SUMMARY    │──▶│ usage_ledger.rb      │
│  + usage.rb     │   │  • ai-usage-* artifact     │   │  • ledger.jsonl      │
│ (one JSONL      │   │  • sticky PR cost comment  │   │  • summary.yml       │
│  record/call)   │   │    (creation vs downstream)│   │  • AI_USAGE.md       │
└─────────────────┘   └────────────────────────────┘   │  • ONE data-only PR  │
                                                       └──────────┬───────────┘
                                                                  ▼
                                                       /docs/ai-usage/ (Liquid
                                                       over _data/ai_usage/)
```

### 1. Capture (`scripts/ai/usage.rb`)

`run.sh` runs `claude -p … --output-format json`, which returns the same run
with a final payload carrying `usage`, `modelUsage` (per-model splits — subagent
models included), `total_cost_usd`, `num_turns`, and `duration_ms`. `usage.rb`
normalizes that into one record and re-emits the result text, so callers see
exactly what they always did. The API fallback (`api_call.rb`) records its own
response usage the same way. Records land in `$RUNNER_TEMP/lh-ai-usage/` —
outside the checkout, so agents never see a dirty tree.

The record: `id` (stable per payload — ingest is idempotent), `ts`, `source`
(`claude-code` | `api-fallback` | `claude-code-action`), `status`, `agent`
(the fleet role), `model`, `auth` (`oauth` | `api_key`), `tokens`
(input/output/cache_read/cache_creation), `model_usage`, `cost_usd`,
`cost_source`, `duration_ms`, `num_turns`, `session_id`, the GitHub run context
(workflow/job/run_id/event/ref/sha), and `pr` + `pr_source` once attributed.

### 2. Report (`scripts/ai/usage_report.rb`)

Wired into the **`claude-run` composite** as always-run post-steps, so all its
consumers (pipeline's brand-review and content-review, content-factory,
fleet-dispatch, explore, brand-sweep, loop-tuner, agent-review, theme-scout,
content-scout, quest-forge, devops-audit) meter with zero per-workflow wiring.
Two integration points run models outside the composite and carry their own
copy of the same steps: `auto-fix.yml` (calls `run.sh` from a clone) and the
two gitfactory workflows (`claude-code-action`; the post-step parses the
action's `execution_file` output).

PR attribution, in priority order: an explicit `--pr N` (auto-fix knows its
PR), the `pull_request` event payload, or the **`pr-result.txt`** file the
factory/fleet agents write after opening a PR — those records get
`pr_source: "created"`, which is how a PR's *creation* cost is separated from
its *downstream* cost.

The sticky comment (marker `<!-- lh-ai-usage -->`) embeds its own base64 data
blob and merges new records by id, so it's cumulative across runs and safe to
re-run. Concurrent jobs can race the read-merge-write — last writer wins for
the *view*; the artifacts and ledger stay authoritative. The pipeline's harness
comment was switched from `gh pr comment --edit-last` to a marker-based upsert
for the same reason: two bot-authored sticky comments can't share `--edit-last`.

### 3. Ledger (`.github/workflows/ai-usage.yml` + `scripts/ai/usage_ledger.rb`)

Artifacts expire (30 days); the ledger doesn't. The daily sweep lists
`ai-usage-*` artifacts, downloads the recent window (`lookback_days`, default
3 — dedup makes overlap harmless and backfills safe), folds them into
`_data/ai_usage/ledger.jsonl`, regenerates `summary.yml` (the dashboard's data)
and root `AI_USAGE.md`, and opens **one** PR labeled `source/ai-usage-bot`,
superseding any older open sweep PR. Scheduled runs idle unless
`AI_USAGE_ENABLED=true`; manual runs default to dry-run. The workflow makes
zero model calls.

`classify_changes.rb` treats `_data/ai_usage/` + `AI_USAGE.md` as **data**, so
ledger PRs ride the lightest pipeline path, and the gated auto-merge sweep may
ship them under the same tight rule as triage refreshes: the diff must classify
as *pure data* or it gets `needs-human`.

### 4. Publish

[`pages/_docs/ai-usage.md`](../pages/_docs/ai-usage.md) renders
`site.data.ai_usage.summary` via Liquid (GitHub Pages safe mode — no plugins):
totals and 7/30-day windows, spend by workflow/role/model/month, the auth mix,
and the most expensive PRs split creation vs downstream.

## Guardrails & audit checks

`scripts/devops/audit.rb` (tier-1 `fast`, runs on every pipeline change) now
enforces, as **errors**:

- `run.sh` records usage (`usage.rb`) — spend never goes dark;
- `api_call.rb` records fallback usage;
- the `claude-run` composite publishes records (`usage_report`);
- any workflow using `claude-code-action` or calling `run.sh` directly carries
  a `usage_report` step — **this is the regeneration alarm**: gitfactory
  overwrites its workflows from the blueprint, and a regenerated file without
  the metering steps turns the pipeline red instead of going quietly unmetered;
- `ai-usage.yml` is gated by `AI_USAGE_ENABLED` (the standard autonomy-gate
  check).

The E2E simulation (`scripts/sim/simulate.rb`) drives the real capture → ledger
→ summary code with fixtures: reported vs estimated cost, ingest idempotency,
and the creation/downstream PR split are contract-tested on every pipeline
change.

## Turning it on

1. Metering itself is always on — capture + step summaries + artifacts + PR
   comments need no flag (they're observations, not actions).
2. Set the repo variable **`AI_USAGE_ENABLED=true`** to arm the daily ledger
   sweep (or run `ai-usage.yml` manually with `apply` for a one-off, with a
   bigger `lookback_days` to backfill from surviving artifacts).
3. Optional: `gh label create source/ai-usage-bot` happens automatically on
   first apply.
4. Auto-merge of ledger PRs rides the existing `AUTO_MERGE_ENABLED` switch.

## Known gaps (documented, not hidden)

- **Crashed runs** — a run that dies before Claude Code emits its result
  payload leaves no record (`status: "error"` covers failures that *finish*).
- **Local runs** — skills invoked on a laptop go through the same `run.sh`
  capture, but records land in the local temp dir and nothing sweeps them;
  CI is the system of record.
- **gitfactory regeneration** — regenerating the factory workflows drops the
  hand-added metering steps; the audit turns that into a red build with a
  pointer here. Re-add the two `📊` steps from either factory workflow.
- **Fixer-line PR attribution** — `factory--issue-factory-2` opens PRs via
  `claude-code-action`, which doesn't write `pr-result.txt`; its spend is
  metered at workflow level but not attributed to the PR it opened.
- **Comment race** — two AI jobs finishing simultaneously on one PR can lose a
  comment update to the race; the ledger reconciles the truth nightly.
- **Preview-image renderer** — `scripts/generate-preview-images.sh` bills
  non-Anthropic providers (OpenAI et al.) for raster rendering and is local
  tooling, off by default in CI; it is out of scope until it runs in CI.
