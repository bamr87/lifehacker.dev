---
title: AI Orchestration — how the network grows itself
description: >-
  How the year-of-ai hub orchestrates a federated network of self-growing
  knowledge bases that research and write themselves, one tick at a time.
keywords:
  - ai orchestration
  - self-growing knowledge bases
  - growth engine
  - model escalation
  - year of ai network
layout: default
permalink: /orchestration/
sidebar:
  nav: hub
lastmod: 2026-07-28
---

# AI Orchestration

This organization is a **federated network of self-growing knowledge bases** — one repository per year (1776, 1777, 1778, the 2005–2011 lineage, …). Each one researches and writes its own encyclopedic content, one daily *tick* at a time, and publishes its own GitHub Pages site. **This hub is the brain that drives them all.** It holds every year's concept, the growth policy, and the agent toolkit; it decides what grows, how, and when; and it presents the result.

This page documents the whole model, the growth process, and the strategy.

<div class="alert alert-info d-flex align-items-start gap-2" role="alert">
  <i class="bi bi-info-circle-fill mt-1"></i>
  <div><strong>In one sentence:</strong> a scheduled hub clones each year repo,
runs a three-model AI escalation (Haiku drafts → Sonnet expands → Opus polishes) to write new content, records the growth in a central seed, and publishes only the finished content back to the year's own site — forever.</div>
</div>

## 1 · The model — one hub, many living repos

Growth is **centralized**. The hub owns *what grows, how, and when*; the year repos own *only their content and their published site*. Nothing that grows a repo lives in the repo — it lives here, so there is a single source of truth and a single place to schedule, throttle, or evolve the whole network.

