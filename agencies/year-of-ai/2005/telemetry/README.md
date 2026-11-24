# Evolution telemetry ledger

`evolution.jsonl.gz` is the raw record of every AI agent run in this lineage's growth loop — one gzipped JSON line per `grow` workflow run, appended automatically by [`telemetry.yml`](../.github/workflows/telemetry.yml) after each run completes. It retains the agent's full inputs/outputs (conversation turns, tool calls, usage, cost, permission denials) for detached analysis, review, evaluation, and learning.

## Schema — `evolution-telemetry/v1`

One JSON object per line:

| Field | Contents |
|---|---|
| `schema` | `"evolution-telemetry/v1"` |
| `repo` | Repository that ran the workflow (the lineage driver) |
| `run` | Workflow-run envelope: `id`, `number`, `event` (`schedule`/`workflow_dispatch`), `conclusion`, `head_sha`, `started_at`, `completed_at`, `url` |
| `phase_resolution` | `{phase, model}` chosen by the lifecycle policy resolver (`tick` or `distill`) |
| `attempts.api_key` | Raw `claude-code` execution log of the API-key attempt (full message history, tool calls, per-model usage, `total_cost_usd`, `permission_denials`), or `null` |
| `attempts.subscription` | Same, for the subscription-fallback attempt when it ran, or `null` |
| `collected_at` | When the record was appended |

Records where both attempts are `null` correspond to runs that failed before the agent produced output — kept for complete run coverage.

## Reading it

```bash
# Stream + filter
gunzip -c telemetry/evolution.jsonl.gz | jq '.run.number, .phase_resolution'

# Cost per run
gunzip -c telemetry/evolution.jsonl.gz | jq -r \
  '[.run.number, (.attempts.api_key.total_cost_usd // 0) + (.attempts.subscription.total_cost_usd // 0)] | @tsv'
```

```python
import pandas as pd
df = pd.read_json("telemetry/evolution.jsonl.gz", lines=True, compression="gzip")
```

Append-only: never edit or reorder existing lines — downstream evaluators treat the ledger as an immutable event stream.
