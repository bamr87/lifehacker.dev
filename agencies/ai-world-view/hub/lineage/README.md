# lineage/ — the canonical seeds & framework kit

This directory is the **source of truth** for the self-growing knowledge-base lineage. The country repos hold only their *content* (plus a GitHub Pages `_config.yml`, `.claude/`, and `telemetry/`); the hub owns the seed and orchestrates their growth.

- `seeds/<country>.md` — each country's **concept definition**: subject, taxonomy, source strategy (for this org: the model's **own world view** — no web research), conventions, and its Evolution Log. The orchestrator reads these to grow each repo.
- `seed-package/` — the **portable bootstrap kit** planted into a new repo when a lineage spawns: `seed.template.md`, `lifecycle.template.yml`, `MANIFEST.md`.
- `policy.yml` — the **canonical growth policy**: the 3-tier model escalation (Haiku → Sonnet → Opus), perpetual-growth rules, `cadence.repos_per_run` (stalest-first rotation — enforced by `orchestrate.yml`), the `preview:` banner art direction (the grow tick's Illustrate step), the `spawn:` gate (maturity-gated automatic country spawning via `plant-lineage.yml` — year-of-ai ADR-0007), and auth.
- `framework/` — the **canonical agent toolkit** (`prompts/`, `skills/`, `agents/`) that the hub's central grow workflow stages into a cloned country repo to run a tick. `workflows/` and `scripts/lineage.sh` are the retired peer-to-peer engine, kept as reference but **excluded from staging** — they are unreachable under the central model.

The reference implementation of this model (including its Architecture Decision Records and the org-genome replant tooling this hub was planted from) lives at [year-of-ai/year-of-ai.github.io](https://github.com/year-of-ai/year-of-ai.github.io).

Excluded from the Jekyll build (see `_config.yml`) — this is orchestration data, not site content. The published lineage view is `pages/lineage.md` (`/lineage/`).