<figure class="my-4 text-center">
<svg viewBox="0 0 760 430" role="img" aria-label="The hub holds seeds, policy, framework, and workflows. It dispatches a growth tick to each of ten year repositories, which hold only content, a Pages config, thin .claude adapters, and telemetry. Each year repo publishes its own GitHub Pages site, and its seed Evolution Log flows back to the hub." style="max-width:100%;height:auto;font-family:var(--bs-font-sans-serif,system-ui,sans-serif)">
  <defs>
    <marker id="ar1" markerWidth="9" markerHeight="9" refX="7" refY="3" orient="auto">
      <path d="M0,0 L7,3 L0,6 Z" fill="var(--bs-secondary-color,#6c757d)"/>
    </marker>
    <marker id="ar1b" markerWidth="9" markerHeight="9" refX="7" refY="3" orient="auto">
      <path d="M0,0 L7,3 L0,6 Z" fill="var(--bs-success,#198754)"/>
    </marker>
  </defs>

  <!-- THE HUB -->
  <rect x="24" y="60" width="232" height="320" rx="10" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-primary,#0d6efd)" stroke-width="2"/>
  <rect x="24" y="60" width="232" height="32" rx="10" fill="var(--bs-primary,#0d6efd)"/>
  <rect x="24" y="76" width="232" height="16" fill="var(--bs-primary,#0d6efd)"/>
  <text x="140" y="82" text-anchor="middle" fill="#fff" font-size="15" font-weight="700">THE HUB</text>
  <text x="140" y="112" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">year-of-ai.github.io</text>
  <text x="44" y="146" fill="var(--bs-body-color,#212529)" font-size="12.5"><tspan font-weight="600">lineage/seeds/</tspan> — concept + tick clock</text>
  <text x="44" y="176" fill="var(--bs-body-color,#212529)" font-size="12.5"><tspan font-weight="600">lineage/policy.yml</tspan> — models, cadence</text>
  <text x="44" y="206" fill="var(--bs-body-color,#212529)" font-size="12.5"><tspan font-weight="600">lineage/framework/</tspan> — toolkit</text>
  <text x="44" y="236" fill="var(--bs-body-color,#212529)" font-size="12.5"><tspan font-weight="600">orchestrate.yml</tspan> — scheduler</text>
  <text x="44" y="266" fill="var(--bs-body-color,#212529)" font-size="12.5"><tspan font-weight="600">grow-lineage.yml</tspan> — engine</text>
  <text x="44" y="300" fill="var(--bs-secondary-color,#6c757d)" font-size="11.5" font-style="italic">presents /hub/ · /lineage/</text>
  <text x="44" y="320" fill="var(--bs-secondary-color,#6c757d)" font-size="11.5" font-style="italic">this /orchestration/ page</text>

  <!-- YEAR REPO -->
  <rect x="320" y="96" width="216" height="232" rx="10" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="2"/>
  <rect x="320" y="96" width="216" height="32" rx="10" fill="var(--bs-secondary-color,#6c757d)"/>
  <rect x="320" y="112" width="216" height="16" fill="var(--bs-secondary-color,#6c757d)"/>
  <text x="428" y="118" text-anchor="middle" fill="#fff" font-size="14" font-weight="700">YEAR REPO &#215;10</text>
  <text x="338" y="160" fill="var(--bs-body-color,#212529)" font-size="12.5"><tspan font-weight="600">content/</tspan> — articles, INDEX</text>
  <text x="338" y="190" fill="var(--bs-body-color,#212529)" font-size="12.5"><tspan font-weight="600">_config.yml</tspan> — Pages config</text>
  <text x="338" y="220" fill="var(--bs-body-color,#212529)" font-size="12.5"><tspan font-weight="600">.claude/</tspan> — thin adapters</text>
  <text x="338" y="250" fill="var(--bs-body-color,#212529)" font-size="12.5"><tspan font-weight="600">telemetry/</tspan> — run records</text>
  <text x="338" y="296" fill="var(--bs-secondary-color,#6c757d)" font-size="11.5" font-style="italic">no seed, no workflows —</text>
  <text x="338" y="313" fill="var(--bs-secondary-color,#6c757d)" font-size="11.5" font-style="italic">just content + site</text>

  <!-- PAGES -->
  <rect x="600" y="150" width="136" height="124" rx="10" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-success,#198754)" stroke-width="2"/>
  <text x="668" y="200" text-anchor="middle" fill="var(--bs-success,#198754)" font-size="26"><tspan font-family="sans-serif">&#127760;</tspan></text>
  <text x="668" y="230" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="13" font-weight="600">GitHub Pages</text>
  <text x="668" y="250" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">live site / year</text>

  <!-- arrows -->
  <line x1="256" y1="150" x2="316" y2="150" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="2" marker-end="url(#ar1)"/>
  <text x="286" y="140" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">&#9312; grow</text>
  <line x1="536" y1="200" x2="596" y2="200" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="2" marker-end="url(#ar1)"/>
  <text x="566" y="190" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">&#9314; publish</text>
  <path d="M360,328 C360,392 230,392 158,384" fill="none" stroke="var(--bs-success,#198754)" stroke-width="2" stroke-dasharray="5 4" marker-end="url(#ar1b)"/>
  <text x="300" y="408" text-anchor="middle" fill="var(--bs-success,#198754)" font-size="11">&#9313; seed §8 (tick log) returns to the hub</text>
</svg>
<figcaption class="figure-caption mt-2">The hub grows each year repo, the repo publishes its own site, and the
record of what grew flows back to the hub.</figcaption>
</figure>

| | The hub (`year-of-ai.github.io`) | Each year repo |
|---|---|---|
| **Holds** | seeds, growth policy, canonical framework, the two workflows | content, `_config.yml`, `.claude/` adapters, `telemetry/` |
| **Role** | decides *what / how / when*; schedules and presents | the *product* — encyclopedic content + a live Pages site |
| **Scheduling** | sole scheduler (one daily cron for the whole org) | none — never self-schedules |
| **Source of truth** | the seed and the toolkit | its own published content |

## 2 · The process — anatomy of a growth tick

A *tick* is one unit of growth. The hub runs the same pipeline for every repo: schedule → prepare → a three-model escalation → record → publish. The three AI passes share one working tree, so each builds on the last one's drafts.

