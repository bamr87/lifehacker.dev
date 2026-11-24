---
name: Replant
description: "End this repository's growth generation and plant its successor: finalize and compact the current knowledge base, mark it mature, then spawn a fresh repo for the next concept in the lineage carrying only the necessary context and files. Use when: check-lifecycle reports phase `replant` (generation tick budget spent); manually rotating the lineage to its next subject. Concept-agnostic — succession rule and lineage come from lifecycle.yml."
argument-hint: "Optional: `--force` to replant before the tick budget is spent, or an explicit successor subject to override the succession rule."
agent: agent
tools: [read, edit, execute, web, github]
---

Run the **replant routine**: close out this repository's growth generation and spawn its successor. A replant is two halves of one operation — (a) compact this repo to a finished, seed-rebuildable state, and (b) plant the framework into a **new repository** for the next concept, carrying only the necessary context and files.

Read [lifecycle.yml](../../lifecycle.yml) and the Concept Definition in [seed.md](../../seed.md) first — everything is parameterized by them.

## Preconditions

1. Run the **check-lifecycle** skill. Proceed only if it reports phase `replant` (`generation_ticks ≥ replant_after_ticks`), or the user passed `--force`.
2. Confirm push access and the ability to create repositories. In CI the ambient GitHub token is scoped to this repo only and **cannot** create repos — the PAT arrives as the `LIFECYCLE_PAT` environment variable; verify it is non-empty and run repo-creation/archival commands as `GH_TOKEN="$LIFECYCLE_PAT" gh …`. (Interactively: any `gh` credential with repo-creation scope, or the GitHub MCP `create_repository` tool.) If no such credential exists, stop and report — never half-replant.

## Part A — Finalize this repo (compact in place)

1. **Settle structure** — run the **build-structure** skill so all generated artifacts (indices, TIMELINE, INDEX, cross-refs) reflect final content.
2. **Compact the roadmap** — collapse unfinished Now/Backlog items into **Ideas** with a note `deferred at replant`; Done stays as the generation's record.
3. **Sync the DNA** — run the **sync-seed** skill; verify seed.md §7 Rebuild Procedure plus §1–6 genuinely suffice to reconstruct the repo (the necessary context IS the seed).
4. **Mark maturity** — in `lifecycle.yml`: set `state.status: mature` and this repo's lineage entry `status: mature`. Add a short *Status* line at the top of `README.md` noting the repo is mature and naming its successor (fill the link in after Part B).
5. **Record** — run the **encode-seed** prompt to append a `### Replant — <date>` entry to seed.md §8 summarizing the generation (ticks run, content totals, successor subject).
6. **Publish** — via the **publish-session** skill (commit + push to `main`).

## Part B — Spawn the successor

1. **Derive the successor concept** from `lifecycle.policy.succession.rule` applied to the newest lineage member (e.g. "the year 2005" → "the year 2006"). If the user passed an explicit subject, use that instead.
2. **Create the repository** under the same owner, named by the successor's subject slug (e.g. `2006`), public unless the lineage says otherwise. In CI: `GH_TOKEN="$LIFECYCLE_PAT" gh repo create <owner>/<slug> --public`.
3. **Plant only the necessary context and files** — nothing else:
   - `.github/` and `.claude/` layers, copied **verbatim** (they are concept-agnostic). **Source them from the lineage's canonical driver (`lineage[0]`)'s current `main`, not this repo's local tree**, unless this repo *is* the driver: the driver is the deterministic forward-pollination source and holds the reconciled framework, whereas a non-first member may carry drift (per-member `/learn` embeddings that never flowed back). This stops a successor from inheriting one member's gaps. Fall back to this repo's copy only if the driver is unreachable, and note the fallback in the replant log. `.github/workflows/grow.yml` needs the PAT to carry `workflow` scope (classic) / Workflows: write (fine-grained) — if the push is rejected for that one file, plant everything else, record the omission in the replant log entry, and continue (the shepherd fallback in LIFECYCLE.md keeps the successor growing); **never fail the replant over it**;
   - `CLAUDE.md` and `.gitignore`;
   - `lifecycle.yml` — same `policy`, `state.status: growing`, `state.generation_ticks: 0`, the **full lineage carried forward** with the new member appended (`status: growing`, `spawned_from: <this repo>`);
   - **no** content files, README knowledge table, ROADMAP, or seed inventories — the successor grows its own from genesis.
4. **Germinate** — in the successor, run the **genesis** prompt with the successor subject (it writes the new seed.md, README, ROADMAP). If genesis cannot be run cross-repo from here, leave a bootstrap note: the successor's first scheduled `/grow` must detect the missing seed and run `/genesis` itself (the grow workflow handles this).
5. **Close the loop** — fill the successor link into this repo's README *Status* line and `lifecycle.yml`, amend/commit/push via **publish-session**.
6. **Register with the driver** — if this repo is not the lineage's first member, also append the successor (and this repo's `mature` status) to the **driver repo's** `lifecycle.yml` lineage (clone `lineage[0]` via `GH_TOKEN="$LIFECYCLE_PAT"`, edit, push `chore: reconcile lineage registry`). The driver's lineage is the registry its workflow's phase resolver reads — a stale registry delays distill/consolidate triggers.

## Output Format

```
## Replant Summary

**Generation closed**: <subject> — <N> ticks, <rows> table rows, <files> topic files
**Status**: mature (pushed <SHA>)
**Successor**: <owner>/<slug> — <subject> (created | bootstrap pending /genesis)
**Lineage**: <m> of <consolidate_at_members> members toward consolidation
```
