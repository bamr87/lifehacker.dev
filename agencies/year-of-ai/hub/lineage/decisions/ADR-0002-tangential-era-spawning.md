# ADR-0002: Tangential new-era spawning

**Status:** Accepted **Date:** 2026-06-18 **Deciders:** Repo owner (@bamr87) **Depends on:** [ADR-0001](ADR-0001-centralized-growth-orchestration.md)

> **Update (2026-06-18):** approved and implemented. `lineage/repo-template/` +
> `scripts/plant-lineage.rb` shipped; the first tangential era, `year-of-ai/2012`,
> was spawned for real and is growing. The remaining piece is the optional
> `plant-lineage.yml` workflow (automated decide → gated plant); the manual
> path (human/frontier-model authors the seed, then `plant-lineage.rb --apply`)
> is proven.

## Context

Under the perpetual-growth model (ADR-0001), repos are never consolidated, archived, or deleted — the lineage only ever grows. The original intent was that **new eras spawn tangentially from the frontier**: as the newest knowledge base matures, the hub plants a fresh repo whose subject is *related to, but distinct from*, the frontier — so the lineage branches outward into adjacent territory rather than looping or stalling.

This is the **one unbuilt capability**. Today all 10 repos (1776–1778, 2005–2011) are growing, but the network can only deepen what exists; it cannot widen.

What already exists and can be reused:
- `lineage/seed-package/seed.template.md` — a `{{SUBJECT}}`-parameterized seed (§1 Concept Definition + empty §8) — the starting point for a new seed.
- `scripts/provision-org-sites.rb` — clones a repo, renders `templates/org-site/*` (`_config.yml` + nav), pushes (`--direct`), and enables Pages (`--enable-pages`). Idempotent; refuses to clobber a hand-rolled config.
- `_data/hub.yml` has `auto_discover: true` — **a new org repo is registered automatically** by the next `sync-hub-metadata.rb`; no manual registry edit.
- `orchestrate.yml` → `grow-lineage.yml` grows any repo that has a seed in `lineage/seeds/`.

The gap: nothing **decides** a tangential subject, **creates** the repo, or **plants** the minimal year-repo skeleton + hub seed.

## Decision

Add a **`plant-lineage`** capability to the hub: a gated, two-part operation that spawns one new era per invocation.

```
DECIDE (Opus)                          PLANT (deterministic script + gh)
─────────────                          ─────────────────────────────────
read the frontier seeds        →       create repo year-of-ai/<id>
propose { id, subject, concept }       drop the repo skeleton (.claude + CLAUDE.md
that is TANGENTIAL to the frontier       + telemetry/ + starter README/INDEX)
(related theme/era, not a dup)         render lineage/seeds/<id>.md from the
                                         proposed concept (seed.template.md)
                                       provision _config.yml + enable Pages
                                         (reuse provision-org-sites.rb)
                                       commit the new seed to the hub
                                       ─────────────────────────────────
                          auto-discovery registers it · orchestrate grows it next tick
```

The newly planted repo is **empty of content** — its first `grow-lineage` tick writes the first articles, exactly like any other repo. Planting only creates the *vessel* (skeleton + seed); growth fills it.

## Key design decisions

### A. How the tangential subject is chosen
**Chosen: Opus proposes, a human approves before anything is created.** A `decide` pass (frontier model) reads the newest seeds in `lineage/seeds/` and proposes `{ id, subject, scope, taxonomy }` that is tangential to the frontier — adjacent in theme or time, not a duplicate of an existing repo. The proposal is surfaced (workflow summary / PR body) and **creation is gated on explicit confirmation** (see E).

- *Rejected — fully autonomous spawn:* creating public repos with zero human gate is too irreversible for an unattended loop, especially early.
- *Rejected — human writes the whole concept:* loses the "AI picks a tangential direction" intent; the model is better at surveying the frontier for adjacency.

### B. Where the new repo's `.claude/` adapters come from
Every repo needs the thin `.claude/` adapters (ADR-0001) for `grow-lineage` to resolve skills at tick time. A brand-new repo has none.

**Chosen: a hub-owned `lineage/repo-template/`** holding the minimal year-repo skeleton — `.claude/` (the adapter set), `CLAUDE.md`, `telemetry/.gitkeep`, `.gitignore`, and starter `README.md`/`INDEX.md`. Planting copies it verbatim. This keeps the skeleton, like seeds and the framework, **canonical in the hub** and self-contained (consistent with ADR-0001). Seed it once by lifting the adapters from a current reference repo (e.g. `1776`).

- *Rejected — copy `.claude/` from a reference year repo at plant time:* couples planting to a peer repo's current state (the drift problem ADR-0001 retired).
- *Deferred — generate adapters from `lineage/framework/` via a layout transform:* elegant, but a larger build; the template is the pragmatic first step.