<figure class="my-4 text-center">
<svg viewBox="0 0 820 300" role="img" aria-label="The growth tick pipeline: a daily schedule dispatches a tick; the engine checks out the year repo and stages its seed and framework; a three-tier escalation runs Haiku then Sonnet then Opus; the seed is persisted and hub files stripped; finished content and telemetry are published to the year repo." style="max-width:100%;height:auto;font-family:var(--bs-font-sans-serif,system-ui,sans-serif)">
  <defs>
    <marker id="ar2" markerWidth="9" markerHeight="9" refX="7" refY="3" orient="auto">
      <path d="M0,0 L7,3 L0,6 Z" fill="var(--bs-secondary-color,#6c757d)"/>
    </marker>
  </defs>

  <!-- Phase: Schedule -->
  <rect x="14" y="100" width="128" height="96" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="1.5"/>
  <text x="78" y="128" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="13" font-weight="700">Schedule</text>
  <text x="78" y="150" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">orchestrate.yml</text>
  <text x="78" y="166" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">daily 05:30 UTC</text>
  <text x="78" y="182" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">dispatch / repo</text>

  <!-- Phase: Prepare -->
  <rect x="170" y="100" width="128" height="96" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="1.5"/>
  <text x="234" y="128" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="13" font-weight="700">Prepare</text>
  <text x="234" y="150" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">checkout repo</text>
  <text x="234" y="166" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">stage seed +</text>
  <text x="234" y="182" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">framework</text>

  <!-- Phase: Escalate (the 3 tiers) -->
  <rect x="326" y="74" width="232" height="148" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-primary,#0d6efd)" stroke-width="2"/>
  <text x="442" y="94" text-anchor="middle" fill="var(--bs-primary,#0d6efd)" font-size="13" font-weight="700">3-tier escalation</text>
  <rect x="340" y="104" width="204" height="30" rx="6" fill="var(--bs-info,#0dcaf0)" opacity="0.85"/>
  <text x="442" y="124" text-anchor="middle" fill="#000" font-size="11.5" font-weight="600">Haiku · generate / draft</text>
  <rect x="340" y="140" width="204" height="30" rx="6" fill="var(--bs-primary,#0d6efd)"/>
  <text x="442" y="160" text-anchor="middle" fill="#fff" font-size="11.5" font-weight="600">Sonnet · expand / deepen</text>
  <rect x="340" y="176" width="204" height="30" rx="6" fill="var(--bs-warning,#ffc107)"/>
  <text x="442" y="196" text-anchor="middle" fill="#000" font-size="11.5" font-weight="600">Opus · enhance / finalize</text>

  <!-- Phase: Record -->
  <rect x="586" y="100" width="110" height="96" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-border-color,#dee2e6)" stroke-width="1.5"/>
  <text x="641" y="128" text-anchor="middle" fill="var(--bs-body-color,#212529)" font-size="13" font-weight="700">Record</text>
  <text x="641" y="150" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">seed §8 → hub</text>
  <text x="641" y="166" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">strip hub</text>
  <text x="641" y="182" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">files</text>

  <!-- Phase: Publish -->
  <rect x="724" y="100" width="84" height="96" rx="9" fill="var(--bs-tertiary-bg,#f8f9fa)" stroke="var(--bs-success,#198754)" stroke-width="2"/>
  <text x="766" y="128" text-anchor="middle" fill="var(--bs-success,#198754)" font-size="13" font-weight="700">Publish</text>
  <text x="766" y="152" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">content +</text>
  <text x="766" y="168" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">telemetry</text>
  <text x="766" y="184" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">→ repo</text>

  <!-- arrows -->
  <line x1="142" y1="148" x2="166" y2="148" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="2" marker-end="url(#ar2)"/>
  <line x1="298" y1="148" x2="322" y2="148" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="2" marker-end="url(#ar2)"/>
  <line x1="558" y1="148" x2="582" y2="148" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="2" marker-end="url(#ar2)"/>
  <line x1="696" y1="148" x2="720" y2="148" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="2" marker-end="url(#ar2)"/>

  <!-- fallback note -->
  <text x="442" y="244" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">if the tiers produce nothing → one-pass <tspan font-style="italic">API-key fallback</tspan></text>
</svg>
<figcaption class="figure-caption mt-2">One tick: schedule → prepare → three-model escalation → record → publish.
The three AI passes share one working tree.</figcaption>
</figure>

Step by step, the engine (`grow-lineage.yml`) does this for a single repo:

