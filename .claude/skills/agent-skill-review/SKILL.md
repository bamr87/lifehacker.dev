---
name: agent-skill-review
description: The routine for reviewing + evaluating the repo's agents and skills — quality, consistency, least-privilege tools, overlap, and drift vs the workflows — and opening one focused improvement PR.
---

# agent-skill-review

The automation runs on a set of **agents** (`.claude/agents/<name>.md` — the persona, tools, hard rules) that delegate to **skills** (`.claude/skills/<name>/SKILL.md` — the procedure). This routine keeps that set sharp. Run it periodically (the `agent-review` workflow) or on demand.

## 1. Inventory + structural check
- List `.claude/agents/*.md` and `.claude/skills/*/SKILL.md`.
- Run `ruby scripts/ci/lint_agents.rb` — fix any structural finding (missing
frontmatter, name≠filename, a workflow `agent:` ref with no agent, a skill dir with no SKILL.md).
- Map each agent to (a) the skill it delegates to and (b) the workflow(s) that
  invoke it (`grep -rn 'agent:' .github/workflows`).

## 2. Evaluate each role
For every agent + its skill, ask:
- **Single, clear role?** No scope creep, no overlap with another agent.
- **Hard rules correct + present?** never merge; content-only / upstream-only as
  appropriate; the honesty rule (no fabricated results); never close a human's issue.
- **Least-privilege tools?** The agent's `tools` (and the workflow's `--tools`
allow-list) grant no more than the role needs. Flag anything that could merge, approve, or touch infra it shouldn't.
- **Current?** The skill's steps match the workflows/scripts as they exist now — no
  stale path, flag, or instruction.
- **Drift?** The invoking workflow's prompt doesn't contradict the agent/skill.

## 3. Improve + report
- Make the **smallest high-value** edits to the agent/skill files only.
- Keep `lint_agents`, the devops audit, and the simulation green.
- Open ONE PR: what you changed and why, plus a short "checked and healthy" list.
  If nothing needs changing, open NO PR — say the set is sound and what you verified.

## Hard rules
- Touch ONLY `.claude/agents/**` and `.claude/skills/**`. Never weaken a guardrail,
  never merge, never edit content/scripts/workflows. One PR per run.
