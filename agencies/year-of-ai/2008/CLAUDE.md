# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **self-growing, concept-agnostic knowledge base**. It is two things at once:

1. **A knowledge base** about one concept — currently **"the year 2005"** (history, science, arts, society, people).
2. **A reusable framework** that grows *any* knowledge base. Nothing in `.github/` hardcodes 2005; point it at a new subject and it grows a different repo. 1987 is the reference instance; 2005 is the current instance.

There is **no build system, package manager, or test suite** — the content is hand-and-agent-authored Markdown, and the "commands" are the prompts in `.github/prompts/` (see below). This is its own independent Git repository; the rules below apply, not any parent-monorepo conventions.

## seed.md is the DNA — read it first

[`seed.md`](seed.md) parameterizes *everything*. Every skill, prompt, and agent reads the **Concept Definition** YAML block (section 1) to learn what to grow — `subject`, `scope`, `taxonomy`, `source_strategy`, and `conventions`. **Never hardcode a specific subject (a year, a category) into any agent/skill/prompt or content logic; derive it from the concept.** To retarget the entire framework at a new concept, change `concept.subject` and re-derive `taxonomy` (via `/genesis`), not by editing individual files.

`seed.md` has two zones with **opposite** edit rules:
- **Sections 1–7** (Concept Definition, Identity, Architecture, Content/Structure Inventories, Growth Loop, Rebuild Procedure) are **generated** by the `sync-seed` skill. Do not hand-edit — they are overwritten on every tick to mirror real repo state.
- **Section 8 (Evolution Log)** is **append-only**, written by the `encode-seed` prompt. Never regenerate, reorder, or edit prior entries — it is the genesis record.

## Generated vs. hand-authored files (critical)

Editing a generated file by hand gets silently overwritten on the next growth tick. Know which is which:

| File / region | Maintained by | Hand-edit? |
|---|---|---|
| `seed.md` §1–7 | `sync-seed` skill | ❌ generated |
| `seed.md` §8 Evolution Log | `encode-seed` prompt (append) | append only |
| `ROADMAP.md` | `plan-roadmap` skill | ❌ generated (reconciled each tick) |
| `TIMELINE.md`, `INDEX.md`, `<category>/index.md`, `## Related` cross-refs | `build-structure` skill | ❌ generated |
| `README.md` knowledge table rows | `add-topic` / `curator` / `update-readme` | ✅ via skills |
| `<category-slug>/<topic-slug>.md` topic files | `curator` / `deep-dive` | ✅ via skills |
| `lifecycle.yml` `state` block | `check-lifecycle` / `replant` / `consolidate` | ❌ machine-maintained |
| `lifecycle.yml` `policy` block | hand-tuned | ✅ deliberate knob changes only |
| `telemetry/evolution.jsonl.gz` | `telemetry.yml` workflow (append-only) | ❌ machine-appended; never edit/reorder |
| `telemetry/learnings.jsonl` | `learn` skill (append-only) | ❌ machine-appended; never edit/reorder |

`build-structure` wraps every generated region in `<!-- BEGIN GENERATED: <artifact> ... -->` / `<!-- END GENERATED -->` markers and only rewrites inside them — keep hand-written content outside the markers. It is idempotent: a rerun with no content change must produce no diff (stable ordering).

## The growth loop and delegation hierarchy

The core operation is **one growth tick**, run via `/grow`, which delegates to the **Architect** agent. Pipeline: **Orient → Plan → Execute → Verify → Record → Publish** ([architect.agent.md](.github/agents/architect.agent.md)).

Delegation is strict — respect it when extending agents:
- **Architect** (`[read, search, todo, agent]`) orchestrates only. It does **not** research, write, or publish content itself. It calls `plan-roadmap` to pick 1–3 items, dispatches `content`→Curator, `structure`→`build-structure` skill, `meta`→`/evolve`, then runs `sync-seed`, `encode-seed`, and `publish-session`.
- **Curator** ([curator.agent.md](.github/agents/curator.agent.md)) is the content specialist — research + write. It delegates to the `research`, `add-topic`, and `publish-session` skills.
- **`research` skill writes nothing** — it returns structured facts. Only `add-topic` / `deep-dive` create files.
- No agent pushes to GitHub except through the `publish-session` skill (the publish gate).

`ROADMAP.md` tracks work in **Now / Backlog / Done / Ideas**, each item tagged `content | structure | meta`. The Architect pulls from Now/Backlog; `plan-roadmap` rewrites it each tick.

