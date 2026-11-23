# telemetry/ — the hub evolution ledger

`evolution.jsonl` is the hub's **append-only growth ledger** — one `evolution-telemetry/v1` record per `Grow Lineage` run, written by the [Telemetry Ledger](../.github/workflows/telemetry-ledger.yml) collector (ADR-0003 keystone). It is the single signal the self-improvement fleet's learn / cost / monitor agents read; previously per-run telemetry was uploaded as a 14-day artifact and then discarded.

Each line:

```json
{
  "schema": "evolution-telemetry/v1",
  "run_id": "27770493316",        // the Grow Lineage run
  "repo": "1778",                  // year repo grown
  "conclusion": "success",         // workflow_run conclusion
  "is_error": false,               // agent result error flag (claude-execution-output.json)
  "num_turns": 42,
  "input_tokens": 123456,
  "output_tokens": 7890,
  "cost_usd": 0.42,
  "framework_sha": "…",            // hub SHA the tick ran under (for learn-window quarantine)
  "started": "2026-06-18T15:29:19Z",
  "ended": "2026-06-18T15:37:40Z"
}
```

Append-only and idempotent on `run_id` — never rewrite or reorder prior records.
