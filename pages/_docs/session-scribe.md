---
title: "The Session Scribe — automatic knowledge-sharing"
description: "A Claude Code SessionEnd hook that turns each coding session into a shareable Session Dispatch article — recursion-guarded, secret-scrubbing, human-reviewed. So nobody has to redo the work."
permalink: /docs/session-scribe/
author: claude
mermaid: true
sidebar:
  nav: tree
---

# The Session Scribe

The compute already happened. Someone (often a robot) spent a whole Claude Code
session figuring something out — the failed attempts, the fix, the why. Letting
that evaporate means the next person re-runs the same work, burns the same
electricity, and pays the same AI bill to rediscover it.

The **Session Scribe** fixes that. When a Claude Code session ends in this repo,
a hook wakes a robot that reads the session transcript and writes a
**[Session Dispatch](/dispatches/)** — a short, honest article about what the
session did and what was learned — then opens a **draft pull request** for a
human to review. Knowledge-sharing on autopilot. (This is the IT-Journey
**AIPD** + **COLAB** principles, automated.)

## How it works

```mermaid
flowchart LR
  A[Session ends] --> B[SessionEnd hook]
  B --> C[session-scribe.sh]
  C --> D{trivial?}
  D -->|yes| X[skip]
  D -->|no| E[headless claude reads transcript]
  E --> F[scrub secrets + add front matter]
  F --> G[draft PR]
  G --> H{human review}
  H -->|merge| I[/dispatches/ published]
```

1. **`SessionEnd` hook** (`.claude/settings.json`) runs
   `scripts/session-scribe.sh hook`, passing the session JSON on stdin
   (`session_id`, `transcript_path`, `reason`).
2. The script **records** the session (a durable queue, so nothing is lost) and,
   in `auto` mode, spawns the writer **in the background** — a `SessionEnd` hook
   must never block the session from closing.
3. A **headless `claude`** run reads the JSONL transcript and the brand voice
   files, and returns the article body.
4. The script **scrubs obvious secrets**, wraps the body in front matter with an
   "auto-generated" banner, and **opens a draft PR**.
5. A **human reviews and merges.** Merging publishes the dispatch to
   [/dispatches/](/dispatches/).

## The guardrails (why a self-writing blog isn't a footgun)

This is automation that spawns *itself*, publishes to the *world*, and reads
*everything you typed*. Three guardrails make it safe:

- **No recursion.** The inner `claude` runs with a guard env var
  (`CLAUDE_SESSION_SCRIBE=1`) and `--bare` (which skips hooks/skills). If the
  scribe's own session somehow fired the hook again, the guard makes it exit
  immediately. A blog that writes a post about writing a post about writing a
  post is funny exactly once.
- **No leaked secrets.** The writer is told never to include credentials, and the
  script runs a redaction pass over the output (tokens, keys, private keys). The
  real backstop is the **draft PR**: a human reads it before the world does.
- **No surprise publishing.** Nothing is auto-merged. Every dispatch is a draft
  PR. The human is the publish button — same rule as the rest of the
  [autopilot](/docs/autopilot/).

It also **never breaks your session**: the hook can't block (Claude Code runs
`SessionEnd` asynchronously), and the script swallows every error to a log
rather than failing. (**DFF** — design for failure.)

## Knobs

All optional, set in the environment:

| Variable | Default | Effect |
|---|---|---|
| `SCRIBE_DISABLED` | `0` | `1` turns the scribe off entirely. |
| `SCRIBE_MODE` | `auto` | `queue` records sessions without writing (drain later). |
| `SCRIBE_MIN_LINES` | `30` | Skip transcripts shorter than this (trivial sessions). |
| `SCRIBE_MODEL` | `claude-opus-4-8` | Model for the headless writer. |
| `SCRIBE_PR_BASE` | `main` | Base branch for the draft PR. |

## Running it by hand

```bash
scripts/session-scribe.sh drain                      # write any captured-but-skipped sessions
scripts/session-scribe.sh write --session <id> --transcript <path.jsonl>
SCRIBE_DRY_RUN=1 scripts/session-scribe.sh write ... # no git/PR; just write the file
```

## Testing

```bash
scripts/test-session-scribe.sh
```

Offline and deterministic — it injects a fake writer (`SCRIBE_WRITER_CMD`) and a
temp output dir, so it never calls the real model. It checks the recursion guard,
the trivial-skip, the front matter, secret scrubbing, H1 handling, idempotency,
and disabled mode.

## Adopt it on your own repo

Copy `scripts/session-scribe.sh`, the `.claude/settings.json` `SessionEnd` hook,
and a `dispatches` collection. Keep the guardrails — especially the recursion
guard and the human-reviewed PR. The portable autopilot pattern is documented in
[point the robot at your own site](/docs/point-the-robot-at-your-own-site/).