## The repo lifecycle (grow → replant → consolidate)

Beyond single ticks, each repo lives inside a **lineage** — see [LIFECYCLE.md](LIFECYCLE.md) (design) and [lifecycle.yml](lifecycle.yml) (state). Every tick starts with the `check-lifecycle` skill (pipeline step 0), which counts ticks from seed.md §8 (the source of truth) and gates the run:

- after `replant_after_ticks` (default **3**) growth ticks, `/replant` finalizes this repo as `mature` and spawns a successor repo for the next concept (per `lifecycle.policy.succession.rule`), planting only the framework + carried-forward `lifecycle.yml`;
- when the lineage reaches `consolidate_at_members` (default **7**), `/consolidate` — run from the newest member — merges all members into one range-named repo (e.g. `2005-2011`), preserves every Evolution Log, and archives the members.

Unattended operation runs via the scheduled [`.github/workflows/grow.yml`](.github/workflows/grow.yml), which is planted verbatim into every successor. Never hand-edit `lifecycle.yml`'s `state` block; tune only `policy`.

## Commands (slash commands, not shell scripts)

These run natively as Claude Code slash commands (`.claude/commands/`) — thin adapters over the canonical `.github/prompts/` files. The primary entry points:

| Command | Purpose |
|---|---|
| `/grow [N or targets]` | Run one full autonomous growth tick end-to-end (plan→content+structure→verify→sync→publish). The main loop; safe to run on a schedule or under `/loop`. |
| `/genesis "<concept>"` | Bootstrap (or rebuild) a fresh self-growing repo for **any** subject. Blank = rebuild from existing `seed.md`. This is how you retarget the framework. |
| `/deep-dive "<topic>"` | Research one topic in depth → dedicated `<category-slug>/<topic-slug>.md` file + README link. |
| `/update-readme [topics]` | Bulk-populate knowledge-table rows from a topic list or auto-detected gaps. |
| `/evolve [scope]` | Audit & improve the `.github/` customization layer itself (descriptions, minimal tools, delegation, concept-agnosticism). |
| `/encode-seed` | Append a session entry to `seed.md` §8 Evolution Log. |
| `/publish` | Thin wrapper over the `publish-session` skill (encode-seed → review → commit → push). |
| `/replant [--force\|subject]` | End this repo's growth generation (mark `mature`) and spawn the successor repo for the next concept in the lineage. Normally triggered by the lifecycle gate, not by hand. |
| `/consolidate [--dry-run]` | Merge a completed 7-member lineage into one range-named repo and archive the members. Run from the newest member. |
| `/learn [--window N]` | Per-cycle improvement flywheel (`policy.models.learn`): mine the just-closed generation's telemetry for friction and embed the minimal fixes into the foundational prompts so future cycles run faster/cheaper. Records to `telemetry/learnings.jsonl`; runs off the growth critical path via `.github/workflows/learn.yml`. |
| `/distill [--force]` | One-time lineage meta-review (`policy.models.distill`, default Opus 4.8): analyze all members, improve the cycle, emit the portable `seed-package/` bootstrap kit. Triggered by the lifecycle gate at `distill_at_members` (default 3). |

Lower-level skills (`research`, `add-topic`, `build-structure`, `plan-roadmap`, `sync-seed`, `publish-session`, `check-lifecycle`, `pollinate`, `learn`) are usually invoked *by* the agents/prompts above rather than directly. The full architecture inventory is `seed.md` §3.

**Three-speed learning architecture** — improvements flow through the lineage at three cadences: `pollinate` (mechanical, every tick) propagates framework changes that already exist; `learn` (Sonnet, every generation boundary, off the critical path) turns telemetry friction into embedded prompt edits; `distill` (Opus 4.8, once per lineage milestone) does the deep whole-lineage review → `seed-package/`. Foundational changes made anywhere reach every member repo; per-instance files (content, `seed.md`, `lifecycle.yml`) are never propagated. The append-only `telemetry/learnings.jsonl` ledger records every captured learning so none is re-derived.

## Claude Code integration (the `.claude/` layer)

The AI tooling originates in `.github/` (GitHub Copilot / VS Code format). A parallel **`.claude/` layer makes the same prompts, agents, and skills work natively in Claude Code** — they are **thin adapters that delegate to the canonical `.github/` files**, so `.github/` stays the single source of truth.

