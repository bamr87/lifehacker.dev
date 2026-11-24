# ADR-0005: docs-warden — documentation coverage as a fleet agent

**Status:** Accepted **Date:** 2026-06-18 **Deciders:** Repo owner (@bamr87) **Extends:** [ADR-0003](ADR-0003-self-improving-agent-fleet.md) (the self-improvement fleet)

## Context

Across this build the hub accumulated workflows, scripts, ADRs, a genome, and a fleet — and documentation drifted: e.g. `plant-lineage.rb` and several new workflows (`codeql`, `framework-pr-reviewer`) shipped without a CLAUDE.md entry, and `.github/config/environment.yml` pins Ruby 3.2 while every workflow inlines 3.3. The existing reviewers cover only slices: `ai-content-review` (pages prose), `framework-pr-reviewer` (framework safety), `genome-sync` (genome drift). Nothing guaranteed that **every change is matched by a doc update** — the goal of complete coverage of all changes/improvements/additions.

## Decision

Add **docs-warden**, an ADR-0003 fleet agent (UPDATE/GOVERN stage) for the hub's own doc surface, in four files:

- `.github/config/docs_warden.yml` — the editable **change→doc coverage map**, the doc-exempt predicate, the bot-commit allowlist, and the `enforcement` knob.
- `scripts/docs-warden.rb` — the deterministic engine: `--base` (PR coverage) + `--census` (drift); `--json`/`--summary`/`--check`.
- `.github/workflows/docs-warden.yml` — **gate** (PR), **sweep** (weekly + manual drift census → an issue), kill-switch aware.
- `.github/instructions/docs-warden.instructions.md` — the contract.

It is the hub analogue of the member-repo `claude-md-canon-warden`. It does **not** overlap the three existing reviewers.

## Key design choices

- **Gate + sweep ⇒ 100% commit coverage.** PRs are caught by the gate; the no-PR automated commits (grow ticks, ledger appends, dashboard refreshes) are observed by the sweep. The exempt set + bot allowlist keep it silent on the ~90% of commits that are legitimately doc-free.
- **Exempt set is decoupled from the genome `ignore` tier.** "Does it transplant?" ≠ "does it need a doc?" — `CLAUDE.md`/ADRs are genome-ignored yet are prime doc targets, so they are not exempt.
- **Seed grow-commits are exempt by committer + message**, not by section: the grow tick git-adds the whole seed, so a section filter would flag every tick.
- **Read-only / PR-not-direct** (ADR-0003): the gate comments, the sweep files an issue. No commit/push/merge. Kill-switch (`_data/fleet_pause.yml`) honored first.
- **`enforcement: warn`** at rollout (always advises, never blocks) → `soft-gate` (dismissible) → `hard-gate`, tuned in config without editing the workflow.

## Consequences

- **Easier:** undocumented changes become visible (the warden caught its own predecessors' gaps — `codeql.yml`, `framework-pr-reviewer.yml` — on first run), and adding a new surface to the map is itself a tracked change, so the map can't silently rot.
- **Watch-outs:** the map must be extended when a genuinely new surface appears (the UNKNOWN-surface note is the forcing function). An auto-drafting companion-doc-PR mode is deferred (a second mutation surface; doc-only allowlist if ever built).

## Action Items
1. [x] Build the four files; validate the census catches real drift.
2. [x] Document the warden itself + the accumulated drift in CLAUDE.md; register in `/self-improvement/`.
3. [x] Fix the surfaced drift: `environment.yml` aligned to Ruby 3.3 / Node 20 (was 3.2 / 18, stale vs the workflows). The Cloudflare deploy secrets were already documented in the chat-proxy README + the deploy workflow header + (now) CLAUDE.md.
4. [ ] Flip `enforcement` to `soft-gate` and add the gate to required checks once the map is tuned.
