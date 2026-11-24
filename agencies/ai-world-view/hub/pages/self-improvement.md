---
title: Self-Improvement — the fleet that watches the fleet
description: >-
  The routine AI-agent fleet that reviews, fixes, and evolves the
  ai-world-view hub and framework — a continuously self-improving system.
keywords:
  - ai agent fleet
  - autonomous self-improvement
  - self-monitoring ai system
  - telemetry ledger
  - fleet health
layout: default
permalink: /self-improvement/
sidebar:
  nav: hub
lastmod: 2026-07-28
---

# Self-Improvement — the fleet that watches the fleet

The hub grows the knowledge bases ([AI Orchestration]({{ '/orchestration/' | relative_url }}))
and spawns new countries on its own. But growing isn't enough — a system that writes itself also needs to **watch and improve itself**. This page identifies the routine **agent fleet** that does that: a meta-layer whose job is the health and continuous improvement of the growth system itself.

The fleet was designed in the reference implementation (the `year-of-ai` hub, from which this org was planted), and this hub arrived with its safety scaffolding and watchers **already built**: the kill-switch, the write serializer, the evolution ledger, and the daily watchers all run here today. The framework's own self-improvement mechanisms — the grow-adjacent prompts (`distill`, `evolve`) and skills (`learn`, `pollinate`) — exist in `lineage/framework/` but are **dormant** — built for the old per-repo model and not yet wired into the central engine. The fleet below wires those up and fills the remaining gaps, forming a closed loop.

## The continuous-improvement loop

<figure class="my-4 text-center">
<svg viewBox="0 0 1024 250" role="img" aria-label="A continuous loop of eight stages: Observe (telemetry ledger), Detect (health, pages, secret watchers), Gate (prepublish + framework-PR review), Learn (learn-flywheel), Align (tick-clock + canon wardens), Fix (hygiene + rollback), Evolve (tier-ROI + meta-audit), and Govern (cost ceiling + kill-switch). The output of Govern returns to Observe, closing the loop." style="max-width:100%;height:auto;font-family:var(--bs-font-sans-serif,system-ui,sans-serif)">
  <defs>
    <marker id="sl" markerWidth="9" markerHeight="9" refX="7" refY="3" orient="auto"><path d="M0,0 L7,3 L0,6 Z" fill="var(--bs-secondary-color,#6c757d)"/></marker>
  </defs>
  <!-- 8 stage nodes -->
  <!-- n1 OBSERVE -->
  <rect x="12" y="48" width="104" height="92" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="1.5"/>
  <text x="64" y="74" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="12.5" font-weight="700">OBSERVE</text>
  <text x="64" y="100" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">ledger-</text>
  <text x="64" y="112" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">collector</text>
  <!-- n2 DETECT -->
  <rect x="140" y="48" width="104" height="92" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="1.5"/>
  <text x="192" y="74" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="12.5" font-weight="700">DETECT</text>
  <text x="192" y="100" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">health · pages</text>
  <text x="192" y="112" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">· secret watch</text>
  <!-- n3 GATE (accent) -->
  <rect x="268" y="48" width="104" height="92" rx="9" fill="var(--bs-primary,#0d6efd)"/>
  <text x="320" y="74" text-anchor="middle" fill="#fff" font-size="12.5" font-weight="700">GATE</text>
  <text x="320" y="100" text-anchor="middle" fill="#fff" font-size="8.5">prepublish ·</text>
  <text x="320" y="112" text-anchor="middle" fill="#fff" font-size="8.5">fw-review</text>
  <!-- n4 LEARN -->
  <rect x="396" y="48" width="104" height="92" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="1.5"/>
  <text x="448" y="74" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="12.5" font-weight="700">LEARN</text>
  <text x="448" y="100" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">learn-</text>
  <text x="448" y="112" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">flywheel</text>
  <!-- n5 ALIGN -->
  <rect x="524" y="48" width="104" height="92" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="1.5"/>
  <text x="576" y="74" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="12.5" font-weight="700">ALIGN</text>
  <text x="576" y="100" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">tick-clock ·</text>
  <text x="576" y="112" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">canon wardens</text>
  <!-- n6 FIX -->
  <rect x="652" y="48" width="104" height="92" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="1.5"/>
  <text x="704" y="74" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="12.5" font-weight="700">FIX</text>
  <text x="704" y="100" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">hygiene ·</text>
  <text x="704" y="112" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">rollback</text>
  <!-- n7 EVOLVE -->
  <rect x="780" y="48" width="104" height="92" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="1.5"/>
  <text x="832" y="74" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="12.5" font-weight="700">EVOLVE</text>
  <text x="832" y="100" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">tier-ROI ·</text>
  <text x="832" y="112" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="8.5">meta-audit</text>
  <!-- n8 GOVERN (accent) -->
  <rect x="908" y="48" width="104" height="92" rx="9" fill="var(--bs-warning,#ffc107)"/>
  <text x="960" y="74" text-anchor="middle" fill="#000" font-size="12.5" font-weight="700">GOVERN</text>
  <text x="960" y="100" text-anchor="middle" fill="#000" font-size="8.5">cost ceiling</text>
  <text x="960" y="112" text-anchor="middle" fill="#000" font-size="8.5">· kill-switch</text>
  <!-- forward arrows -->
  <line x1="116" y1="94" x2="139" y2="94" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="1.8" marker-end="url(#sl)"/>
  <line x1="244" y1="94" x2="267" y2="94" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="1.8" marker-end="url(#sl)"/>
  <line x1="372" y1="94" x2="395" y2="94" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="1.8" marker-end="url(#sl)"/>
  <line x1="500" y1="94" x2="523" y2="94" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="1.8" marker-end="url(#sl)"/>
  <line x1="628" y1="94" x2="651" y2="94" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="1.8" marker-end="url(#sl)"/>
  <line x1="756" y1="94" x2="779" y2="94" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="1.8" marker-end="url(#sl)"/>
  <line x1="884" y1="94" x2="907" y2="94" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="1.8" marker-end="url(#sl)"/>
  <!-- return arrow GOVERN -> OBSERVE -->
  <path d="M960,140 L960,196 L64,196 L64,141" fill="none" stroke="var(--bs-success,#198754)" stroke-width="1.8" stroke-dasharray="5 4" marker-end="url(#sl)"/>
  <text x="512" y="214" text-anchor="middle" fill="var(--bs-success,#198754)" font-size="11">every cycle feeds the next — learnings make each future tick cheaper &amp; better</text>