### C. Identifier & subject shape
A new era gets a short slug `id` (used as the repo name `year-of-ai/<id>`, the seed filename, and the Pages path). Year-like ids stay numeric (e.g. `2012`); thematic tangents may use a kebab slug. The `decide` pass proposes the `id`; the planter validates it is unique (no existing repo/seed) and URL-safe.

### D. Trigger & cadence
**Chosen: manual `workflow_dispatch` first.** Spawning is rare and high-consequence; it should not ride the daily growth cron initially. Once proven, a later ADR can gate automatic spawning on a frontier-maturity signal (e.g. the newest repo passing a tick/coverage threshold).

### E. Gating & safety (non-negotiable)
- **`dry_run` defaults to true** — the default invocation only *proposes and prints the plan*; it creates nothing.
- A real spawn requires `dry_run=false` **and** a `confirm: "<id>"` input that must match the proposed id — a two-key action.
- **Idempotent & non-destructive:** refuse if `year-of-ai/<id>` or `lineage/seeds/<id>.md` already exists. Never delete or overwrite an existing repo. One repo per run.
- **No content is generated at plant time** — only the vessel; the normal tick path (with its own auth + telemetry) fills it.

## Reuse vs. new

| Step | Mechanism |
|---|---|
| Decide subject | **new** — Opus `decide` pass over `lineage/seeds/*` |
| Create repo | **new** — `gh repo create year-of-ai/<id> --public` |
| Plant skeleton | **new** — copy `lineage/repo-template/*` |
| Create hub seed | **new** — render `seed-package/seed.template.md` → `lineage/seeds/<id>.md` |
| `_config.yml` + Pages | **reuse** — `provision-org-sites.rb --repos <id> --direct --enable-pages` |
| Register in hub | **reuse** — `auto_discover: true` (next `sync-hub-metadata.rb`) |
| Grow it | **reuse** — `orchestrate.yml` → `grow-lineage.yml` next cycle |

## Consequences

**Easier**
- The lineage can widen, not just deepen — the network grows new branches.
- Planting is hub-sourced and self-contained; a spawned repo is identical in shape to the hand-made ones.

**Harder / watch-outs**
- Creating public repos is outward-facing and effectively irreversible — hence the dry-run default + two-key confirm + human approval of the subject.
- `lineage/repo-template/` becomes a third thing to keep current alongside `seeds/` and `framework/`; if the adapter contract changes, update it too.
- The `decide` pass needs guardrails so "tangential" doesn't drift into off-mission or duplicate subjects (validate id uniqueness; show the proposal).

**To revisit**
- Automatic, maturity-gated spawning (deferred from D).
- Generating adapters from `lineage/framework/` instead of a static template (B).

## Implementation outline (draft — build after sign-off)

1. **`lineage/repo-template/`** — commit the minimal skeleton (lift `.claude/` + `CLAUDE.md` from `1776`; add `telemetry/.gitkeep`, `.gitignore`, starter `README.md`/`INDEX.md`).
2. **`scripts/plant-lineage.rb`** — `--dry-run` (default) prints the plan; `--apply --confirm <id>` performs it. Responsibilities: validate id is unique; `gh repo create`; copy `repo-template`; write `lineage/seeds/<id>.md` from the concept; shell out to `provision-org-sites.rb`; commit the seed to the hub. Reuses `scripts/lib/hub.rb`.
3. **`.github/workflows/plant-lineage.yml`** — `workflow_dispatch` with inputs `dry_run` (default `true`), `id`, `confirm`. Step 1: Opus `decide` pass writes the proposal to the job summary. Step 2 (only if `dry_run=false` and `confirm==id`): `plant-lineage.rb --apply`. Auth: `CLAUDE_CODE_OAUTH_TOKEN` for decide, `LIFECYCLE_PAT` for repo creation + push.
4. **Docs** — add the spawn flow to `/orchestration/` (§5 already names it) and flip this ADR to **Accepted**.

## Action Items
1. [x] Owner approves this design (and the dry-run-first / two-key gating).
2. [x] Build `lineage/repo-template/` (skeleton + adapters).
3. [x] Build `scripts/plant-lineage.rb` (dry-run first).
4. [x] Build `.github/workflows/plant-lineage.yml` (decide → gated plant) — built with maturity-gated auto mode, [ADR-0007](ADR-0007-maturity-gated-auto-spawning.md).
5. [x] Dry-run end-to-end; then one real spawn behind the two-key confirm (`2012`).
6. [x] Document on the site (`/orchestration/` §5); mark this ADR Accepted.