| Claude Code | Mirrors | Notes |
|---|---|---|
| `.claude/commands/*.md` (`/grow`, `/genesis`, `/deep-dive`, `/update-readme`, `/encode-seed`, `/publish`, `/evolve`, `/replant`, `/consolidate`) | `.github/prompts/*.prompt.md` | Native slash commands; each reads & follows its canonical prompt. |
| `.claude/agents/{architect,curator}.md` | `.github/agents/*.agent.md` | Subagents (spawned via the Task tool). |
| `.claude/skills/<name>/SKILL.md` | `.github/skills/<name>/SKILL.md` | Auto-triggered by `description`; body points to the canonical procedure. |

**Editing rule**: change the canonical `.github/` file; keep the matching `.claude/` adapter's `description` frontmatter in sync (the `/evolve` flow enforces this). Don't fork the procedure into the adapter.

**Execution model** — one Claude Code constraint shapes the design: **subagents cannot spawn subagents**. So delegating orchestration (Architect → Curator) runs in the **main thread via `/grow`**, which spawns the **Curator** subagent for content items. The `architect` subagent still exists for direct use, but when invoked that way it executes content itself rather than sub-delegating.

**Worktree / git caveat**: this repo may run inside a linked git worktree (e.g. `.claude/worktrees/…`), where plain `git status` misreports every tracked file as deleted and `git add -A` is unsafe. Run git from a normal clone, or scope each command: `GIT_WORK_TREE=<worktree-abs-path> git -C <worktree-abs-path> …`. `.claude/worktrees/` and local settings are gitignored.

## Content conventions

Authoritative source: [content.instructions.md](.github/instructions/content.instructions.md) (applies to `**/*.md`). Key rules:

- **Scope & sourcing**: every fact must fall within `concept.scope` and be verified against **≥2 authoritative sources** (one encyclopedic, e.g. Wikipedia/Britannica; one specialist) per `concept.source_strategy`. Skip and note anything that can't be confirmed in-scope.
- **Knowledge table** (`## Notable Events of 2005` in [README.md](README.md)): row format `| <Item> | one-sentence description under 25 words ending in its significance |`. Never duplicate a row — count existing rows first. Link the item cell to its dedicated file when one exists.
- **Dedicated topic file**: create when research yields **4+ distinct facts** or notable significance. Path `<category-slug>/<topic-slug>.md` (slug = lowercase, hyphens). Required frontmatter `title`, `date`, `category`, then `# Title`, **Category** / **Key figures** lines, `## Summary`, `## Significance`, `## Sources` (≥2 links).
- **Tone**: factual, neutral, encyclopedic, third person — match `concept.conventions.tone`. No editorializing.
- Content belongs to **exactly one** category from `concept.taxonomy`.

When authoring/editing agent files, follow [agents.instructions.md](.github/instructions/agents.instructions.md): minimal tool sets, the required section order (Role → Constraints → Workflow → Output Format), and the orchestrator-delegates-content pattern.

## Publishing

`publish-session` (or `/publish`) is the only sanctioned push path: it runs `encode-seed`, reviews `git status`, `git add -A`, commits, and **pushes to `main`**. Commit messages use **Conventional Commits** — `feat` for new topics/README entries, `fix`/`docs` for content edits, `chore` for skills/prompts/instructions or seed-only changes; a mixed session leads with its most significant change. Do not push without running through this skill, and do not publish a tick that produced zero net change.

**Framework PRs vs. the autonomous loop**: growth ticks push straight to `main` while human/agent framework work goes through PRs — so framework PRs must **not** carry machine-maintained files (`lifecycle.yml` state, `seed.md` §1–7, `ROADMAP.md`, generated indices); let the owning skills reconcile those on `main`. Use **one short-lived branch per change, cut fresh from `main` and deleted after its squash-merge** — reusing a branch across squash-merges re-diffs all its old changes against `main` and manufactures conflicts. Sync the branch with `main` immediately before merging any PR that sat open across a tick.

## Governance

Read [`docs/constitution.md`](docs/constitution.md) before changing anything: it is the highest-precedence rule set here and wins over this file when they disagree. It changes only through a numbered record in [`docs/amendments/`](docs/amendments/), ratified by the maintainer merging the PR; agents propose, never merge. Every user-facing feature has a stable id in [`features/features.yml`](features/features.yml) with `status`, location and the PRD requirement ids it serves; the PRD's "Feature catalog" block is generated from it (`python3 <bamr87/bamr87>/tools/governance_lint.py prd-sync . --write`; check with `… check .`). Never hand-edit that block or `CHANGELOG.md`.
