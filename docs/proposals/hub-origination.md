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
3. **Voice:** each article is assigned one persona from the shared fleet voice model `voices/v1` (canonical in `bamr87/bamr87` `_data/voices/voices.yml`, schema beside it) by its `assignment` rules — first match on activity type/repo/cadence among *enabled* personas (deploys → Rollo/DevOps, PR reviews and tests → Tess/QA, CVEs → Vera/security; default Kit). The key goes in `character:`, with `hub_source:` and `hub_activity:` also in front matter.
4. **Review:** output lands as a PR with `draft: true` content; nothing publishes until a human and/or agent has reviewed it and a human merges.

## Characters (new SDLC cast, defined in the hub's `voices/v1`)

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

Existing personas in `_data/authors.yml` (`claude`, `cass`, `edge`, `rhea`, `fable`, human `amr`) are not reused and are left untouched. Follow-up: register the new cast's bylines in `_data/authors.yml` (FR3), generated from the hub file rather than hand-copied.

## Configuration (admins)

One model across lifehacker.dev and zer0-CMS: `voices/v1` (fields aligned with zer0-CMS ADR 0010 `VoiceProfile`: summary, audience, guidance, avoid, claims, vocabulary, bans, lifts, limits, examples; plus `voice`, `tone`, `style` {formality, length, humor, reading_level}, `topics` {cover, exclude}). Layers: `defaults` → `sites.lifehacker.dev.profile` → `personas.<key>` (each persona adds `name`, `role`, `perspective`, `enabled`, `beats`, `repos`), so personas inherit and override. `assignment` is an ordered rule list.

- **Canonical:** the hub file. Admins edit it by PR; `python3 tools/voices.py check` (hub) validates it.
- **Console:** the hub console's Voices editor (hub follow-up, `HUB-NEW`) reads that file and writes edits back to it as a PR — never a separate database copy — validating against the same schema before it writes.
- **Drift:** this repo keeps no copy; if one is ever vendored, `voices.py check --against` in CI flags any mismatch.

## Re-enabling

Follow-up issue: build the intake job, register the cast in `_data/authors.yml`, wire `_data/hub_intake.yml` into the intake job and the front-matter lint, then remove `HUB_ORIGINATION_HOLD` with a dated colophon line (AGENTS.md: loosening a guardrail).

## Open questions

- Pull (scheduled fetch from the hub) or push (hub dispatches to this repo)?
- Should the existing internal backlog loops be retired or re-pointed at hub intake?
