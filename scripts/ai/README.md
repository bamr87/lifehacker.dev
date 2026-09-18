# scripts/ai — this repo's half of the `ai-runner` kit

Every model call this repo makes goes through the **fleet's** runner — the `claude-run` action in the hub, [bamr87/bamr87 `.github/actions/claude-run`](https://github.com/bamr87/bamr87/tree/main/.github/actions/claude-run) (kit `ai-runner`, docs in the hub's `templates/ai-runner/`). Workflows consume it by reference, `uses: bamr87/bamr87/.github/actions/claude-run@main`, so this repo holds no copy of the runner to drift. Until 2026-09-08 it held the source of truth; a real fleet of 17 lanes still tests the runner here daily, which is why the hub's kit README names this repo its reference consumer.

## What lives here

| File | What it does |
| --- | --- |
| `run.sh` | A **shim**, not the runner: finds the fleet runner (`$AI_RUNNER` exported by the hub action for nested calls, then a local hub clone at `$FLEET_HUB` or `../bamr87`, then a daily-refreshed download) and runs it with `AI_REPO_ROOT` pointed here. Exists for the two callers that are not a workflow step: a human running a fleet agent locally (`.vscode/launch.json`) and `scripts/preview/illustrate.mjs` from inside an agent session. Same flags, same exit contract. |
| `usage.rb` | Metering companion the runner probes for: one JSONL record per call (tokens, API-equivalent cost, model, status, CI context) into `$AI_USAGE_DIR/records.jsonl` (default `$RUNNER_TEMP/ai-usage`, outside the checkout). Without it the runner still enforces "is_error is a failure" but records nothing — `scripts/devops/audit.rb` fails CI if it goes missing. |
| `usage_report.rb` | End-of-job publisher the action's post-step runs when present: step summary, `ai-usage-*` artifact, sticky PR comment (marker `<!-- lh-ai-usage -->`). |
| `api_call.rb` | The single-shot Messages API fallback the runner uses when Claude Code is unavailable or fails. Stdlib only, self-contained; reads `_data/ai.yml`. |
| `usage_ledger.rb` | lifehacker.dev only: sweeps the artifacts into `_data/ai_usage/` + `AI_USAGE.md` (the `ai-usage.yml` workflow). |

Configuration lives in `_data/ai.yml` (`model`, `fallback_model`, `max_tokens`, API wire details). Auth never lives in a file. Extra excludes for the runner's post-run one-paragraph-per-line normalizer go in the repo-root `.prose-excludes`, one extended regex per line.

## Contract (the runner's — unchanged by the move)

```bash
scripts/ai/run.sh --prompt "..." [--agent name] [--tools "Bash,Read"] [--mcp cfg.json] \
                  [--system "..."] [--out file] [--model id] [--max-turns N]
```

| Variable | Meaning |
| --- | --- |
| `CLAUDE_CODE_OAUTH_TOKEN` | Preferred credential (`claude setup-token`). When set, `ANTHROPIC_API_KEY` is stripped from the CLI's environment so the metered key is never billed for subscription work. |
| `ANTHROPIC_API_KEY` | Fallback credential; the only one the API fallback can use. |
| `AI_MODEL` | Override the model from `_data/ai.yml` for one run (`--model` beats it). |
| `AI_FORCE_API=1` | Skip Claude Code, go straight to the API fallback. |
| `AI_MAX_TURNS` | Cap the agent's turns (`--max-turns`); unset = CLI default. |
| `AI_USAGE_DIR` | Where `usage.rb` writes records. |
| `AI_REPO_ROOT` | The tree the runner acts on (the shim sets it to this repo; `auto-fix.yml` points it at its clone). |
| `AI_RUNNER` | Path of the runner, exported by the hub action so nested calls reuse it. |

| Exit | Meaning |
| --- | --- |
| `0` | The call ran, **or** nothing was ever attempted (no `claude` on PATH and no API key — the documented no-op). |
| `1` | The call was attempted and failed with no usable fallback. The reason is printed and raised as a `::error::` annotation under Actions. |

The exit contract is pinned by the hub's `templates/ai-runner/tests/contract.sh`, run by its `ai-runner-contract` workflow on every change to the runner. To run that suite against this repo's companions (it exercises the once-only metering assertion only where `usage.rb` exists): `AI_RUNNER_SUT=scripts/ai/run.sh bash <hub>/templates/ai-runner/tests/contract.sh`.

## Adopting the kit in a sibling repo

1. In every workflow: `uses: bamr87/bamr87/.github/actions/claude-run@main` with the job env carrying the auth secret, behind a `<LANE>_ENABLED` repository variable — or take the whole lane from the hub's reusable `ai-lane.yml` (see its `templates/ai-runner/ai-lane.template.yml`).
2. Provide `_data/ai.yml` with at least `model:`.
3. Copy `usage.rb` + `usage_report.rb` for metering and `api_call.rb` for the fallback, or leave them out — the runner adapts.
4. Do **not** copy `run.sh` unless something outside a workflow step needs to call the runner; if so, copy this shim, not a runner.
