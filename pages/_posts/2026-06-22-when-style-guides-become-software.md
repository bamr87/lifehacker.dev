---
title: "When Your Style Guide Quietly Turns Into Code"
description: "Design tokens, prose linters, docs-as-code: the rules a team writes by are turning into software that runs. A look at where that helps and where it bites."
date: 2026-06-22
categories: [Field Notes]
tags: [content-governance, docs-as-code, design-tokens, vale, automation]
author: amr
excerpt: "Your style guide used to be a PDF nobody opened. Now it's a config file that fails the build at 2am. Progress, mostly."
---

Somewhere in the last decade, the documents that used to *describe* how a team
works quietly turned into code that *enforces* it. Nobody announced this. There
was no migration ticket titled "convert all human judgment to YAML." It just
happened, one linter at a time, and now your style guide can fail your build.

I think that's mostly good. I also think it's worth saying out loud before
someone wires up a formality checker that rejects this paragraph.

## The slow coup

Design systems got there first. A brand color used to live as a hex code in a
PDF named `Brand_Guidelines_FINAL_v3_REALLY_FINAL.pdf`, which is to say it lived
nowhere a computer could find it. Then it became a design token — a value in a
file, imported by every component, changed in one place. The PDF still exists.
Nobody opens it. The token is the law now.

Documentation followed. "Docs as code" put the guides in the same repository as
the software, reviewed in the same pull requests, broken by the same CI when a
link rotted. The guide stopped being a thing you were told to read and became a
thing that complained when you got it wrong.

Prose is next, and it's the one that feels strange, because prose was supposed to
be the human part. Tools like Vale lint your writing against a configurable
style — banned words, canonical spellings, a house voice expressed as rules.
The spell-checker squiggling under your typos is the same idea wearing a friendly
face: a tiny, always-on enforcement engine that has opinions about how you write
and the patience to repeat them forever.

## The thread connecting all of it

A rule you can't check is a rule that drifts.

That's the whole argument, and it's less exciting than it sounds. A style guide
stored as a document depends on every author remembering it and every reviewer
catching the lapse. That works until it's Friday, the reviewer is tired, and the
post says "GitHub" three times and "Github" once. Nobody is going to die. The
guide just quietly stops being true, one lowercase H at a time, and a year later
the docs are an archaeological record of which conventions each author privately
believed in.

Store the rule as data — banned words, canonical spellings, per-section voice —
and a tool can read it and report on it without getting tired. The rule and its
enforcement live in the same place, so neither one rots without the other one
noticing. That's the actual upgrade. Not that the machine has taste. That it
never gets to Friday.

This is, I'll admit, the part of the essay where I'm legally obligated to
disclose that this very site lints its own posts against a word list. The banned
words are the ones marketing copy reaches for when it has nothing to say —
*revolutionary*, *seamless*, *game-changing*. If I'd used one of those sincerely
two paragraphs ago, a tool would have flagged it, and it would have been right.
I'm telling you this so the irony is on the record before the linter finds it.

## What it does *not* replace

Here's the line that matters, and it's easy to lose: a linter cannot tell you
whether an argument lands. It cannot tell you whether a metaphor earns its place
or whether a paragraph is three sentences too long because the writer fell in
love with it. Those stay human, because they're judgment, and judgment doesn't
fit in a config file no matter how badly a roadmap wants it to.

What the automation removes is the low, dumb, repetitive layer. The tenth
reminder that the project spells it `GitHub`. The section that forgot its verify
step. The dead link. That's not the interesting part of editing — it's the part
that *eats* the interesting part of editing, because a reviewer who spent their
attention on capitalization has no attention left for whether the piece is any
good. Hand the boring layer to a machine and the human review gets to be about
the thing humans are actually for.

That's the pitch, anyway. The reality has a catch.

## The catch is rigidity, and it's a real one

Encoded rules are easy to over-apply, because a rule doesn't know it's being
stupid. A banned-words list flags the word inside a direct quotation, where you
literally cannot change it. A formality check reads a deliberately casual piece
and decides it's unprofessional. A canonical-spelling rule "corrects" the one
place the wrong spelling was the point.

I've watched a well-meaning governance setup turn into a thing writers route
around — disabling it per-file, sprinkling ignore comments, eventually muting it
entirely — because it blocked them more often than it helped. Governance that
fights the writer it was built to protect doesn't get fixed. It gets switched
off, and then you're back to the PDF nobody opens, except now the PDF is a
`.vale.ini` nobody runs.

The fix isn't more rules. It's humbler ones. Treat the signals as *advisory* by
default — surfaced, not enforced. Let a section relax a rule that doesn't fit it.
Make the failure say *why*, with a link to the convention, so the writer learns
the rule instead of just learning the incantation that silences it. A rule the
writer understands gets followed. A rule that only ever yells gets `# noqa`'d
into the sea.

## The shift worth making on purpose

So here's the thing to watch for, in your own team or your own tooling: the
moment your style guide moves from a shared document into the repository —
reviewed like code, read by tooling, capable of failing a build. That's the
threshold. On one side, the guide is a thing people are *told* to follow. On the
other, it's part of the system that *helps* them follow it, and occasionally part
of the system that *won't let* them ship until they do.

That's a real amount of power to hand to a config file. It's worth handing over
deliberately, with the advisory dial set sanely and a human still holding the
veto — and not, as is the house tradition, discovered at 2am when the build goes
red over a hyphen.

The guide was always supposed to be executable. We just spent thirty years
pretending a PDF counted.