1. **Schedule** — `orchestrate.yml` runs on a daily cron, refreshes the
   [lineage ledger]({{ '/lineage/' | relative_url }}), and dispatches one tick per
   repo.
2. **Prepare** — check out the year repo, then stage its seed (`lineage/seeds/<year>.md` → `seed.md`) and the canonical framework (`lineage/framework/*` → `.github/`) from the hub.
3. **Generate (Tier 1 · Haiku)** — pick 1–3 topics not yet covered, then research and write a first draft of each.
4. **Expand (Tier 2 · Sonnet)** — deepen every draft: detail, specific dates and figures, sourced facts, and cross-links between topics.
5. **Enhance (Tier 3 · Opus)** — polish prose and verify sources, rebuild the indices and timeline, regenerate the seed, and append a new **Tick N** entry to the seed's Evolution Log.
6. **Fallback** — if the OAuth passes produced nothing (empty tree, or an authentication error), one complete pass runs on the API key instead.
7. **Illustrate** — every new article gets a preview banner from the `zer0-image-generator` engine's illustration loop (ADR-0008): Claude plans the scene, draws it as SVG from the org's style card and the era's palette (`lineage/policy.yml` `preview:`), the engine outlines the headline and strict-lints the file, then renders it at full and card-thumbnail size so a vision critic can request targeted edits before the best draft is committed. A banner that cannot be made clean ships simple generated art instead — the tick never waits on its pictures.
8. **Record** — persist the updated seed Evolution Log back to the hub (the tick clock advances), then **strip** every hub-owned file from the checkout.
9. **Publish** — commit and push **only** the new content + telemetry to the year repo, which rebuilds its own Pages site.

## 3 · The three-model escalation

