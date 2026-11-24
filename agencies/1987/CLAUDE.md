# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **self-growing, concept-agnostic knowledge base**. It is two things at once:

1. **A knowledge base** about one concept — currently **"the year 1987"** (history, science, arts, society, people).
2. **A reusable framework** that grows *any* knowledge base. Nothing in `.github/` hardcodes 1987; point it at a new subject and it grows a different repo. 1987 is the reference instance, not the framework.

There is **no build system, package manager, or test suite** — the content is hand-and-agent-authored Markdown, and the "commands" are the prompts in `.github/prompts/` (see below). This is its own independent Git repository (remote `bamr87/1987`, default branch `main`); it happens to live under the `bamr87` monorepo's `projects/` tree, but the monorepo's submodule/build conventions do **not** apply here — the rules below do.

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
| `TIMELINE.md`, `index.md`, `<category>/index.md`, `## Related` cross-refs | `build-structure` skill | ❌ generated |
| `README.md` knowledge table rows | `add-topic` / `curator` / `update-readme` | ✅ via skills |
| `<category-slug>/<topic-slug>.md` topic files | `curator` / `deep-dive` | ✅ via skills |

`build-structure` wraps every generated region in `<!-- BEGIN GENERATED: <artifact> ... -->` / `<!-- END GENERATED -->` markers and only rewrites inside them — keep hand-written content outside the markers. It is idempotent: a rerun with no content change must produce no diff (stable ordering).

## The growth loop and delegation hierarchy

The core operation is **one growth tick**, run via `/grow`, which delegates to the **Architect** agent. Pipeline: **Orient → Plan → Execute → Verify → Record → Publish** ([architect.agent.md](.github/agents/architect.agent.md)).

Delegation is strict — respect it when extending agents:
- **Architect** (`[read, search, todo, agent]`) orchestrates only. It does **not** research, write, or publish content itself. It calls `plan-roadmap` to pick 1–3 items, dispatches `content`→Curator, `structure`→`build-structure` skill, `meta`→`/evolve`, then runs `sync-seed`, `encode-seed`, and `publish-session`.
- **Curator** ([curator.agent.md](.github/agents/curator.agent.md)) is the content specialist — research + write. It delegates to the `research`, `add-topic`, and `publish-session` skills.
- **`research` skill writes nothing** — it returns structured facts. Only `add-topic` / `deep-dive` create files.
- No agent pushes to GitHub except through the `publish-session` skill (the publish gate).

`ROADMAP.md` tracks work in **Now / Backlog / Done / Ideas**, each item tagged `content | structure | meta`. The Architect pulls from Now/Backlog; `plan-roadmap` rewrites it each tick.

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

Lower-level skills (`research`, `add-topic`, `build-structure`, `plan-roadmap`, `sync-seed`, `publish-session`) are usually invoked *by* the agents/prompts above rather than directly. The full architecture inventory is `seed.md` §3.

## Claude Code integration (the `.claude/` layer)

The AI tooling originates in `.github/` (GitHub Copilot / VS Code format). A parallel **`.claude/` layer makes the same prompts, agents, and skills work natively in Claude Code** — they are **thin adapters that delegate to the canonical `.github/` files**, so `.github/` stays the single source of truth.

| Claude Code | Mirrors | Notes |
|---|---|---|
| `.claude/commands/*.md` (`/grow`, `/genesis`, `/deep-dive`, `/update-readme`, `/encode-seed`, `/publish`, `/evolve`) | `.github/prompts/*.prompt.md` | Native slash commands; each reads & follows its canonical prompt. |
| `.claude/agents/{architect,curator}.md` | `.github/agents/*.agent.md` | Subagents (spawned via the Task tool). |
| `.claude/skills/<name>/SKILL.md` | `.github/skills/<name>/SKILL.md` | Auto-triggered by `description`; body points to the canonical procedure. |

**Editing rule**: change the canonical `.github/` file; keep the matching `.claude/` adapter's `description` frontmatter in sync (the `/evolve` flow enforces this). Don't fork the procedure into the adapter.

**Execution model** — one Claude Code constraint shapes the design: **subagents cannot spawn subagents**. So delegating orchestration (Architect → Curator) runs in the **main thread via `/grow`**, which spawns the **Curator** subagent for content items. The `architect` subagent still exists for direct use, but when invoked that way it executes content itself rather than sub-delegating.

**Worktree / git caveat**: this repo is a git submodule whose shared config sets `core.worktree`. Inside a *linked git worktree* (e.g. `.claude/worktrees/…`), plain `git status` misreports every tracked file as deleted and `git add -A` is unsafe. Run git from a normal clone, or scope each command: `GIT_WORK_TREE=<worktree-abs-path> git -C <worktree-abs-path> …`. `.claude/worktrees/` and local settings are gitignored.

## Content conventions

Authoritative source: [content.instructions.md](.github/instructions/content.instructions.md) (applies to `**/*.md`). Key rules:

- **Scope & sourcing**: every fact must fall within `concept.scope` and be verified against **≥2 authoritative sources** (one encyclopedic, e.g. Wikipedia/Britannica; one specialist) per `concept.source_strategy`. Skip and note anything that can't be confirmed in-scope.
- **Knowledge table** (`## Notable Events of 1987` in [README.md](README.md)): row format `| <Item> | one-sentence description under 25 words ending in its significance |`. Never duplicate a row — count existing rows first. Link the item cell to its dedicated file when one exists.
- **Dedicated topic file**: create when research yields **4+ distinct facts** or notable significance. Path `<category-slug>/<topic-slug>.md` (slug = lowercase, hyphens). Required frontmatter `title`, `date`, `category`, then `# Title`, **Category** / **Key figures** lines, `## Summary`, `## Significance`, `## Sources` (≥2 links). See [society-economics/black-monday.md](society-economics/black-monday.md) for the canonical shape.
- **Tone**: factual, neutral, encyclopedic, third person — match `concept.conventions.tone`. No editorializing.
- Content belongs to **exactly one** category from `concept.taxonomy`.

When authoring/editing agent files, follow [agents.instructions.md](.github/instructions/agents.instructions.md): minimal tool sets, the required section order (Role → Constraints → Workflow → Output Format), and the orchestrator-delegates-content pattern.

## Publishing

`publish-session` (or `/publish`) is the only sanctioned push path: it runs `encode-seed`, reviews `git status`, `git add -A`, commits, and **pushes to `main`**. Commit messages use **Conventional Commits** — `feat` for new topics/README entries, `fix`/`docs` for content edits, `chore` for skills/prompts/instructions or seed-only changes; a mixed session leads with its most significant change. Do not push without running through this skill, and do not publish a tick that produced zero net change.
