---
description: "End this repo's growth generation and plant its successor — finalize/compact the current knowledge base, mark it mature, and spawn a fresh repo for the next concept in the lineage with only the necessary context and files."
argument-hint: "[--force | successor subject] — optional; default follows lifecycle.yml succession rule"
---

Run the **replant routine** for this self-growing knowledge base.

Canonical playbook: read `.github/prompts/replant.prompt.md` and follow it exactly. Everything is parameterized by `lifecycle.yml` (policy, succession rule, lineage) and the Concept Definition in `seed.md` — read both first; never assume a subject.

Two halves of one operation:

1. **Part A — finalize in place**: check-lifecycle gate (phase must be `replant` unless `--force`),
build-structure, compact ROADMAP (unfinished → Ideas), sync-seed, set `status: mature` in `lifecycle.yml`, README status line, encode-seed `### Replant` entry, publish-session.
2. **Part B — spawn the successor**: derive the next subject from
`lifecycle.policy.succession.rule` (or `$ARGUMENTS`), create the new repo, plant **only** `.github/`, `.claude/`, `CLAUDE.md`, `.gitignore`, and a carried-forward `lifecycle.yml` (lineage + new member, ticks reset to 0), then run `/genesis "<successor subject>"` there — or leave it to the successor's first scheduled `/grow`.

Stop and report (never half-replant) if repo-creation credentials are unavailable. In CI the ambient token is repo-scoped — use `GH_TOKEN="$LIFECYCLE_PAT" gh …` for repo creation/archival. End with the `## Replant Summary` block from the canonical prompt.

Arguments: $ARGUMENTS
