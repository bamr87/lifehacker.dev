# telemetry/ — the hub evolution + banner ledgers

`evolution.jsonl` is the hub's **append-only growth ledger** — one `evolution-telemetry/v1` record per `Grow Lineage` run, written by the [Telemetry Ledger](../.github/workflows/telemetry-ledger.yml) collector (ADR-0003 keystone). It is the single signal the self-improvement fleet's learn / cost / monitor agents read; previously per-run telemetry was uploaded as a 14-day artifact and then discarded.

Each line:

```json
{
  "schema": "evolution-telemetry/v1",
  "run_id": "27770493316",        // the Grow Lineage run
  "repo": "<member-id>",            // the member repo grown this tick
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

## `banners.jsonl` — the banner ledger (ADR-0008)

One `banner/v1` record per banner the zer0-image-generator engine commits to a member — written by the engine's `--telemetry` (the grow tick's Illustrate step and the `reillustrate.yml` backfill), uploaded as a `*-banners-<repo>-<run_id>` artifact, and appended here by the same collector, which adds `repo` and `run_id`. Members also keep their own copy in their `telemetry/banners.jsonl`. Read by `scripts/sync-lineage-state.rb` (`banner_quality` per member in `_data/lineage.yml`, last 20 records), `scripts/banner-quality.rb` (the weekly watcher) and `scripts/reillustrate.rb` (the backfill planner).

```json
{
  "schema": "banner/v1", "ts": "2026-10-20T04:35:33Z",
  "repo": "<member-id>", "run_id": "27770493316",
  "slug": "…", "article": "_posts/…/x.md", "banner": "assets/images/previews/x.svg",
  "kind": "svg", "kb": 13.9, "provider": "claude", "model": "claude-sonnet-5-5",
  "style_card": "retro-pixel", "plan": true, "calls": 5, "rounds_used": 1,
  "fix_round": false, "fallback": null,          // "lint" | "author_failed" | "budget" | …
  "rasterizer": "resvg",
  "lint": {"clean": true, "errors": [], "warnings": []},
  "text": {"mode": "paths", "converted": 2, "stripped": 0, "fitted": 0, "missing_glyphs": 0},
  "critic": {"overall": 6.5, "thumbnail_holds": false, "fails": ["…"], "next_change": "…"},
  "tokens": {"input": 18234, "output": 9120},    // null when the run rode the claude CLI
  "cost_usd": 0.127716                           // list-price shadow cost; null on the CLI
}
```

Append-only and idempotent on `run_id`, like the evolution ledger. The schema is additive: new fields are free, renames bump the marker.

