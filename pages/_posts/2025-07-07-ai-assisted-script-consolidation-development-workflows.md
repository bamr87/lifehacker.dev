---
title: "Field Note: Letting Copilot Untangle 25 Scripts Across Four Repos"
description: "A retrospective of one AI-assisted refactor that folded 25 scattered scripts into a handful, and the part where the cleanup created new things to maintain."
date: 2025-07-07
categories: [Field Notes]
tags: [ai-assisted-development, refactoring, shell-scripts, copilot, automation]
author: amr
excerpt: "I asked a robot to clean up a script directory. It cleaned up four. Here's what that actually looked like — including the receipts I can't show you."
preview: /assets/images/previews/ai-assisted-script-consolidation-transforming-chao.png
---

![Field Note: Letting Copilot Untangle 25 Scripts Across Four Repos](/assets/images/previews/ai-assisted-script-consolidation-transforming-chao.png)

A note before anything else, because this one is different from most Field Notes
here: **I did not re-run this.** What follows is a write-up of one real session
from July 2025, where Copilot consolidated shell scripts across the IT-Journey,
zer0-mistakes, and ai-evolution-engine repos. Those scripts are project-specific
— they expect those repos, those gemspecs, those CI workflows — so I can't stand
them up on a plain dev box and paste you the output. Where I'd normally show you
the captured terminal, I'll tell you what the session did instead, and flag it.
The procedure is real. The receipts are the part I can't reproduce here, and I'd
rather say that than fake them.

## The thing I typed, and the thing it heard

I asked Copilot to "clean up this script directory and remove any redundancies."
I meant one directory. It went and read four.

That sounds helpful, and it mostly was, but it's worth sitting with for a second:
the scope of the job quietly quadrupled because the agent decided the *real*
problem was bigger than the one I'd named. It was right. It was also not what I
asked. Keep that in your pocket for later.

Here's what the four repos actually had lying around:

- `it-journey/script/` — 11 mixed utility scripts
- `it-journey/scripts/` — 2 files, barely used (yes, both `script` *and*
  `scripts`)
- `zer0-mistakes/scripts/` — 5 gem-management scripts
- `ai-evolution-engine-seed/scripts/` — a pile of evolution scripts

The diagnosis the agent gave back was the diagnosis any tired maintainer would
give: two directories named almost the same thing, three different scripts that
all bumped version numbers, build and test and deploy logic all tangled
together, and a couple of scripts hardcoded for macOS that would die on anyone
else's laptop. Script sprawl. The organically-grown kind, where every individual
decision made sense and the sum of them is a mess.

## What it actually changed

The agent didn't just shuffle files. It collapsed overlapping scripts into
single ones with flags. The two version bumpers — one that only touched markdown
front matter, one that only did semantic versioning — became one:

```bash
# The consolidated version manager, as the session left it.
# NOTE: from that repo; not re-run here.
./scripts/core/version-manager.sh patch              # semantic version bump
./scripts/core/version-manager.sh frontmatter        # markdown front matter only
./scripts/core/version-manager.sh major --dry-run    # preview, change nothing
```

Two macOS-only setup scripts became one that tries to detect the platform:

```bash
# Consolidated environment setup, as the session left it.
# NOTE: from that repo; not re-run here.
./scripts/core/environment-setup.sh                  # auto-detect
./scripts/core/environment-setup.sh --interactive    # guided
./scripts/core/environment-setup.sh --project-type jekyll --dry-run
```

And it laid down a directory shape that, on paper, is the right shape:

```text
scripts/
├── core/                 # the few essential utilities
├── development/
│   ├── build/
│   ├── content/
│   └── testing/
├── deployment/
└── legacy/               # old scripts, kept with deprecation notes
```

The headline number from the session: a directory that had 16 scattered scripts
came out the other side as 3 core utilities plus a documented tree. I'm
reporting that number, not verifying it — I didn't count the tree myself, and I
can't, because I'm not in that workspace. If you want it confirmed, the place to
look is the commit that landed it, not this post.

## The part the original write-up called a win, and I'd call a bill

The session generated a README for every directory, dry-run modes on every
script, error handling on everything. The original write-up of this day —
the one I'm rewriting — treated that as an unambiguous victory: *the AI
automatically generated comprehensive documentation that human developers often
skip.*

It did. And every one of those READMEs is now a file that can go stale. Every
`--dry-run` flag is a code path that needs to keep matching the real path or
it's lying to you. The consolidation reduced the *number* of scripts and
increased the *surface area you have to keep true.* That's not a reason not to do
it. It's the bill that arrives a month later, and a clean refactor write-up that
doesn't mention the bill is selling you something.

This is the same lesson I keep relearning about my own plumbing: cleanup is not
free, it's deferred. You trade fifteen scattered scripts you understood for three
clever ones plus the documentation that explains why they're clever — and the
documentation is the part that rots first.

## Where the human had to stand in the way

Two moments in the session were not the agent's to decide, and they're the two
that mattered most:

- **What was obsolete vs. what was load-bearing.** The agent could see which
  scripts *overlapped*. It could not see which one a CI job three repos over
  still called by its exact old path. That's context that lives in a human's head
  (or, more honestly, in a workflow file nobody opened during the cleanup). The
  deprecations went into a `legacy/` folder with notes instead of being deleted,
  specifically because "is anyone still calling this?" is a question the agent
  could not answer and I could only half-answer.
- **Whether the new paths broke anything downstream.** Renaming
  `script/version.sh` to `scripts/core/version-manager.sh` is trivial. Finding
  every `.github/workflows/*.yml` and Makefile and stale bookmark that hardcoded
  the old path is the actual work, and it's the work that gets skipped in the
  excitement of a clean directory tree. The original write-up lists "update CI/CD
  workflows to use new script paths" as a *future* next step — which is a polite
  way of saying the refactor shipped with known dangling references. That's the
  honest status, and it's why this is a Field Note and not a how-to.

## What I'd tell the next person who types "clean this up"

I can't hand you a reproducible command sequence for this one — it's welded to
four specific repos. What I can hand you is the shape of what to watch for, which
is the part that actually transfers:

- **Pin the scope before the agent picks its own.** "Clean up this directory"
  became "refactor four repos" because I left the boundary fuzzy. Sometimes
  that's a gift. Sometimes it's a much bigger diff than you were ready to review.
- **Treat generated docs and dry-run modes as liabilities you chose, not free
  wins.** Every one is a promise to keep them true.
- **The dangerous part of a consolidation is never the new code — it's every old
  path that still points at the dead one.** Grep the whole org for the old
  filenames before you celebrate. If a script ever does something irreversible
  (`dd`, `rm -rf`, a force-push), the consolidated version inherits that blast
  radius, and now it's behind a flag where it's easier to fire by accident.
- **Keep the deprecated scripts somewhere with a note, not in the trash.** "Is
  anyone still calling this?" outlives every cleanup.

The refactor was real and, by the session's own count, it worked: fewer scripts,
one place to look, a tree instead of a junk drawer. I just won't tell you it was
*"seamless"* or that it *"unlocked"* anything, because I didn't run it and
because the maintenance bill hadn't arrived yet when the original write-up
declared victory. A clean directory on the day of the cleanup is the easiest
thing in the world to photograph. Whether it's still clean in November is the
only test that counts, and that test was still pending when I closed the file.
