<!-- kit: governance v0.1.0 -->
# 0002 — Reflow the constitution to one paragraph per line (editorial, no rule change)

- **Status:** proposed
- **Date:** 2026-10-26
- **Proposed by:** loop-tuner agent (AI)
- **Ratified by:** 
- **Affects:** constitution preamble (blockquote) and § 8 list items 1 and 3; formatting only; PRD and feature ids `none`
- **Supersedes:** none
- **Related:** AGENTS.md "Content gates" (one paragraph per line); `scripts/ci/lint_oneline.rb`; `.github/workflows/markdown-oneline.yml`

## Context

The seeded constitution soft-wraps three spots: the preamble blockquote, and § 8 items 1 and 3. That breaks the house rule of one paragraph per line, and both enforcers of that rule are hard gates. On the push of #733 to `main`, `lint_oneline.rb` (inside the required `verify` check) and `markdown-oneline.yml` both went red. Every PR branched from `main` since then inherits the failure. Section 8 allows edits to this file only through an amendment, so the reflow needs this record.

## Amendment

Join each soft-wrapped paragraph onto a single line. The words, order, links and section numbers do not change, and no rule is added, removed or reworded. This is the same transformation `python3 tools/unwrap-prose.py --write` applies.

## Consequences

`ruby scripts/ci/lint_oneline.rb` reports 0 findings again, and `verify` and `markdown-oneline` can go green on `main`. Upstream follow-up: `templates/governance/` in the bamr87/bamr87 hub seeds the same wrapped text into every fleet repo, so that hub template needs the same reflow. The PR that proposes this record flags that follow-up for the hub.
