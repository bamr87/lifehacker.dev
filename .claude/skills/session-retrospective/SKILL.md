---
name: session-retrospective
description: Turn a finished Claude Code thread into one honest, on-voice Field Note for the site — the narrative, the hard-won lessons, the durable concepts — then record it in the ledger. Reads the transcript, redacts every secret, opens one content PR, never merges.
---

# session-retrospective — write down what the thread learned

Every finished thread is a candidate for a retrospective: a short Field Note, in the autopilot's own voice, about what was attempted, what broke, and what is worth remembering. The SessionEnd hook queues the threads; this is how you turn one into a published post. The point is institutional memory — so the *next* thread starts knowing what this one cost.

## 1. Pick the thread
- `ruby scripts/retro/process_queue.rb --next` → the newest pending thread
(`session_id` + `transcript_path`). If it prints "No pending retrospectives", stop and say so — open no PR.

## 2. Read the thread honestly
- Read the transcript at `transcript_path` (a `.jsonl` of the session). Skim for
the ARC, not every token: what the human asked, what you actually did, the turning points (an error → the fix), the honest failures, the few durable lessons.
- Extract only what really happened. **Never invent a lesson, a number, a fix, or
an outcome.** If you can't verify it from the transcript, it does not go in — the same honesty rule the content factory runs on.

## 3. Draft the Field Note
- One file: `pages/_posts/field-notes/<YYYY-MM-DD>-<slug>.md` (date = today, the
  publish date). Field notes are the `field-notes` news section now (issue #337).
- Frontmatter like the other field notes: `title`, `description`, `date`,
  `categories: [Field Notes]`, `tags`, `author: claude`, `excerpt`. Tag from the
  field-notes pill vocabulary (`automation ai jekyll ci-cd satire business
  engineering career`) — a retrospective is usually `career`; no one-off tags.
- Voice: first person, honest, specific, a little self-aware — mirror
`pages/_posts/field-notes/2026-06-22-i-hired-a-robot-to-write-this-website.md`. Read the brand files first (`_data/brand/voice.yml`, `glossary.yml`) and run `ruby scripts/ci/lint_brand.rb` before you open the PR.
- A structure that works: what the shift was → the part that surprised you → the
  concrete lessons (name the real gotcha) → what you want the next thread to know.
- **Redaction (hard):** never quote a secret, token, key, or full credential, even
  if it appears in the transcript. Refer to it by name (`FLEET_TOKEN`), never value.

## 4. Record + open the PR
- `ruby scripts/retro/process_queue.rb --mark <session_id> <post-slug> "<title>"`
  appends to `_data/retrospectives.yml` so the thread is not re-proposed.
- Verify the build (`bundle exec jekyll build`, or the safe-mode build) and that
  `lint_brand` is clean.
- Open ONE PR (branch `retro/<date>-<slug>`): the post + the ledger line. Title it
  `retro: <thread, in a phrase>`. Then stop.

## Hard rules
- Content + ledger only: `pages/_posts/field-notes/**` and `_data/retrospectives.yml`. Never
touch infra, scripts, or workflows. **Never fabricate.** **Redact every secret.** One PR per run. **Never merge.**
