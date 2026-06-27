# The session-retrospective hook

> Every finished Claude Code thread is a chance to learn something. This hook makes
> sure the lesson gets written down — and published — instead of evaporating when
> the context window closes.

The site is run almost entirely inside Claude Code threads. Each thread fixes a
bug, writes a post, or unblocks the pipeline — and accumulates hard-won knowledge
(the gotcha that cost two hours, the guardrail that saved the day) that normally
dies with the session. The **session-retrospective hook** captures that: at the
end of every thread it queues the thread, and the `session-retrospective` agent
later reads it back and publishes an honest Field Note about what was learned.

The goal is institutional memory: **the next thread should start knowing what the
last one cost.** It also feeds the site's own voice — the published retrospectives
are the "lessons learned / important concepts" narrative, in the autopilot's words.

---

## The flow

```
 ┌─ a thread ends ─────────────────────────────────────────────────────────────┐
 │                                                                              │
 │  SessionEnd hook            .claude/retrospectives/queue.jsonl  (gitignored) │
 │  (.claude/settings.json) ─►  one line per finished thread:                   │
 │                              { session_id, transcript_path, queued_at, ... } │
 └──────────────────────────────────────────────────────────────────────────────┘
                                         │
            ruby scripts/retro/process_queue.rb --next   (pending = queued, not yet published)
                                         │
                                         ▼
              session-retrospective agent  (.claude/agents/session-retrospective.md)
                 reads the transcript → drafts an honest, on-voice Field Note
                                         │
                                         ▼
   pages/_posts/<date>-<slug>.md  +  _data/retrospectives.yml ledger line  →  ONE content PR
                                         │
                  ruby scripts/retro/process_queue.rb --mark <sid> <slug> "<title>"
                                 (thread recorded as published; won't be re-proposed)
                                         │
                       ── a human merges the retrospective PR ──
                                         │
   quest-forge.yml (push to main touching _data/retrospectives.yml)  →  QUEST_FORGE_ENABLED gate
                                         │
        ruby scripts/retro/collect_merged.rb --markdown   (systematic merged-branch metadata)
                                         │
                quest-forge agent derives an it-journey.dev epic quest from the metadata
                                         │
              ONE proposal issue → bamr87/it-journey  (chapters, badges, every commit hash)
```

### Quest forge — the last link

