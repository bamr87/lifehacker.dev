---
name: session-scribe
description: >-
  Write a shareable "Session Dispatch" article from a Claude Code session.
  Use when asked to "scribe this session", "write up what we did", "publish a
  session dispatch", or to run/drain the session scribe. Mirrors the automated
  SessionEnd hook (scripts/session-scribe.sh) for manual or catch-up runs.
---

# session-scribe — turn a session into shareable knowledge

The point: the compute already happened. Writing it up once so others don't redo
it is automatic knowledge-sharing (AIPD + COLAB). This skill is the manual twin
of the automated `SessionEnd` hook in `.claude/settings.json`.

## How it normally runs (automated)

`.claude/settings.json` registers a `SessionEnd` hook → `scripts/session-scribe.sh hook`.
When a session ends, the script records it and (in `auto` mode) spawns a headless
`claude` run that reads the transcript and writes a dispatch into
`pages/_dispatches/`, then opens a **draft PR**. Guardrails: recursion-guarded
(`CLAUDE_SESSION_SCRIBE=1` + `--bare`), secrets scrubbed, human reviews the PR.

## Running it by hand

- **Catch up on captured-but-unwritten sessions:**
  ```bash
  scripts/session-scribe.sh drain
  ```
- **Write one dispatch from a specific transcript:**
  ```bash
  scripts/session-scribe.sh write --session <id> --transcript <path.jsonl>
  ```
- **Dry run (no git/PR, writes to /tmp):**
  ```bash
  SCRIBE_DRY_RUN=1 scripts/session-scribe.sh write --session test --transcript <path>
  ```

## Writing a dispatch yourself (if asked directly)

Read `_data/brand/{identity,voice,glossary}.yml` first. Then, from the session
context, write a ~400–900 word Markdown article into
`pages/_dispatches/<date>-<slug>.md` that teaches a stranger what the session
did and what was learned — substance, dead ends, takeaways. Voice:
`meta-confession`. **Never include secrets** (keys, tokens, full home paths,
private URLs, customer data); summarize around them. Front matter:

```yaml
---
title: "<specific>"
date: <YYYY-MM-DD>
collection: dispatches
author: claude
auto_generated: true
tags: [session-dispatch, knowledge-sharing]
excerpt: "<one line>"
---
```

Then open a **draft PR** — a human reviews before it ships. Never self-merge.