A single model writing a finished article in one shot is expensive and uneven. Instead, work climbs a ladder — each rung handing more capable (and more costly) models a better-formed draft, so the frontier model spends its budget on judgment, not first drafts. The model for each rung is read from
[`lineage/policy.yml`](https://github.com/{{ site.repository | join: '' }}/blob/main/lineage/policy.yml),
so tiers can be retuned in one place.

<figure class="my-4 text-center">
<svg viewBox="0 0 720 360" role="img" aria-label="A three-step ascending staircase. Tier one is Haiku, which generates drafts by planning, researching, and writing. Tier two is Sonnet, which expands drafts with detail, sources, and cross-links. Tier three is Opus, which enhances: polishing, building indices, syncing the seed, and finishing ready to publish. Capability and cost increase up the staircase, with an API-key fallback to the side." style="max-width:100%;height:auto;font-family:var(--bs-font-sans-serif,system-ui,sans-serif)">
  <defs>
    <marker id="ar3" markerWidth="10" markerHeight="10" refX="6" refY="3" orient="auto">
      <path d="M0,0 L7,3 L0,6 Z" fill="var(--bs-secondary-color,#6c757d)"/>
    </marker>
  </defs>

  <!-- Tier 1 -->
  <rect x="30" y="234" width="230" height="96" rx="10" fill="var(--bs-info,#0dcaf0)" opacity="0.9"/>
  <text x="46" y="262" fill="#000" font-size="14" font-weight="700">Tier 1 · Haiku</text>
  <text x="46" y="284" fill="#000" font-size="13" font-weight="600">GENERATE</text>
  <text x="46" y="304" fill="#000" font-size="11.5">plan · research · draft new files</text>
  <text x="46" y="320" fill="#000" font-size="11.5">claude-haiku-5-5</text>

  <!-- Tier 2 -->
  <rect x="245" y="150" width="230" height="96" rx="10" fill="var(--bs-primary,#0d6efd)"/>
  <text x="261" y="178" fill="#fff" font-size="14" font-weight="700">Tier 2 · Sonnet</text>
  <text x="261" y="200" fill="#fff" font-size="13" font-weight="600">EXPAND</text>
  <text x="261" y="220" fill="#fff" font-size="11.5">detail · sources · cross-links</text>
  <text x="261" y="236" fill="#fff" font-size="11.5">claude-sonnet-5-5</text>

  <!-- Tier 3 -->
  <rect x="460" y="66" width="234" height="96" rx="10" fill="var(--bs-warning,#ffc107)"/>
  <text x="476" y="94" fill="#000" font-size="14" font-weight="700">Tier 3 · Opus</text>
  <text x="476" y="116" fill="#000" font-size="13" font-weight="600">ENHANCE</text>
  <text x="476" y="136" fill="#000" font-size="11.5">polish · index · seed · finalize</text>
  <text x="476" y="152" fill="#000" font-size="11.5">claude-opus-5-5</text>

  <!-- escalation arrow -->
  <line x1="60" y1="222" x2="150" y2="160" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="2" marker-end="url(#ar3)"/>
  <line x1="300" y1="138" x2="390" y2="76" stroke="var(--bs-secondary-color,#6c757d)" stroke-width="2" marker-end="url(#ar3)"/>
  <text x="360" y="334" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="12" font-style="italic">increasing capability &#38; cost &#8594;</text>

  <!-- fallback -->
  <rect x="476" y="186" width="218" height="60" rx="8" fill="none" stroke="var(--bs-danger,#dc3545)" stroke-width="1.5" stroke-dasharray="5 4"/>
  <text x="585" y="208" text-anchor="middle" fill="var(--bs-danger,#dc3545)" font-size="12" font-weight="600">API-key fallback</text>
  <text x="585" y="228" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">one full pass if the</text>
  <text x="585" y="242" text-anchor="middle" fill="var(--bs-secondary-color,#6c757d)" font-size="11">OAuth tiers come up empty</text>
</svg>
<figcaption class="figure-caption mt-2">Each rung hands a better-formed draft to a more capable model, so Opus is
spent on judgment, not first drafts.</figcaption>
</figure>

| Tier | Model | Job | Leaves behind |
|---|---|---|---|
| 1 · Generate | `claude-haiku-5-5` | Plan the roadmap, research, write first drafts | Uncommitted draft files |
| 2 · Expand | `claude-sonnet-5-5` | Deepen each draft — detail, dates, sources, cross-links | Richer drafts |
| 3 · Enhance | `claude-opus-5-5` | Polish, verify, rebuild indices, update the seed | Finished content + a new Tick entry |
| Fallback | `claude-opus-5-5` | One complete pass if the OAuth tiers produced nothing | Same finished output |

## 4 · How the toolkit reaches each repo (adapter + staging)

A subtle but load-bearing design choice: the year repos carry only **thin adapters** in `.claude/`, while the **canonical procedures** live in the hub. This keeps every repo lean *and* keeps the hub the single source of truth for *how* growth works.

<div class="row g-3 my-3">
  <div class="col-md-4">
    <div class="card h-100"><div class="card-body">
      <h3 class="h6"><i class="bi bi-file-earmark-text me-1"></i>1 · Discover</h3>
      <p class="card-text small mb-0">Claude Code finds the skill via the year
      repo's <code>.claude/skills/&lt;name&gt;/SKILL.md</code> — a ~20-line
      <strong>adapter</strong>.</p>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100"><div class="card-body">
      <h3 class="h6"><i class="bi bi-signpost-split me-1"></i>2 · Delegate</h3>
      <p class="card-text small mb-0">The adapter says <em>“canonical procedure:
      <code>.github/skills/&lt;name&gt;</code> — read it and follow exactly.”</em></p>
    </div></div>
  </div>
  <div class="col-md-4">
    <div class="card h-100"><div class="card-body">
      <h3 class="h6"><i class="bi bi-box-arrow-in-down me-1"></i>3 · Stage</h3>
      <p class="card-text small mb-0">That canonical file exists only because the
      tick <strong>staged</strong> <code>lineage/framework/</code> from the hub —
      then strips it before publishing.</p>
    </div></div>
  </div>
</div>

The effect: the hub is genuinely authoritative for every procedure, the year repos stay lean (adapters + content only), and a single edit in `lineage/framework/` reaches every repo on its next tick. See
[ADR-0001](https://github.com/{{ site.repository | join: '' }}/blob/main/lineage/decisions/ADR-0001-centralized-growth-orchestration.md)
for the alternatives weighed and why this one was chosen.

## 5 · The strategy — perpetual, self-referential growth

- **Grow forever.** Every repo grows perpetually. Nothing is consolidated, archived, or deleted — the network only ever gets larger and deeper.
- **The seed is the clock.** Each year's seed carries an **Evolution Log** (§8). Every published tick appends a `Tick N` entry; that log is how the system knows what a repo already covers and how many times it has grown.
- **One scheduler, many repos.** A single daily cron on the hub paces the whole org. There are no per-repo schedules to drift or collide, and growth can be paused org-wide simply by not dispatching.
- **Escalate, don't repeat.** Cheap models do the broad first-draft work; the frontier model is reserved for the judgment-heavy finish.
- **New eras spawn tangentially — and automatically.** As the frontier matures, the hub plants a fresh repo whose subject is chosen to be *tangential* to the newest one — so the lineage branches outward into related territory rather than looping. `2012` was the first tangentially-spawned era (see
  [ADR-0002](https://github.com/{{ site.repository | join: '' }}/blob/main/lineage/decisions/ADR-0002-tangential-era-spawning.md)),
  and spawning is now **maturity-gated automation**: once every member has logged the policy's `spawn.frontier_ticks` growth cycles and the roster is under `spawn.max_members`, the daily orchestrate run dispatches the plant-lineage workflow — a frontier-model DECIDE pass authors the tangential seed, the deterministic planter creates the repo, and the next tick grows it
  ([ADR-0007](https://github.com/{{ site.repository | join: '' }}/blob/main/lineage/decisions/ADR-0007-maturity-gated-auto-spawning.md)).
- **Self-referential.** Repos cross-link their own topics and, increasingly, each other — a knowledge base that builds on and refers back to itself.

## 6 · Guardrails & trust

- **Authentication.** Model passes use a Claude subscription token (`CLAUDE_CODE_OAUTH_TOKEN`), with an `ANTHROPIC_API_KEY` fallback; cross-repo pushes use a scoped `LIFECYCLE_PAT`. Secrets live in the org, never in code.
- **Clean repos by construction.** The strip step guarantees a year repo only ever receives content + telemetry — never the hub's seed, framework, or scratch files.
- **Deterministic when idle.** If nothing changed, the ledger refresh makes no commit and a tick that writes no content publishes nothing.
- **Observable.** Every run uploads its agent telemetry, and the
  [lineage dashboard]({{ '/lineage/' | relative_url }}) shows each repo's growth
  state and tick count.

> **Watching and improving itself.** Growth is only half the system. A separate
> routine **agent fleet** reviews, fixes, aligns, learns from, and evolves the
> hub and framework — a self-monitoring, continuously improving loop. See
> [**Self-Improvement**]({{ '/self-improvement/' | relative_url }}).

## At a glance

<div class="row g-3 my-2">
  <div class="col-md-6">
    <div class="card h-100"><div class="card-body">
      <h3 class="h6"><i class="bi bi-diagram-3 me-1"></i>See it live</h3>
      <p class="card-text small mb-2">The growth state of every repo, refreshed from
      the seeds.</p>
      <a class="btn btn-sm btn-outline-primary" href="{{ '/lineage/' | relative_url }}">Lineage dashboard</a>
      <a class="btn btn-sm btn-outline-secondary" href="{{ '/hub/' | relative_url }}">Content hub</a>
    </div></div>
  </div>
  <div class="col-md-6">
    <div class="card h-100"><div class="card-body">
      <h3 class="h6"><i class="bi bi-github me-1"></i>Read the internals</h3>
      <p class="card-text small mb-2">Policy, the decision record, and the engine.</p>
      <a class="btn btn-sm btn-outline-secondary" href="https://github.com/{{ site.repository | join: '' }}/blob/main/lineage/policy.yml">policy.yml</a>
      <a class="btn btn-sm btn-outline-secondary" href="https://github.com/{{ site.repository | join: '' }}/blob/main/lineage/decisions/ADR-0001-centralized-growth-orchestration.md">ADR-0001</a>
      <a class="btn btn-sm btn-outline-secondary" href="https://github.com/{{ site.repository | join: '' }}/blob/main/.github/workflows/grow-lineage.yml">grow-lineage.yml</a>
    </div></div>
  </div>
</div>
