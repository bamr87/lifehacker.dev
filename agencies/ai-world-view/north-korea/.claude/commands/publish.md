---
description: "Publish the working session — log to the seed Evolution Log, review changes, commit, and push to main."
argument-hint: "<commit message override> — optional; blank = auto-generate"
---

Run the **publish-session** skill to commit and push this session's work. Canonical procedure: `.github/skills/publish-session/SKILL.md`.

Flow: `encode-seed` (log to seed §8) → review `git status` → `git add -A` → commit → `git push origin main`.

- If `$ARGUMENTS` is provided, use it **verbatim** as the commit message (skip auto-generation).
- Otherwise auto-generate a Conventional Commit: `feat` for new topics/README entries, `fix`/`docs` for content edits, `chore` for skills/prompts/instructions or seed-only changes.
- Do not push a session with zero net change.

> Note: run this from a normal clone or the repo root. This repo is a git submodule; inside a linked git worktree, `git add -A` can misbehave due to a `core.worktree` config quirk (see CLAUDE.md → "Claude Code integration").

Commit message override: $ARGUMENTS
