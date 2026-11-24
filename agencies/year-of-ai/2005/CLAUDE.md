# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A **static knowledge-base archive about the year 2005** (history, science, arts, society, people), rendered by GitHub Pages. It began as an instance of the self-growing knowledge-base experiment; in June 2026 that framework (seed.md, lifecycle.yml, the `.github/prompts/` playbooks) was consolidated into the **year-of-ai org** — the orchestration now lives in `year-of-ai/year-of-ai.github.io`, and this repo's lineage continued in `year-of-ai/2005-2011`. What remains here is content + Pages config only.

There is **no build system, package manager, or test suite**. The repo is: `_config.yml` (Jekyll/Pages config), `_data/`, `_posts/`, `assets/`, `index.html`, `news.md`, `TIMELINE.md`, and `telemetry/` (the historical growth ledger — append-only record, do not rewrite).

## Working here

- Edits are content edits: Markdown/HTML/YAML. GitHub Pages builds the site; there is no committed local build tooling.
- Do not resurrect framework references (seed.md, lifecycle.yml, `/grow`, `/replant`, etc.) — those files no longer exist here. For the living framework, see the year-of-ai org.
- This is its own independent Git repository (vendored as a submodule of the bamr87/bamr87 dash): commit and push changes **here** first; the hub only bumps its pointer afterwards.
- Conventional Commits (`type(scope): description`); default branch `main`.

> **Note:** the legacy `.claude/` directory (agents/commands/skills from the retired framework) points at the deleted files above and is pending removal.
