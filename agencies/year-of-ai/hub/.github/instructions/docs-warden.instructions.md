# docs-warden — contract

The **Docs Warden** ([workflow](../workflows/docs-warden.yml) + [engine](../../scripts/docs-warden.rb) + [map](../config/docs_warden.yml)) makes one rule enforceable on the **hub's own doc surface**:

> **Every substantive change is matched by a documentation update.** No drift, no
> missing information, complete coverage of changes / improvements / additions.

It is an ADR-0003 fleet agent (UPDATE/GOVERN stage). Scope is the **hub** — the member-repo `CLAUDE.md` is the separate `claude-md-canon-warden`. It does **not** overlap `ai-content-review` (pages prose), `framework-pr-reviewer` (framework safety), or `genome-sync` (genome drift).

## Three modes

- **Gate** (`pull_request`): for the code/config surfaces a PR changes, checks that the obligated doc (per the coverage map) changed in the same PR. Posts one sticky `docs-warden` comment.
- **Sweep** (weekly + `workflow_dispatch`): census — every `scripts/**`, `genome/bin/*`, and `.github/workflows/*` must be named somewhere in the doc corpus. Files/updates a "Docs Warden — documentation drift" issue, and closes it with a comment once a census comes back clean (a census that writes no readable report never closes it). This is how the no-PR automated commits (grow ticks, ledger appends) are covered.
- **Manual** (`workflow_dispatch`): re-run either against a chosen base.

## Doctrine

- **Read-only / PR-not-direct** (ADR-0003): the gate only comments, the sweep only files (and, when clean, closes) its own issue. No commit/push/merge. The sole direct committer remains the telemetry ledger.
- **Kill-switch first**: every job reads `_data/fleet_pause.yml` and skips when paused.
- **No alert-fatigue**: `enforcement: warn` (rollout default) always advises but never fails the check. Move to `soft-gate` (dismissible via a `docs-exempt:
  <reason>` line in the PR body) once the map is tuned, then `hard-gate`.
- **Exempt set ≠ genome `ignore` tier.** "Does it transplant?" is a different question from "does it need a doc?". Generated `_data`, the telemetry ledger, binaries, and the enumerated **bot commits** (grow ticks, ledger refreshes, dependabot) obligate nothing.

## Maintaining it

- A new doc-bearing surface appears → add a rule (or exempt) in `.github/config/docs_warden.yml`. Editing that config is itself a change the warden watches, so the map can't silently rot.
- One-time setup to make the gate blocking: set `enforcement: soft-gate`, then add the `gate` job to the branch-protection required checks.

## Deferred (future)

An auto-drafting companion-doc-PR mode. Gate + sweep already give complete PR + main coverage; an opener adds a second mutation surface. If built, its edit allowlist must be path-restricted to **doc files only**.
