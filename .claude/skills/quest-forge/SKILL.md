---
name: quest-forge
description: After a retrospective is published, capture the merged-branch metadata of the build it covers and derive an it-journey.dev epic quest (or quest-chapter) from it — filing ONE proposal issue to bamr87/it-journey with the full plan and commit-hash references. Read-only on lifehacker.dev; files nothing here; never merges.
---

# quest-forge — turn a finished build into a gamified quest

The last stage of the retrospective chain. A thread's work has merged and its
retrospective is published; this turns the *metadata* of those merged branches into
an [it-journey.dev](https://it-journey.dev/quests/home/) quest, so the build becomes a
learnable, gamified journey. The issue is a **proposal** — a human on it-journey
accepts, adapts, or declines it.

## 1. Capture the metadata (systematic, deterministic)
- `ruby scripts/retro/collect_merged.rb --markdown` → the full ledger (PR number,
  squash-merge SHA, date, size, branch, title). Scope to the *new* work with
  `--since <date>` — the previous entry's `published` date in
  `_data/retrospectives.yml`. Use all of it on the first/bootstrap run.

## 2. Derive the quest (match it-journey's format)
it-journey gamifies IT learning as RPG quests. Match its conventions:
- **Tiers** (binary levels): 🌱 Apprentice `0000–0011` · ⚔️ Adventurer `0100–0111` ·
  🔥 Warrior `1000–1011` · ⚡ Master `1100–1110` · 👑 Legend `1111`.
- **Difficulty:** 🟢 Easy · 🟡 Medium · 🔴 Hard · ⚔️ Epic. **XP:** 20–150 per quest.
- **Classes:** Software Developer · System Engineer · Security Specialist · Data
  Scientist · Digital Artist · Game Developer. **Types:** main_quest / side_quest / epic_quest.
- **Badges:** e.g. First Pull Request, Bug Slayer, Security Guardian.

Group the merged branches into themed **chapters** (milestones a learner can
reproduce). Each chapter: a tier+level, difficulty, XP, class, the PRs + commit
hashes it maps to, and a concrete "what you learn." Name a **boss fight** from the
hardest bug; award badges. Keep the fantasy-infused but honest tone.

## 3. File ONE proposal issue to it-journey
- `gh issue create --repo bamr87/it-journey --title "⚔️ Epic Quest: …" --label enhancement --label automated --body-file …`
- Include: the premise, a quest-metadata block, the chapter series with hashes, the
  badges, a build plan for maintainers, and the full ledger table.
- Cross-link lifehacker commits as `bamr87/lifehacker.dev@<sha>` and PRs as
  `bamr87/lifehacker.dev#<n>`.
- **Idempotency:** if an open quest issue already covers this build/window, comment an
  update instead of filing a duplicate. If there's no substantial new build since the
  last retrospective, file nothing and say so. If you cannot file cross-repo (no
  it-journey token), print the full issue body to the log instead.

## Hard rules
- **READ-ONLY on lifehacker.dev** — never edit this repo, never merge. Capture
  metadata only; quote real PR numbers and commit hashes (**never invent one**). The
  it-journey issue is a proposal, not a change. ONE issue per run.
