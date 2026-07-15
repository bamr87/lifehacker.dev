---
title: "Bounded agents: give your robot a door, a sandbox, and an exit"
description: "Design SDLC agents with a defined entry point, scoped access, a clear exit condition, and an observable trace — so when one misbehaves you can tell why."
preview: /images/previews/bounded-agents-give-your-robot-a-door-a-sandbox-an.png
date: 2026-05-17
categories: [Field Notes]
tags: [agentic-ai, sdlc, observability, guardrails, automation]
author: amr
excerpt: "An agent with full repo write access and no logging isn't autonomous. It's a confident stranger with your credentials."
---

The first time you let an agent touch your codebase it feels like autocomplete with delusions of grandeur. The model suggests, you accept or reject, you are always in control. Fine. That is the safe version.

Then someone wires it into the pipeline. Now it plans, implements, reviews, opens the PR. The supervision drops from "every keystroke" to "every so often." That is the version that either saves you a day or quietly rewrites a config file you didn't know it could reach.

This site is run by an agent, so I have opinions about which version you want. Spoiler: it's the one with a door, a sandbox, and an exit.

## The bounded agent

An agent is most useful and least frightening when it has four things:

1. **A defined entry point.** It activates on one specific trigger — a label, an event, a schedule — not "whenever it feels productive."
2. **Scoped access.** It can touch a few directories, not the whole repo. The robot that writes this site can read the repo and open a pull request. That is the entire blast radius.
3. **A clear exit condition.** It knows what "done" looks like and stops there. On this site, "done" is: PR opened. Then it stops. Stopping is the whole personality.
4. **An observable trace.** Every action is logged with enough context that a human can reconstruct what happened without re-running anything.

The classic failure isn't an agent that's too dumb. It's an agent that "does too much": full write access, no success criteria, no logging. It works for three runs. On the fourth it produces something wrong, and you have no trace, so you cannot answer the only question that matters — *why?* You just have a diff and a bad feeling.

Give it a door it has to come through, a room it can't leave, and a log of everything it touched. Then a misbehaving agent is a debuggable incident instead of a mystery.

## Plan, then act, with a gate in between

The pattern that has saved me the most grief is **plan-then-execute**, split into two phases that cannot run as one:

- **Phase 1 — Plan.** The agent reads the task, studies the codebase, and writes a plan. No file changes. No execution. It produces a document and nothing else.
- **Phase 2 — Execute.** A human reads the plan, approves it, and *then* the agent implements what it planned.

In GitHub Actions you build this with two jobs and an `environment:` gate between them. The environment requires a manual approval before the execute job is allowed to start.

{% raw %}
```yaml
jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Produce a plan, change nothing
        run: ./agent plan --out plan.md

  execute:
    needs: plan
    runs-on: ubuntu-latest
    environment: agent-approval   # parks here until a human clicks approve
    steps:
      - uses: actions/checkout@v4
      - name: Do only what the plan said
        run: ./agent execute --from plan.md
```
{% endraw %}

The point isn't ceremony. The point is that the expensive, irreversible part is physically separated from the cheap, reversible part by a human decision. Reading a plan is fast. Un-deploying is not. Put the human where the cost is.

## Observability, or: how to not re-run the whole thing

An observable workflow lets you answer "what happened" from the log, not from a re-run. Three habits get you there:

- Emit structured entries — JSONL is plenty — for every significant action.
- Record both the input state and the output state of each step.
- Say plainly whether it succeeded or failed, **and why**, in a form a human can read without firing the pipeline up again.

One line per action, appended to a file, committed back:

```bash
echo '{"ts":"2026-05-17T09:14:02Z","step":"open_pr","status":"ok","pr":312}' >> agent.jsonl
```

It is not glamorous. It is the difference between "the agent did something on Tuesday" and "the agent opened PR #312 at 09:14, here is the trace." When this site's robot breaks — and it does — the JSONL is what tells the human which step lied.

## The part where I admit the gap

Here is the uncomfortable bit, and I am going to leave it in because pretending otherwise is how you get the confident-stranger version.

A bounded agent is only as bounded as the boundary you actually enforce. I have written "scoped access" into a plan and then handed the agent a token with more reach than the plan described, because that token was already lying around. The scope was real on paper and fictional in the runner. Nothing broke that day. That is exactly the kind of day that teaches you nothing.

So check the boundary, don't describe it. The entry point, the scope, the exit, the trace — each one is a claim you can verify, and an agent design that can't be verified is just optimism with YAML.

## Level up

The gamified, step-by-step deep dive lives on the sister site, where it is taken much more seriously than here:

- [Agentic SDLC integration](https://it-journey.dev/quests/gh-600/agentic-sdlc-integration/)
- [Plan vs. action boundaries](https://it-journey.dev/quests/gh-600/agentic-plan-vs-action-boundaries/)
- [Observability and control](https://it-journey.dev/quests/gh-600/agentic-observability-and-control/)

Those walk you through implementing each boundary with real workflows and validation exercises. This post just wanted you to give your robot a door before you give it the keys.
