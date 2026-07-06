# AUTOPILOT.md — operating the lifehacker.dev autopilot

lifehacker.dev is a **headless CMS driven by Claude Code**. This file is the
operator's guide. The reader-facing version lives at
[/docs/autopilot/](https://lifehacker.dev/docs/autopilot/) and
[/about/colophon/](https://lifehacker.dev/about/colophon/).

## TL;DR

A robot (Claude Code) reads this repo, writes content into it, and opens pull
requests. A human reviews and merges. There is no dashboard — the repo **is** the
CMS.

## The data that drives it

| File | Purpose |
|---|---|
| `_data/brand/identity.yml` | Who the site is: mission, pillars, the running joke, the prime directive. |
| `_data/brand/voice.yml` | Voice profiles (`satire-deadpan`, `how-to-practical`, `tool-review-honest`, `meta-confession`) and when to use each. |
| `_data/brand/glossary.yml` | Words banned when used sincerely; the satire word policy. |
| `_data/backlog.yml` | The content queue: `{id, kind, title, brief, voice, priority, status}`. |
| `.claude/skills/grow-lifehacker/SKILL.md` | The instructions the robot follows each run. |

## Running a cycle (assisted mode — current)

From the repo root, in Claude Code:

```
/grow-lifehacker
```

or just ask: *"do an autopilot run"* / *"publish the next backlog item"*. The skill
will:

1. Read the brand + backlog.
2. Pick the highest-priority `status: todo` item (or your named topic).
3. Research it **for real** (run the commands, reproduce the bug).
4. Draft on-voice into the right collection.
5. Build locally (`scripts/preview.sh`), screenshot, verify.
6. Open a PR on a branch and flip the backlog item to `done`. Then stop.

You review the PR and merge. GitHub Pages deploys `main` automatically.

## Guardrails (do not remove)

- **No direct pushes to `main`.** Robot works on branches, opens PRs.
- **No self-merge / no self-approve.** A human merges.
- **No invented commands or output.** Everything shown was run.
- **Honest attribution.** Robot byline = `claude`; human-written = human byline.
- **Bugs go upstream** to `bamr87/zer0-mistakes` (`fix:` prefix, install mode
  "Remote theme (GitHub Pages)").
- **No secrets / no deploy access.**

If you loosen any of these, update [/about/colophon/](https://lifehacker.dev/about/colophon/)
in the same change — in bold, with a date.

## Scheduling fully-autonomous runs (wired, OFF until you flip the variables)

Every loop's cron is wired and **idles behind its `*_ENABLED` repo variable** —
the variable is the single ON switch (`gh variable set <NAME> true`), and the bot
token can't set variables, so a loop can never enable itself. Flip only what you
trust, and add a dated line to the Colophon when you do. The full switch list is
in `docs/CICD.md`. The one exception: `fleet-dispatch.yml` stays schedule-free by
guardrail (audit + simulation both fail if a cron appears there).

## The compounding loop (how each run improves the next)

The framework doesn't just run on a schedule — it **remembers**, so every cycle
starts from what the last one learned. All memory is committed data that reaches
`main` through the same human-reviewed PR gate as everything else:

| Memory | File | Written by | Read by |
|---|---|---|---|
| Improvements ledger | `_data/fleet/improvements.yml` | loop-tuner (one `pending` entry per change, with metric + baseline) | next loop-tuner run (`scripts/devops/verify_improvements.rb` settles each claim: `verified` / `regressed` / still `pending`) |
| Metrics history | `_data/metrics/history.jsonl` | loop-tuner (`loop_metrics.rb --append-history`) | every measure run (trend signals: a tracked metric that worsened since the last snapshot is a regression to hunt) |
| Backlog | `_data/backlog.yml` | humans, explorer gaps, **content-scout** (sister-site it-journey.dev ideas, before the factory), triage promotions | content factory + fleet (starved kinds surface as a loop-tuner signal; `scripts/triage/harvest_ideas.rb` recovers ideas from merged PR descriptions) |
| Published-lessons ledger | `_data/retrospectives.yml` | session-retrospective | retrospective queue (a written-up thread is never re-proposed) |
| Brand accept-ledger | `_data/brand/accepted.yml` | brand-fixer / humans | brand lint (an accepted use never re-flags) |

The cycle: **measure → verify last run's claims → fix the upstream cause →
record the claim + snapshot → PR → human merges → next run verifies.** A change
whose number regresses becomes the next run's top priority; a dead-end hypothesis
is recorded as `abandoned` and never re-tried. That's the ratchet.

## Adapting this for another site

1. Rewrite `_data/brand/*` for your identity and voice.
2. Seed `_data/backlog.yml`.
3. Adapt `.claude/skills/grow-lifehacker/SKILL.md` to your collections.
4. Keep the guardrails — especially no-self-merge.
