---
title: "Your Style Guide Belongs in Git as Data, Not a PDF"
description: "A brand style guide nobody can lint is one nobody follows. Put voice, tone, and banned words in version control next to the content they govern."
date: 2026-06-22
categories: [Field Notes]
tags: [content-governance, branding, version-control, automation, linting]
author: amr
excerpt: "A style guide nobody can lint is a style guide nobody follows. Ship it as data, not a PDF."
---

Every brand has a style guide. It lives in a PDF. The PDF lives in a shared
drive. The shared drive has four files named `Brand_Guidelines_FINAL`, and
nobody knows which one is canon, because the person who knew left in 2023.

This is the natural resting state of a style guide: a 40-page document, lovingly
designed, opened exactly twice — once when it was approved, once when a new hire
asked where it was. After that it is a fossil. The writing keeps moving. The PDF
does not.

Here is the take, stated flatly because it is obvious once you say it: **if a
machine can't read your style guide, your team won't either.**

## The PDF is the wrong file format for a rule

A style guide is not a document. It is a set of rules. "We spell it
`lifehacker.dev`, lowercase, one word." "We never call a feature
`game-changing` with a straight face." "Every how-to ends with a verify step."
Those are not paragraphs to admire. They are assertions that are either true of
your content right now or they are not.

A PDF can hold those rules. It cannot *check* them. So the rules sit in the
document, the content drifts away from the document, and the gap between the two
grows silently until someone notices the product name is misspelled on the
pricing page and has been for six months. Nobody broke a rule on purpose. The
rule just had no way to push back.

The fix is not a longer PDF or a sterner meeting. It is to put the rules
somewhere a program can read them, next to the content they govern, and let a
linter do what linters do.

## So we made the style guide a folder

This site keeps its brand in `_data/brand/` — a small tree of YAML the
autopilot reads before it writes a single word. There is an identity file (who
the site is), a voice file (the profiles — the house tone here is
`satire-deadpan`), and a glossary. The glossary is the part that earns its keep.
It is a list of words that are banned, and it looks roughly like this:

```yaml
banned_when_sincere:
  - revolutionary
  - game-changing
  - seamless
  - 10x
  - leverage   # as a verb meaning "use"
  - just       # the dismissive "just do X"
```

The twist, because this is a comedy site, is the `_when_sincere` part: those
words are banned only when used straight. Inside a clearly flagged bit — a fake
infomercial, scare quotes — they are the punchline vocabulary. The rule encodes
not just the word but the *intent*, which is more nuance than a PDF bullet point
has ever managed.

The point is not the specific words. The point is that "don't say
`game-changing`" stopped being advice in a document somebody has to remember and
became a line in a file a program checks. The rule and the enforcement now live
in the same repository as the writing. When the guide changes, the next draft
gets the new rule automatically. When the writing drifts, the lint catches it
before a human has to.

## Three things you get for free once it's data

**It diffs.** A rule change is now a pull request. You can see who tightened the
banned list, when, and why, the same way you see who changed a function. A style
guide that lives in git has a blame view. A PDF has a "last modified" date and a
shrug.

**It travels with the content.** The guide is in the same repo as the posts it
governs. Clone the repo, you have the rules. There is no second system to keep
in sync, because there is no second system.

**It fails loudly.** This is the whole game. A misspelled product name, a banned
hype word used sincerely, a how-to that forgot its verify step — these show up
the way an unused import shows up: flagged, in context, before publish. No
meeting required. No PDF to remember. The guide can't quietly rot while the
writing drifts, because the writing has to pass the guide on the way out.

## The honest caveat

Putting your style guide in version control does not make your team follow it.
It makes the rules *checkable*. Somebody still has to wire the check into the
pipeline and decide what a failed check blocks. A glossary nobody runs is just a
PDF with a worse font.

And a linter only catches what you can express as a rule. "Don't say
`game-changing`" is a clean grep. "Don't be boring" is not. The data file
handles the mechanical 80% — spelling, banned words, structural tells — so the
humans can spend their judgment on the 20% that actually needs a human. That is
the trade, and it is a good one.

But once the mechanical part is data, it is *enforceable*, and enforceable beats
aspirational every single time. Your first style guide can be a PDF. Your tenth
should be a file your tools refuse to merge around.

---

**More on the sister site:** IT-Journey wrote up the serious, full version of
this — the architecture of a `_data/brand/` tree and how a CMS reads it — in its
[branding governance plan](https://github.com/bamr87/it-journey/blob/main/docs/cms/BRANDING_GOVERNANCE_PLAN.md).
Same idea, fewer jokes, more diagrams.
