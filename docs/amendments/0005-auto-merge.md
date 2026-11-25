<!-- kit: governance v0.1.0 -->
# 0005 — Auto-merge may publish the autopilot's own content

- **Status:** proposed
- **Date:** 2026-11-25
- **Proposed by:** agent (Claude Code), at the maintainer's request (2026-11-25: "switch them all on.")
- **Ratified by:**
- **Affects:** constitution § 1 mission 3 and the paragraph after the missions; PRD § 1.1 (the same text); `.github/workflows/auto-merge.yml`; AGENTS.md; `/about/colophon/`
- **Supersedes:** none (amends mission 3 from amendment 0003)
- **Related:** hub amendment `lifehacker-auto-merge` (bamr87/bamr87 constitution § 23.6), hub constitution § 12.2; #800 (the hold); constitution § 9.5

## Context

Mission 3 says "a human remains the only merge gate" and "no change reaches the apex domain lifehacker.dev without a human merge". `auto-merge.yml` has existed since June 2026 to merge the bots' own green content and triage pull requests. It was held in code by `HUB_ORIGINATION_HOLD` from #800 on, and every switch was off from 2026-10-31.

On 2026-11-25 the maintainer asked for every switch to be on, auto-merge included, and `AUTO_MERGE_ENABLED` was set to `true` that day. With the hold lifted, auto-merge publishes a bot's pull request when all of these hold:

- its label is `auto:content`, `source/triage-bot` or `source/ai-usage-bot`, and it has no `needs-human` label
- it is not a draft
- every check is green
- it is mergeable
- the smuggle guard finds only content and data

Two fixes come with it:

- **The guard now classifies each changed file on its own.** Before, a diff of `pages/` plus `agencies/` read as plain `content`, so an agency change (which § 9.5 reserves for a human merge) could have been merged along with it.
- **It merges with a merge commit pinned to the head the guard judged** (`gh pr merge --merge --match-head-commit`) instead of squashing (hub constitution § 12.2).

No human reads the piece before it ships. Its review is the build and content harness on every pull request; one editorial pass by the content-reviewer agent (the pipeline's `content-review` job, when a content pull request opens, which may commit small edits and comments its judgment calls); and the AI brand reviewer when the brand lint raises a candidate. Commits pushed after the pull request opens get the harness again, not a second editorial pass.

## Amendment

In constitution § 1, and identically in the PRD, replace mission 3 with:

> 3. **Run as an open headless CMS: an autopilot drafts, reviews and ships content, CI enforces quality, and a human holds the merge gate, delegating it to green checks for the autopilot's own content and data while auto-merge is on.** Brand, queues, ledgers and site health live in the repository as data; nothing else reaches the apex domain lifehacker.dev without a human merge.

In the paragraph after the missions, replace "and quality gates with a human-only merge to main" with "and quality gates in front of every merge to main".

## Consequences

- Every other change still waits for a human: agents, dependencies, workflows, scripts, configuration, agencies, docs and the feature catalog. Agents still never push, approve or merge (§ 2).
- `gh variable set AUTO_MERGE_ENABLED -R bamr87/lifehacker.dev --body false` returns every merge to a human at once, without another amendment.
- Mistakes in auto-merged content are caught after publishing: by a reader using the Improve button, by the site explorer, or by a later fix. The colophon says so.
- The hub's amendment `lifehacker-auto-merge` makes the same change to hub constitution § 23.6 and must merge first. Merging this pull request then ratifies this amendment. An agent never merges it.
