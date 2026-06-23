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

## Scheduling fully-autonomous runs (NOT enabled)

Hands-off scheduled runs are designed but **off** by default. To enable, you would
schedule a recurring Claude Code job that runs `grow-lifehacker` and opens a PR —
never auto-merging. Turn it on only when you trust the review gate. When you do,
say so in the Colophon.

## Adapting this for another site

1. Rewrite `_data/brand/*` for your identity and voice.
2. Seed `_data/backlog.yml`.
3. Adapt `.claude/skills/grow-lifehacker/SKILL.md` to your collections.
4. Keep the guardrails — especially no-self-merge.