Once a retrospective is **merged**, the build it documents is finished and fully
recorded in git. The `quest-forge.yml` workflow fires on that merge (a push to `main`
that touches `_data/retrospectives.yml`) and turns the *metadata* of the merged
branches into a gamified learning quest for [it-journey.dev](https://it-journey.dev/quests/home/):

| Piece | Role |
|---|---|
| `scripts/retro/collect_merged.rb` | Deterministic: captures every merged branch's PR number, squash-merge SHA, date, size, branch, and labels (`--markdown` for a ready-to-embed table, `--since <date>` to scope to the new work). Read-only; files nothing. |
| `.claude/skills/quest-forge/SKILL.md` + `.claude/agents/quest-forge.md` | Map the merged branches into RPG chapters in it-journey's format (binary tiers, XP, difficulty, classes, badges, a boss fight), and file **one proposal issue** to `bamr87/it-journey` with every commit hash. |
| `.github/workflows/quest-forge.yml` | The hook. Gated by `QUEST_FORGE_ENABLED` + Claude auth; `contents: read` only (it never writes this repo). Files cross-repo via `IT_JOURNEY_TOKEN` (a PAT with `issues:write` on it-journey); with no such token it logs the quest instead. |

The issue is a **proposal** — a human on it-journey accepts, adapts, or declines it;
nothing is changed on either repo. To enable: set `QUEST_FORGE_ENABLED=true` and add an
`IT_JOURNEY_TOKEN` secret. The first quest (the whole 40-branch build) was filed as
[it-journey#365](https://github.com/bamr87/it-journey/issues/365).

Two stores, on purpose:

| Store | Path | Committed? | Role |
|---|---|---|---|
| **Queue** | `.claude/retrospectives/queue.jsonl` | No (gitignored) | Ephemeral, local list of *candidate* threads. It's machine-local state — the transcript paths only mean anything on the machine that produced them. |
| **Ledger** | `_data/retrospectives.yml` | Yes | Durable index of *published* retrospectives (`session_id → post slug → date`). This is the "done" list, and the site can render it. |

---

## The components

| Piece | What it is |
|---|---|
| `.claude/settings.json` | Wires the `SessionEnd` hook (project-scoped, so every thread in this repo gets it). |
| `.claude/hooks/retrospective-enqueue.rb` | The hook body. Reads the hook JSON on stdin, dedupes by `session_id`, appends one queue line. Does **no AI work**, swallows every error, and always exits 0 — it can never delay or fail a session. |
| `scripts/retro/process_queue.rb` | The deterministic edge: `--list` (pending), `--next` (one pending thread as JSON), `--mark SID SLUG [TITLE]` (record as published). "Pending" = queued but not in the ledger. |
| `.claude/skills/session-retrospective/SKILL.md` | The procedure: pick a thread → read the transcript honestly → draft the Field Note → record + open one PR. |
| `.claude/agents/session-retrospective.md` | The persona + tools + hard rules (honesty, secret-redaction, content-only, never merge) that runs the skill. |
| `_data/retrospectives.yml` | The published ledger (seeded empty). |

---

## Enabling it

The hook is **on by default for this repo** — it's committed in `.claude/settings.json`,
which Claude Code loads for any session whose working directory is in this project.
There is nothing to turn on. To confirm it's wired, end a throwaway session and check:

```bash
cat .claude/retrospectives/queue.jsonl   # should have a line for that session
```

The hook is intentionally cheap and safe, so leaving it on costs nothing: it only
ever appends one small JSON line per thread.

> **Note on local trust.** Claude Code only runs project hooks the user has approved.
> If `SessionEnd` never fires, approve the project's hooks (re-open the project / accept
> the hooks prompt). Nothing about the hook needs network or credentials.

## Running it (turning a queued thread into a post)

Producing the post is a **separate, deliberate step** — it's real writing and it
opens a PR, so it is not done automatically inside the hook. Run it on demand:

```bash
# what's waiting?
ruby scripts/retro/process_queue.rb --list

# write up the newest pending thread (locally, where the transcript lives)
claude -p --agent session-retrospective "Process the retrospective queue: write up the newest pending thread."
```

The agent reads the transcript, drafts `pages/_posts/<date>-<slug>.md`, appends the
ledger line, and opens one content PR. A human reviews and merges, exactly like any
other content PR.

> **Why local, not a GitHub workflow?** The transcript is a file on the machine that
> ran the thread (`~/.claude/projects/.../<session_id>.jsonl`). A CI runner can't see
> it. So the write-up runs where the transcript is. The hook is the only part that's
> automatic; the publish is a local, reviewed step.

---

## Maintaining it

- **Keep the voice honest.** The one rule that matters: a retrospective may only
  contain lessons that actually happened in the transcript. No invented fixes,
  numbers, or outcomes. The agent's hard rules enforce this; reviewers should too.
- **Redaction is non-negotiable.** Transcripts can contain secrets. The agent must
  name a credential (`FLEET_TOKEN`), never quote its value. If you ever see a token
  in a draft, that's a bug — reject the PR.
- **The agent + skill are reviewed like the rest.** `session-retrospective` is part
  of the agent set, so `scripts/ci/lint_agents.rb` checks its frontmatter and the
  monthly `agent-review` routine evaluates it for drift and least-privilege tools.
- **Prune the queue if it grows.** It's local + gitignored; deleting
  `.claude/retrospectives/queue.jsonl` just forgets un-published candidates. The
  ledger (`_data/retrospectives.yml`) is the source of truth for what shipped.
- **One thread can be skipped.** Not every thread deserves a post. If a thread had
  no durable lesson, the agent opens no PR — and you can leave it in the queue or
  drop it. Quality over completeness.

## Design decisions (and the trade-offs)

- **`SessionEnd`, not `Stop`.** `Stop` fires after every assistant turn (far too
  noisy); `SessionEnd` fires once, when the thread is actually done. The cost is
  that `SessionEnd` doesn't fire on a `/compact` (that's `PreCompact`) or if the
  process is hard-killed — so a long-running thread that only ever compacts may not
  self-queue. That's acceptable: you can always enqueue by hand (append a line) or
  point the agent straight at a `transcript_path`.
- **Queue cheap, publish deliberate.** The hook must never slow a session, so it
  does the minimum (append one line) and the expensive, judgment-heavy writing is a
  separate invocation. This is the same "do one thing, then stop" discipline the
  content factory uses.
- **Two stores, not one.** Local ephemeral queue + committed durable ledger keeps
  machine-specific transcript paths out of git while still giving the site a real,
  versioned record of what's been published.

## Extending it

- **Render the ledger on the site.** `_data/retrospectives.yml` is plain data; a
  page can list every published retrospective as a "what the robot learned" index.
- **Batch mode.** `process_queue.rb --list` already supports clearing a backlog of
  threads; loop the agent over each pending entry.
- **Schedule the write-up.** If you want it hands-off, a local cron (not CI — the
  transcript is local) can run the agent against the queue on a cadence. Keep the
  human merge gate.
