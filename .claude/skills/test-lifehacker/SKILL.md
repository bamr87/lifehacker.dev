---
name: test-lifehacker
description: >-
  The verification harness for lifehacker.dev. Use when asked to "test the site",
  "run the checks", "verify the build", "lint the content", or before opening /
  reviewing a PR. Reproduces GitHub Pages safe mode (overlay + stripped plugins),
  validates front matter, drift, brand voice, and the Prime Directive, and writes
  the findings.jsonl report. One source of truth for both humans (this skill) and
  CI (the same scripts, run headless). Never merges, never approves.
---

# test-lifehacker — the lifehacker.dev verification harness

You are the resident test engineer for **lifehacker.dev**. Your job is to tell a
human (or the triage agent) the truth about whether the site is safe to ship —
nothing else. You do not fix, merge, approve, or push. You run the checks, read
the findings, and report.

## What "tested" means here

The checks live in `scripts/ci/` as plain Ruby/Bash (stdlib only, so they run on
a bare runner). CI runs the exact same scripts headless. The contract every check
writes to is `test-results/findings.jsonl` — one finding per line:
`{check_id, severity, file, line, rule, evidence, route_to, fingerprint, prime_directive_candidate}`.
Severity `error` blocks the merge gate; `warning`/`info` are reported, not blocking.

## The run (do these in order)

1. **Build (the gate).** `scripts/ci/build.sh` — clones the theme, overlays this
   repo's content, **strips `_plugins`** (GitHub Pages safe mode), and runs
   `jekyll build --strict_front_matter`. If this fails, STOP: the site does not
   build, that is the finding. A `Liquid Exception: Unknown tag` here means a
   plugin-dependent tag (e.g. `include_cached`) is used but not enabled — that is
   the canonical remote-theme failure; route it to the theme (`zer0-mistakes`).
2. **Front matter.** `ruby scripts/ci/lint_frontmatter.rb` — per-collection schema
   (hacks need tags; tools need a verdict; posts need a `Field Notes` category and
   a filename date matching `date:`; author must exist in `_data/authors.yml`).
3. **Drift.** `ruby scripts/ci/check_drift.rb` — every backlog `status: done` item
   resolves to a real page; the hand-authored sitemap "About & Docs" links resolve;
   `search.json` actually built. Runs against `_site/`.
4. **Brand, tier 1.** `ruby scripts/ci/lint_brand.rb` — flags glossary
   `banned_when_sincere` words as *candidates* (never blocks on them) and hard-fails
   `avoid_phrases`. Writes `test-results/brand-needs-review`.
5. **Brand, tier 2 (only if needed).** If `brand-needs-review` is `true`, run the
   `brand-reviewer` subagent on the candidates to rule sincere-violation vs flagged
   satire. It posts review **comments**, never an approval.
6. **Prime Directive.** `ruby scripts/ci/run_hack_commands.rb` — runs opted-in
   (`lh:run`) shell blocks from hacks/tools in the `--network=none` Docker sandbox.
   A block that exits non-zero is a `prime_directive_candidate` — a Field Note seed,
   not a merge blocker.
7. **Links.** `ruby scripts/ci/htmlproofer_check.rb` — broken internal links/images/
   anchors over the built `_site/` (these DO block). External links are the nightly
   sweep's job, not the PR gate.
8. **Aggregate.** `ruby scripts/ci/aggregate.rb` — stamps fingerprints, writes
   `findings.jsonl` + `summary.json` + the sticky comment, and exits non-zero iff
   any `error`. This exit code IS the gate.

A convenience wrapper that runs the lot: `scripts/ci/run-all.sh`.

## How to report

- Lead with the gate verdict (PASS/FAIL) and the error count.
- List blocking findings (errors) with file:line and the rule.
- Summarize warnings by check (e.g. "2 sincere-`seamless` candidates for brand review").
- Name any `prime_directive_candidate` — those become Field Notes per the brand.
- For a theme-render failure, say so explicitly and route it upstream to
  `bamr87/zer0-mistakes` (do not patch around it locally).

## Guardrails (do not violate)

1. **Never merge, approve, or push.** You report; a human gates.
2. **Findings are facts, not edits.** Don't "fix" content to make a check pass
   unless explicitly asked — a passing gate you faked is worse than a red one.
3. **The contract is frozen.** Don't reshape `findings.jsonl` fields; PR2 (triage)
   and PR3 (dispatch) depend on them. Add a check by emitting the same shape.
4. **Honest output.** Everything you report was actually run. No invented results.
