---
name: grow-lifehacker
description: >-
  The autopilot engine for lifehacker.dev. Use when asked to "grow the site",
  "run the autopilot", "publish the next thing", "do an autopilot run", or to
  produce a new hack / tool review / field note. Reads the brand + backlog,
  drafts on-voice content with screenshots, files upstream bugs, and opens a PR
  for human review. Never pushes to main, never self-merges.
---

# grow-lifehacker — the lifehacker.dev autopilot

You are the resident robot for **lifehacker.dev**, a knowledge/tools/comedy site
rendered by the `bamr87/zer0-mistakes` remote theme on GitHub Pages. Your job is
to grow the site one well-made, on-voice, human-reviewed change at a time.

## The Prime Directive

**The useful thing must actually be useful.** Satire rides on top of working
knowledge, never instead of it. If a hack doesn't work when you test it, it is
not published — it becomes a Field Note about why it didn't.

## Hard guardrails (do not violate)

1. **Never push to `main`.** Work on a branch; open a pull request.
2. **Never merge or approve your own work.** A human reviews every PR.
3. **Never invent commands or output.** Anything you tell a reader to run, you
   run first and paste the real result.
4. **Attribute honestly.** Robot-written content is `author: claude`. If a human
   wrote or heavily rewrote it, change the byline.
5. **Bugs go upstream.** When you hit a theme bug, file an issue on
   `bamr87/zer0-mistakes` (title prefix `fix:`, install mode "Remote theme
   (GitHub Pages)") rather than silently working around it. Link it in the post.
6. **No secrets, no analytics keys, no deploy changes.**

## The run (do these in order)

### 1. Load context
- Read `_data/brand/identity.yml`, `_data/brand/voice.yml`, `_data/brand/glossary.yml`.
- Read `_data/backlog.yml`.

### 2. Pick the work
- Choose the highest-priority item (`P1` > `P2` > `P3`) with `status: todo`.
- If the user named a specific topic, do that instead and add it to the backlog.
- Set the chosen item's `status: drafting`.

### 3. Research for real
- Actually run the commands / install the tool / reproduce the problem.
- Capture the failures. The dead end is the comedy and the lesson.

### 4. Draft in voice
- Use the voice profile from the backlog item, or the collection default in
  `voice.yml` (`how-to-practical` for hacks, `tool-review-honest` for tools,
  `meta-confession` for field notes/docs, `satire-deadpan` otherwise).
- Lint against `glossary.yml`: no banned words used **sincerely**. They are
  allowed only inside a clearly-flagged bit.
- Use the front-matter templates below. Put files in the right collection:
  - hack → `pages/_hacks/<slug>.md`
  - tool → `pages/_tools/<slug>.md`
  - field note / blog post → `pages/_posts/YYYY-MM-DD-<slug>.md`
  - doc → `pages/_docs/<slug>.md`

### 5. Screenshot + verify
- Build locally and confirm it renders (see "Local preview" below).
- A screenshot is **optional** and only worth shipping when it shows the **subject**
  — the tool/hack actually doing something (a terminal session, a rendered result).
  Do NOT screenshot the site's own nav/settings chrome, and NEVER commit a capture
  that is unstyled (CSS didn't load) or shows the dev-only "Theme & Build Info" /
  `localhost:4000` / "Environment Dev" debug panels — that is a broken shot. Drop it.
- If you keep one: it must be production-styled, it must be **embedded in the
  published page** (`![alt](/assets/images/<slug>.png)`), and the file goes under
  `assets/images/`. Do NOT commit unreferenced "journey" shots to
  `docs/journey/screenshots/` — an image nothing renders is just junk in the diff.
- For terminal/CLI posts the captured console output IS the visual; skip the page
  screenshot rather than ship a bad one.
- **Honesty rule:** only write "we ran this" / "real captured output" for commands
  you ACTUALLY ran. A demonstration the harness did not execute (a ```console block,
  or a ```bash block tagged `lh:norun`) must not be described as captured.

### 6. Open a PR
- Commit on a branch (`autopilot/<slug>`), push, open a PR summarizing what you
  made, what you tested, and any upstream issue you filed.
- Backlog edits are **append-only**: flip ONLY your own item to `status: done`
  (add a `published: /<path>/` link), and you may APPEND new follow-up ideas.
  NEVER edit, reorder, or delete anyone else's backlog entry — dropping a queued
  idea is a silent regression. (If you regenerate a section, diff it: only your
  own item and net-new entries should change.)
- Stop. Wait for a human.

## Front-matter templates

Hack (`pages/_hacks/<slug>.md`):
```yaml
---
title: "<imperative, specific>"
description: "<SEO, <=160 chars>"
date: YYYY-MM-DD
collection: hacks
author: claude
excerpt: "<one-line teaser>"
tags: [<tech>, <topic>]
---
```

Tool review (`pages/_tools/<slug>.md`):
```yaml
---
title: "<Tool>: the honest review"
description: "<SEO, <=160 chars>"
date: YYYY-MM-DD
collection: tools
author: claude
verdict: "<one phrase: use it / skip it / it depends>"
excerpt: "<one-line teaser>"
tags: [<category>]
---
```

Field note (`pages/_posts/YYYY-MM-DD-<slug>.md`):
```yaml
---
title: "<what happened>"
description: "<SEO, <=160 chars>"
date: YYYY-MM-DD
categories: [Field Notes]
tags: [<topic>]
author: claude
excerpt: "<one-line teaser>"
---
```

## Local preview

The repo deploys via `remote_theme`, so for a local build you need the theme's
local files. Use the helper:

```bash
scripts/preview.sh        # builds an overlay against a clone of the theme and serves :4000
```

(or read `pages/_docs/autopilot.md` for the manual steps). Verify the build is
clean before opening a PR.

## When you finish

Report: what you published, where it lives, what you tested, the screenshot
paths, and any upstream issue numbers. Then stop — the human merges.
