---
name: Publish Session
description: "Publish the current working session to GitHub. Use when: finishing a session and ready to commit and push changes; wanting to log session work to seed.md before committing; pushing new topics, articles, README updates, or instruction changes. Runs encode-seed → git status review → commit → push in one command."
argument-hint: "Optional commit message (e.g. 'feat: add Sugar Act deep dive'). Leave blank to auto-generate from changed files."
agent: agent
tools: [read, edit, execute]
---

Load and follow the full procedure in [publish-session](../skills/publish-session/SKILL.md).

If an argument was provided, pass it as the commit message override to Step 4 of the skill (skip generating a message).
