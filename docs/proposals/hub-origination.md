# Hub-originated publishing (LHD-NEW, planned)

**Status:** proposed · **Governance:** bamr87/bamr87 constitution § 23 (amendment `writing-chronicle`, bamr87/bamr87#663) · **Related:** bamr87/bamr87#662

## Why

lifehacker.dev's autonomous loops (`content-factory`, `weekly-epic`, `wire-scout`, plus `auto-merge`) generate and ship articles from their own backlog. Under § 23 the hub's writing section (`bamr87/bamr87` `pages/posts/`) is the origination point: it chronicles fleet activity daily, and lifehacker.dev becomes a synthesized, curated news agency built from that activity, written for a wider audience in its existing characters' voices.

## What this PR does

- Holds autonomous publishing in code: `HUB_ORIGINATION_HOLD: "true"` in the gate of the four workflows above makes them idle even if their `*_ENABLED` repo variable is turned on. No history, content, settings, secrets or variables change.
- Records the intake contract and voice assignment in `_data/hub_intake.yml` (data only; nothing reads it yet).

## Intake contract

1. **Source:** reviewed entries in `bamr87/bamr87` `pages/posts/` (daily `YYYY-MM-DD-chronicle.md` and other posts). Unreviewed hub drafts are never eligible (§ 23 rule 4).
2. **Synthesis:** an intake job reads eligible entries, groups them by activity (commits, pushes, deploys, PRs, agent runs, AI prompting, security, QA) and drafts articles for a general audience. Satire in the framing, never the facts (press charter); secrets and tokens are never carried over.
3. **Voice:** each article is assigned one character from the new SDLC cast in `_data/hub_intake.yml` by the `assignment` rules (first match on activity type, e.g. deploys → Rollo/DevOps, PR reviews and tests → Tess/QA, CVEs → Vera/security; default Kit); the key goes in `character:`, with `hub_source:` (hub path/URL) and `hub_activity:` also in front matter.
4. **Review:** output lands as a PR with `draft: true` content; nothing publishes until a human and/or agent has reviewed it and a human merges.

## Characters (new SDLC cast)

| Key | Name | SDLC role | Writes about |
| --- | --- | --- | --- |
| `margo` | Margo Backlog | Product | issues, roadmap, PRD, amendments, governance |
| `juno` | Juno Pixelwell | Design / UX | UI, design system, accessibility, console UX |
| `kit` | Kit Commitson | Development | commits, pushes, refactors, agent runs (default) |
| `tess` | Tess Assert | QA / testing | tests, PR reviews, regressions, evals |
| `rollo` | Rollo Shipley | DevOps / release | deploys, releases, pipelines, infra, fleet ops |
| `vera` | Vera Vault | Security | CVEs, Dependabot, secrets hygiene, permissions |
| `lux` | Lux Telemetry | Data / observability | metrics, AI usage and cost, incidents, AI prompting |
| `quill` | Quill Readme | Docs | docs, changelogs, runbooks, weekly roundups |

Existing personas in `_data/authors.yml` (`claude`, `cass`, `edge`, `rhea`, `fable`, human `amr`) are not reused and are left untouched. Follow-up: register the new cast in `_data/authors.yml` (bylines must resolve there per FR3) with voice profiles in `_data/brand/voice.yml`.

## Re-enabling

Follow-up issue: build the intake job, register the cast in `_data/authors.yml`, wire `_data/hub_intake.yml` into the intake job and the front-matter lint, then remove `HUB_ORIGINATION_HOLD` with a dated colophon line (AGENTS.md: loosening a guardrail).

## Open questions

- Pull (scheduled fetch from the hub) or push (hub dispatches to this repo)?
- Should the existing internal backlog loops be retired or re-pointed at hub intake?
