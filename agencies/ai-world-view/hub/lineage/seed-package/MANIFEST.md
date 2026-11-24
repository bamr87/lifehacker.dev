# MANIFEST — the portable seed package

The package **is** the framework layer in `.github/` and `.claude/`, plus the two templates and the README in `seed-package/`. This manifest names the exact load-bearing files and what each does, so a new lineage can be planted by copying them and filling the two templates. Everything marked **regenerable** is produced by the framework on the first `/genesis` + `/grow` and should NOT be authored by hand.

> Test of done: a reader with this package, a GitHub org, and two secrets
> (`ANTHROPIC_API_KEY`, `LIFECYCLE_PAT`) can reach a germinated, self-growing first repo
> without touching anything outside this list. See `seed-package/README.md` for the steps.

## A — Package templates (`seed-package/`) — fill these

| File | Role |
|---|---|
| `seed-package/README.md` | Configure-and-launch instructions for a brand-new lineage (org, secrets, first repo, push). |
| `seed-package/seed.template.md` | Minimal `seed.md` — §1 Concept Definition with placeholders + empty §8. Copy to repo root as `seed.md`. Everything else regenerates. |
| `seed-package/lifecycle.template.yml` | Full `policy` block (succession / consolidation / models / distill knobs) + virgin `state`. Copy to repo root as `lifecycle.yml`. |
| `seed-package/MANIFEST.md` | This file. |

## B — Orchestration prompts (`.github/prompts/`) — copy verbatim, concept-agnostic

| File | Role |
|---|---|
| `genesis.prompt.md` | Bootstrap/rebuild a repo for any concept; derives concept from `seed.md` §1 or an argument. |
| `grow.prompt.md` | One growth tick (plan → content+structure → verify → record → publish). The main loop. |
| `deep-dive.prompt.md` | Research one topic in depth → dedicated file + README link. |
| `update-readme.prompt.md` | Bulk-populate knowledge-table rows. |
| `evolve.prompt.md` | Audit/improve the customization layer itself. |
| `encode-seed.prompt.md` | Append a session entry to `seed.md` §8. |
| `publish.prompt.md` | Thin wrapper over `publish-session`. |
| `replant.prompt.md` | Close a generation; plant the successor repo (framework sourced from the canonical driver). |
| `consolidate.prompt.md` | Merge a completed lineage into one range-named repo; archive members. |
| `expand.prompt.md` | Post-consolidation deepening + plant next era's lineage. |
| `distill.prompt.md` | Once-per-lineage frontier-model meta-review → refreshes this package. |

## C — Agents (`.github/agents/`)

| File | Role |
|---|---|
| `architect.agent.md` | Orchestrator: runs one tick end-to-end + Shepherd Mode for mature repos. Delegates content. |
| `curator.agent.md` | Content specialist: research + write. Delegates to research / add-topic. |

## D — Skills (`.github/skills/<name>/SKILL.md`)

| Skill | Role |
|---|---|
| `research` | Returns structured, source-verified facts. Writes nothing. |
| `add-topic` | Creates topic files + README rows from research. |
| `build-structure` | Generates/refreshes indices, TIMELINE, INDEX, cross-refs (idempotent). |
| `plan-roadmap` | Selects the next 1–3 items; maintains `ROADMAP.md`. |
| `sync-seed` | Regenerates `seed.md` §1–7 from live state (Step 0 early-exits when already in sync). |
| `publish-session` | The only sanctioned push path: encode-seed → review → commit → push. |
| `check-lifecycle` | Gate: grow / replant / consolidate / expand / dormant (fast-paths mature repos). |
| `pollinate` | Backward framework propagation member → driver (forward is deterministic — see `scripts/lineage.sh`). |
| `learn` | Per-generation telemetry → minimal prompt edits; records to the learnings ledger. |

## E — Instructions (`.github/instructions/`)

| File | Role |
|---|---|
| `content.instructions.md` | Authoring standards for `**/*.md` content (scope, sourcing, table/file formats, tone). |
| `agents.instructions.md` | Authoring standards for agent files (minimal tools, section order, delegation pattern). |

## F — Automation (`.github/`)

| File | Role |
|---|---|
| `workflows/grow.yml` | Scheduled unattended growth tick (germinates, gates, grows, publishes). Resolves phase/model from lifecycle policy; the once-per-lineage `distill` phase fires only in the canonical driver (`lineage[0]`). Needs `workflow` scope on the PAT to be planted. |
| `workflows/learn.yml` | Off-critical-path learning flywheel. |
| `workflows/telemetry.yml` | Appends per-run telemetry to the ledger. |
| `scripts/lineage.sh` | Deterministic forward pollination + registry reconcile, run before the agent each tick. |

## G — Claude Code adapters (`.claude/`) — thin, delegate to `.github/`

| Path | Role |
|---|---|
| `.claude/commands/*.md` | Native slash-command adapters mirroring `.github/prompts/*`. |
| `.claude/agents/*.md` | Subagent adapters mirroring `.github/agents/*`. |
| `.claude/skills/<name>/SKILL.md` | Skill adapters mirroring `.github/skills/*`. |

Keep each adapter's `description` frontmatter in sync with its canonical `.github/` file; never fork the procedure into the adapter.

## H — Root framework docs — copy verbatim

| File | Role |
|---|---|
| `CLAUDE.md` | Operating guide for the agent in this repo (generated-vs-authored map, delegation rules). |
| `LIFECYCLE.md` | Lineage design (grow → replant → consolidate → expand) and shepherd fallback. |
| `.gitignore` | Excludes `.claude/worktrees/` and local settings. |

## Regenerable (do NOT hand-author — the framework produces these)

`seed.md` §2–7 · `README.md` knowledge table · `ROADMAP.md` · `TIMELINE.md` · `INDEX.md` · `<category>/index.md` · `## Related` cross-refs · `telemetry/*` · all `<category-slug>/<topic-slug>.md` content.
