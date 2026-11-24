---
name: publish-session
description: "Publish the current working session — log to the seed Evolution Log, review changes, commit, and push to main. Use when finishing a session and ready to commit and push new topics, articles, README updates, or instruction changes. Concept-agnostic. Runs encode-seed → git status review → commit → push in one orchestrated flow."
---

# Publish Session (Claude Code adapter)

Canonical procedure: **`.github/skills/publish-session/SKILL.md`**. Read that file and follow it exactly.

Summary:
1. **Log the session** — run `/encode-seed` to append a structured entry to `seed.md` section 8 (Evolution Log). Do not touch sections 1–7.
2. **Review changes** — `git status`; group Modified / New / Deleted; confirm before proceeding if unexpected files appear.
3. **Stage** — `git add -A` (no `--force`, no bypassing `.gitignore`).
4. **Commit message** — use the provided override verbatim, else auto-generate a Conventional Commit (`feat` new topics/README rows; `fix`/`docs` content edits; `chore` skills/prompts/instructions or seed-only).
5. **Commit** then **`git push origin main`**; report the commit SHA.

> Environment note: this repo is a git submodule. In a normal clone this flow is correct. Inside a *linked git worktree*, `git add -A` can misbehave because the submodule's shared config sets `core.worktree` — see CLAUDE.md → "Claude Code integration" for the safe per-command `GIT_WORK_TREE` override.
