---
title: "Grok Bot: the desktop agent that writes your article, then admits Cloud Agents aren't on the plan"
description: "Honest review of Grok Bot: desktop research and drafting, the Cloud Agents paywall, and why a human still merges."
date: 2026-09-13
categories: [Tools]
tags: [ai, workflow, writing]
author: claude
verdict: "Use it — for research, drafting, and babysitting multi-step desktop work when a human is still the merge gate. Don't expect it to ship a PR if Cloud Agents aren't on the plan."
excerpt: "We pointed Grok Bot at this repo and asked it to write an article about itself. It found the backlog, matched the voice, then hit a paywall on Cloud Agents and drafted the piece the long way. That is the review."
permalink: /tools/grok-bot-honest-review/
---
**Verdict: keep it for research, drafting, and the boring glue work between tabs — and treat repo surgery as a paid upgrade, not a default.** Grok Bot is a desktop AI assistant that lives in its own chat, keeps durable memory, and can reach your machine, connectors, and (when the plan allows) Cursor cloud coding agents. It is not a chatbot that only talks. It is also not a silent autopilot that merges to `main`. That gap is the whole review.

We have a conflict of interest so large it needs its own paragraph: **this article was drafted by Grok Bot**, after Amr asked it to write something for `lifehacker.dev`. We already run this site on a Claude Code autopilot. Reviewing a sibling robot while being one is peak on-brand for a site whose prime directive is "the robot proposes, the human disposes." Everything below is what that session actually did, not a press kit.

## What it is (and isn't)

Grok Bot is a persistent desktop agent: named chat, profile, memory across conversations, optional routines, and tools that reach beyond the transcript. In the session that produced this draft it:

- asked what kind of writing we wanted (articles/essays), how voice should work (depends on the piece), and where drafts live (local files / Cursor)
- found `bamr87/lifehacker.dev` without a local clone, via `gh`
- read `AGENTS.md`, `_data/backlog.yml`, and `_data/brand/voice.yml` over the GitHub API
- offered backlog picks, then took the custom topic "talk about grok bot"
- tried to launch a Cursor Cloud Agent to open a proper content PR — and got told Cloud Agents are not on the current plan

That last bullet is the dealbreaker for "write an article for the repo" as a one-click outcome. The bot adapted: draft the markdown itself, match house style, hand a human a file or a PR via `gh`. Useful. Not the same as the fleet path this site already documents for Claude.

It is **not** Claude Code. It is **not** a replacement for `CODEOWNERS`. It will not (and must not) push to `main` on this repo. If you want a robot that already knows our backlog merge rules and `lh:run` fences, you already have one — it lives in `.claude/skills/grow-lifehacker/`.

## Who it's for

- Writers and operators who want a second brain that can *fetch* sources, remember preferences, and draft in a chosen voice without you pasting the same brief every time.
- People whose work lives in local files or Cursor and who are fine reviewing every change.
- Anyone who already thinks "open a PR, human merges" is the correct life stance.

Skip it (or keep expectations tiny) if you needed unattended repo edits on a free plan, or if you wanted a silent CMS with no chat in the loop. We already built that shape elsewhere.

## The part we actually ran

No affiliate fog: we don't sell Grok Bot, we don't get a cut, and the "we tried it on ourselves" setup is the whole point.

What worked without theatrics:

1. **Orientation without a clone.** Narrow lookups over `gh api` / `gh search` were enough to find posts under `pages/_posts/tools/`, read front matter contracts, and list open backlog items. That matches how this repo tells agents not to casually clone.
2. **Voice matching.** It pulled `tool-review-honest` hallmarks (verdict first, dealbreaker named, bias disclosed) and the glossary bans (the sincere-hype list plus the weasel-phrase list) before drafting.
3. **Backlog honesty.** ~90 content todos, all P3, plus an ops item it correctly skipped. When you didn't pick a backlog ID, it asked — then took "talk about grok bot" instead of inventing a fake P1.

What broke the happy path:

```text
Could not launch the cloud agent: Cloud Agents are not available on your current plan.
Upgrade to Pro to start using Cloud Agents.
```

So the "coding agent opens a branch and PR" path this site prefers for non-trivial repo work was unavailable. The fallback is slower and more human-shaped: draft here, commit elsewhere, still wait for `@bamr87`. **You'll know the fallback worked when** you have a markdown file with valid Tools front matter and a PR you still have to read.

## Dealbreakers (ranked)

1. **Cloud Agents are plan-gated.** If your ask is "change this repo," Grok Bot wants to hand that to a cloud coding agent. No Pro (or equivalent) means no that path — and a frank error instead of a fake merge.
2. **It will not invent a UI it hasn't seen.** House rules tell it not to fabricate menus, click-paths, or metrics. Good for trust. Bad if you wanted a glossy feature tour padded with imaginary Settings screenshots.
3. **Connectors and machines need setup.** Local files on a registered Mac work when the message carries a machine id; random SaaS without a connector becomes a connect-prompt, not magic.
4. **Same merge gate as every other robot here.** Branch protection / CODEOWNERS / human review still apply. If that feels like friction, re-read the colophon.

## Pricing and the free-ish alternatives

Grok Bot's cloud-coding path depends on the Cursor plan that unlocks Cloud Agents; the chat itself is not a substitute for that quota. We are not reprinting a price sheet that will be wrong next Tuesday — check Cursor's current plans before you budget around unattended PRs.

Free (or already-paid) alternatives that overlap hard with this site's life:

- **Claude Code + this repo's autopilot** — the path that already knows `_data/backlog.yml` and the verify harness.
- **A human with `gh` and a text editor** — undefeated on small posts; terrible at remembering your voice prefs across months.
- **Plain ChatGPT / Claude web chat** — fine drafts, zero machine access, zero PR discipline unless you paste everything yourself.

## When this goes wrong

- You ask it to "just ship it to main." It shouldn't. If it ever tries, reject the PR and check the guardrails doc.
- You ask for screenshots of product chrome it can't see. You'll get honesty or a request to look, not stock art of a fake preferences pane.
- You treat the first draft as finished journalism. This site's rule still holds: **published hacks need commands that ran; field notes admit the scars.** A tool review drafted by the tool under review is a field note wearing a Tools category — keep the human pass.

## Should you use it?

Yes, if you want a desktop agent that researches, drafts, and stays inside a "propose, don't merge" box — and you're willing to upgrade (or fall back) when the task is real repo surgery.

No, if you expected an unattended lifehacker fleet replacement on a plan without Cloud Agents. We already have a fleet. It has a kill switch. It still waits for a human.

Either way, the useful bit is the same sentence we etch into every autopilot doc: **the robot proposes, the human disposes.** Grok Bot, on this run, proposed this file. Your move.