</svg>
<figcaption class="figure-caption mt-2">Each grow tick feeds telemetry into the loop; what the fleet learns is written
back into the canonical framework, so the next tick across all repos improves.</figcaption>
</figure>

<div class="alert alert-secondary d-flex align-items-start gap-2" role="alert">
  <i class="bi bi-shield-lock-fill mt-1"></i>
  <div><strong>Operating doctrine.</strong> Every agent that mutates content,
repos, or secrets opens a <strong>pull request</strong> — never a direct commit (the lone exception is the append-only telemetry ledger). Four highest-risk mutations (model swaps, model-tier changes, content rollbacks, deletions &amp; permission changes) require a <strong>human gate</strong>. A global
  <strong>kill-switch</strong> halts all mutation on demand, and writes are
  serialized so no two agents race the same branch.</div>
</div>

## The fleet (25 agents)

Each agent is tagged by **origin** — <span class="badge text-bg-success">net-new</span> (build it), <span class="badge text-bg-info">rewire</span> (wire up a dormant framework mechanism), or <span class="badge text-bg-secondary">upgrade</span> (make an existing deterministic tool agentic). Priorities **P0 → P2**. Agents marked **Built** run in this hub today; the rest are the designed roadmap.

### Monitor / Observe

| Agent | Pri | Origin | What it does |
|---|---|---|---|
| `telemetry-ledger-collector` | P0 | upgrade | **Built** — appends one record per grow run to the hub evolution ledger (`telemetry/evolution.jsonl`); the P0 keystone every learn/cost/monitor agent depends on |
| `fleet-pause-killswitch` | P0 | net-new | **Built** — `_data/fleet_pause.yml`, the single global halt every dispatching/mutating workflow reads first |
| `pages-deploy-sentinel` | P0 | net-new | **Built** — hourly read-only check that each member repo's Pages build succeeded + the live site responds; files one sticky issue. The sole liveness signal a rollback agent keys off |
| `secret-expiry-watch` | P0 | net-new | **Built** — daily single-attempt probe of `CLAUDE_CODE_OAUTH_TOKEN` + `LIFECYCLE_PAT` ahead of the growth window; files/auto-closes one issue (catches a dead token before ticks burn) |
| `fleet-health-watch` | P1 | net-new | **Built** — daily read-only digest over the evolution ledger: error rate, cost trend, per-member last-grow, stalls; one auto-closing issue (the DETECT half of the loop) |
| `fleet-cost-governor` | P2 | net-new | Cost rail on the orchestrator — pre-flight ceiling + budget writer |
| `lineage-state-report` | P2 | net-new | Single human pane of glass; a pure aggregator over the other signals |

### Review

| Agent | Pri | Origin | What it does |
|---|---|---|---|
| `prepublish-gate` | P0 | net-new | The biggest hole: an inline gate that builds + fact/link/tone-checks a tick before it publishes |
| `framework-pr-reviewer` | P0 | upgrade | **Built** — safety for the self-modification path; gates every framework PR |
| `injection-surface-auditor` | P1 | net-new | Audits the workflow-injection surface (untrusted input into prompts; tools-with-write) |
| `published-content-auditor` | P2 | upgrade | Audits published content for post-publish drift — internal-link rot, self-contradiction, orphans |
| `world-view-consistency-auditor` | P2 | net-new | Checks that the published sites stay true to the concept: the model's own world view, with no web-sourced material creeping in |

### Fix

| Agent | Pri | Origin | What it does |
|---|---|---|---|
| `repo-write-serializer` | P0 | rewire | **Built (convention)** — the `repo-write-<repo>` concurrency lock `grow-lineage` holds + the documented framework/policy single-PR groups; future writers join them so no two race a branch |
| `repo-hygiene-warden` | P1 | net-new | Enforces the invariant that a country repo holds only content + config + .claude + telemetry |
| `model-id-drift-checker` | P1 | upgrade | Keeps the hardcoded model IDs in policy.yml from going stale or deprecated |
| `supply-chain-security-warden` | P1 | net-new | Extends the CodeQL scan (**built**) with the Dependabot / action-pinning audit on secret-bearing workflows |
| `tick-rollback-sentinel` | P2 | net-new | Bounded, human-initiated withdrawal of a bad publish — the rollback the system lacks |

### Align

| Agent | Pri | Origin | What it does |
|---|---|---|---|
| `ledger-tickclock-auditor` | P1 | rewire | Validates the tick-clock / Evolution Log against reality via a CI check gate |

### Update

| Agent | Pri | Origin | What it does |
|---|---|---|---|
| `docs-warden` | P1 | net-new | **Built** — gates every PR + sweeps `main` so every change is matched by a doc update on the hub's own doc surface |
| `claude-md-canon-warden` | P1 | rewire | Re-syncs each repo's drifted (stale old-model) CLAUDE.md back to canon |
| `adapter-canon-aligner` | P2 | rewire | The backward `.claude/`-to-canon diff — keeps the framework converging, not fragmenting |

### Learn

| Agent | Pri | Origin | What it does |
|---|---|---|---|
| `learn-flywheel` | P1 | rewire | Mines a stabilized telemetry window and embeds friction-removing edits into the canonical framework |

### Evolve

| Agent | Pri | Origin | What it does |
|---|---|---|---|
| `tier-roi-auditor` | P2 | net-new | Makes model-tier selection data-driven instead of fixed-by-intuition |
| `recovery-rehearsal-agent` | P2 | net-new | Exercises the re-seed / rebuild path in an isolated scratch org (the untested recovery story) |
| `fleet-meta-auditor` | P2 | net-new | Watches the watchers — audits the agent fleet itself, with an external dead-man's-switch |

## Defects the design surfaced (fixed here by construction)

The fleet design was run against the reference implementation and surfaced real defects in the old per-repo model. This hub was **planted after** those findings, so the fixes arrived with it — each one is worth guarding regardless:

- **No evolution ledger** — per-tick telemetry used to be discarded after 14 days; here `telemetry-ledger.yml` appends every run to `telemetry/evolution.jsonl`.
- **No supply-chain security** — here `codeql.yml` scans the hub; the fuller Dependabot / action-pinning audit remains on the roadmap.
- **A bypassable review** — the old `learn.yml` force-merged its own PR; here framework changes are gated by `framework-pr-reviewer.yml`.
- **A publish race** on each member repo's `main` — here every writer joins the `repo-write-<repo>` concurrency group.
- **A prompt-injection surface** — here the engine's gate job validates dispatch inputs before anything reaches a model prompt.
- **`CLAUDE.md` drift** — member repos can still drift from canon between re-syncs; the canon warden that closes this is on the roadmap.

## Rollout order

1. **Phase 0 — safety scaffolding** (before any mutating agent): the kill-switch, the write serializer, the gated framework PR review. **Planted built.**
2. **Phase 1 — keystone + gates + canaries:** the telemetry ledger collector, then the secret / Pages / health watchers. **Planted built**; the inline prepublish gate remains open.
3. **Phase 2 — the loops:** the learn flywheel and the align / fix wardens.
4. **Phase 3 — slow structural, economic & meta:** tier-ROI, cost governor, content & consistency auditors, recovery rehearsal, and the fleet meta-auditor.

## Full detail

The complete fleet — every agent's trigger, cadence, model tier, inputs, outputs, guardrails, and the closed-loop rationale — is recorded in [**ADR-0003**](https://github.com/year-of-ai/year-of-ai.github.io/blob/main/lineage/decisions/ADR-0003-self-improving-agent-fleet.md) in the reference `year-of-ai` hub, from which this org was planted. It is the synthesized output of a 14-agent design workflow (4 architect lenses → synthesis → 3 adversarial critics → finalize). Or browse the
[content hub]({{ '/hub/' | relative_url }}) to see the published output those
agents protect.
