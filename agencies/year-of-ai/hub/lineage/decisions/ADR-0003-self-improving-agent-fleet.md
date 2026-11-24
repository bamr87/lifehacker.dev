# ADR-0003: The self-improving agent fleet — models watching models

**Status:** Proposed **Date:** 2026-06-18 **Deciders:** Repo owner (@bamr87) **Depends on:** [ADR-0001](ADR-0001-centralized-growth-orchestration.md), [ADR-0002](ADR-0002-tangential-era-spawning.md)

## Context

ADR-0001/0002 made the org self-growing and self-spawning. But today the central engine runs **only** the 3-tier grow tick (plus `plant-lineage` on demand). Two consequences:

- The framework's own self-improvement mechanisms — `learn`, `pollinate`, `distill`, `evolve`, `check-lifecycle` — were authored for the **old per-repo model** and are **dormant**: not wired into `orchestrate.yml` / `grow-lineage.yml`.
- There is **no routine layer** that reviews what the agents publish, monitors cost / quality / failure, keeps repos aligned to policy, fixes drift, or improves the framework from telemetry. The system can grow, but it cannot yet *watch or improve itself*.

As the fleet of growing repos scales (11 and counting), it needs a **meta-layer**: routine agents whose job is the health and continuous improvement of the growth system itself — *a model for models*. This ADR identifies that fleet. It is the synthesized output of a multi-agent design workflow (4 architect lenses → synthesis → 3 adversarial critics → finalize), with every load-bearing claim verified against the repo.

## What the design surfaced — real defects (worth fixing regardless of the fleet)

1. **The hub has no evolution ledger; telemetry is collected then discarded.** `grow-lineage.yml` uploads a 14-day artifact per tick, but the dormant `lineage/framework/workflows/telemetry.yml` that would aggregate it triggers on a workflow named `grow` (the hub's is **"Grow Lineage"**), downloads the wrong artifact pattern (`agent-telemetry-*` vs. the actual `grow-lineage-telemetry-*`), and expects files the tick never produces. So raw I/O is captured and dropped after 14 days, never aggregated.
2. **No supply-chain security.** No `.github/dependabot.yml`, no CodeQL/Trivy/ bundle-audit; every workflow pins third-party actions to **floating tags** (`actions/checkout@v4`, …) on secret-bearing jobs.
3. **A required review is bypassable.** `lineage/framework/workflows/learn.yml`
   force-merges its PR via `… || gh pr merge --squash`, bypassing the review check —
   making any framework reviewer illusory until removed.
4. **A publish race on year-repo `main`.** `grow-lineage`'s publish push and the (future) rollback / hygiene / aligner PRs all write the same branch with no shared lock.
5. **A workflow-injection surface.** The untrusted `${{ inputs.args }}` dispatch input is interpolated straight into `GENERATE_PROMPT`, and the model passes hold web tools with write access.
6. **`CLAUDE.md` drift.** The publish strip-list never touches `CLAUDE.md` and it is never re-synced, so year repos carry a stale old-model `CLAUDE.md`.

## Decision

A fleet of **24 routine agents** across the seven functions (**review · update · fix · learn · align · evolve · monitor**), forming a closed self-improvement loop. Each agent is tagged by origin — 🆕 **net-new**, ♻️ **rewire-dormant** (wiring an existing-but-dormant mechanism into the central model), or ⬆️ **upgrade-tool** (making an existing deterministic tool agentic).

**Operating doctrine (non-negotiable):**

- **PR-not-direct** for every mutation. The *only* direct committer is `telemetry-ledger-collector` — append-only, scoped to the data path.
- **Human gate** on the four highest-blast-radius mutations: model-ID swaps, tier / `max-turns` changes, content rollbacks, and deletions / workflow-permission changes.
- A **global kill-switch** (`fleet-pause-killswitch`) every dispatching/mutating workflow reads first — fail-safe: if it can't be read, the fleet is treated as paused.
- **Serialized writes** (`repo-write-serializer`): one writer per year-repo `main`, one open PR per framework / policy surface.
- A **stabilization quarantine** on the learn loop, so `observe → edit → act → observe` cannot amplify into a feedback runaway.

## The closed loop

```
        ┌──────────────────────────── OBSERVE ◀───────────────────────────┐
        ▼   grow tick emits telemetry → ledger-collector (the keystone)    │
     DETECT   health-watch · secret-expiry-watch · pages-deploy-sentinel   │
        ▼                                                                   │
      GATE    prepublish-gate · injection-auditor · license-auditor        │
        ▼     framework-pr-reviewer (stops bad self-edits org-wide)         │
      LEARN   learn-flywheel mines a STABILIZED window → edits the          │
        ▼     canonical framework → every next tick is cheaper             │
      ALIGN   tickclock-auditor · adapter-canon-aligner · claude-md-warden  │
        ▼                                                                   │
   FIX/RECOVER  hygiene-warden · tick-rollback-sentinel · recovery-rehearsal│
        ▼                                                                   │
      EVOLVE  tier-roi-auditor · model-id-drift · fleet-meta-auditor ───────┤
        ▼                                                                   │
      GOVERN  cost-governor (pre-flight ceiling) · pause kill-switch ·      │
              lineage-state-report (one human pane) ──────────────────────┘
```

Every edge that mutates content / repos / secrets is PR-not-direct, human-gated on the four riskiest mutations, serialized so no two writers race a surface, and stoppable via the kill-switch.

## The fleet

### Monitor / Observe

**`telemetry-ledger-collector`** — **P0** · ⬆️ upgrade-tool · _deterministic-script; haiku only to phrase a fast-path anomaly one-liner when a per-tick…_

The P0 keystone every learn/cost/monitor agent depends on. CONFIRMED BUG: the hub has no evolution ledger. grow-lineage.yml uploads a 14-day artifact grow-lineage-telemetry-&lt;repo&gt;-&lt;run_id&gt; holding a single claude-execution-output.json; the dormant lineage/framework/workflows/telemetry.yml that would append to telemetry/evolution.jsonl.gz triggers on workflows:["grow"] (hub workflow is named "Grow Lineage"), downloads pattern agent-telemetry-* (wrong name), and slurps meta/execution-api-key/execution-subscription…

- **Trigger / cadence:** workflow_run on "Grow Lineage" completion (corrected name), reading grow-lineage-telemetry-* (corrected pattern) + workflow_run metadata (conclusion,… — Per grow tick (~11/day), serialized by a telemetry-append concurrency lock (cancel-in-progress:false) with a…
- **Touches:** hub telemetry/evolution.jsonl.gz ONLY (the sole direct-commit-to-main agent, scope-capped to the data path).
- **Guardrails:** Append-only, never rewrites prior records; idempotent on run_id enforced as a HARD pre-append check; each record VALIDATED against the pinned evolution-telemetry/v1 schema before append — on parse/validation failure it writes a quarantined .bad line instead…

**`fleet-pause-killswitch`** — **P0** · 🆕 net-new · _deterministic-script (a committed flag + a read-guard snippet shared across workflows)._

NET-NEW infrastructure, not a model agent: the single global halt the doctrine is missing. fleet-cost-governor's throttle can only trim the targets list with a hard floor of &gt;=1 repo always growing — there is no way to STOP all mutation while a human investigates a feedback loop, cost runaway, or bad framework edit. This is a committed _data/fleet_pause.yml { paused: bool, reason, set_by, set_at } that EVERY dispatching and mutating step reads as its FIRST action and no-ops when paused:true. orchestrate's fan-out,…

- **Trigger / cadence:** Read (not fired): every dispatching/mutating workflow's first step consults it. Written by a human via a tiny set-pause workflow_dispatch, or by… — On-demand (incident response). Read on every dispatch/mutation.
- **Touches:** _data/fleet_pause.yml only.
- **Guardrails:** Fail-safe: any workflow that cannot read the flag treats the fleet as PAUSED (default-deny on uncertainty for mutations). Setting it requires an explicit human action or a hard-breach + alert. Resuming is human-only. Read-guard is deterministic — no model can…

**`pages-deploy-sentinel`** — **P0** · 🆕 net-new · _deterministic-script._

The SINGLE post-publish liveness detector and the SOLE trigger source for tick-rollback-sentinel. Verifies each year repo's GitHub Pages build/deploy actually SUCCEEDED downstream and the live site_url returns 200 with expected content. The publish push to main does not confirm the remote_theme-fetch-and-render Pages build that follows — a theme rate-limit, a front matter that slips the inline gate, or a Pages outage silently dark-publishes a repo for days. Distinct from prepublish-gate (pre-publish CI build):…

- **Trigger / cadence:** Scheduled cron hourly (decoupled from the growth cron so a broken deploy is caught within the hour) + workflow_dispatch; reads members + site_url… — Hourly.
- **Touches:** Hub issue (one idempotent labeled section/issue). No content/_data/framework writes.
- **Guardrails:** Read-only against year repos + Pages API. The only mutation is the edit-in-place tracking section (never spam-creates). No auto-remediation: it files an incident with a one-click revert dispatch for tick-rollback-sentinel; a human initiates the actual revert.

**`secret-expiry-watch`** — **P0** · 🆕 net-new · _deterministic-script._

SOLE owner of the auth/credential-degradation signal (the other monitors reference its issue rather than re-deriving the fallback-rate, killing the 4x duplicate-alert problem). The machine hangs on three secrets: CLAUDE_CODE_OAUTH_TOKEN (primary, has 401'd), ANTHROPIC_API_KEY (fallback, 'proved invalid across this lineage'), LIFECYCLE_PAT (cross-repo push). Today the only reaction is grow-lineage's after-the-fact fallback gate that alerts no one. This probes each credential and mines telemetry for the…

- **Trigger / cadence:** Scheduled cron ~05:00 UTC (ahead of orchestrate's 05:30 so a dead token is flagged before the day's ticks burn) + workflow_dispatch; also reads… — Daily.
- **Touches:** One labeled hub issue + optional notification. Never reads/prints/writes secret VALUES.
- **Guardrails:** SINGLE-attempt probes, NO retry loop (a retry loop could hammer the very endpoint that 401'd). Cheapest liveness check possible (avoid burning subscription quota daily). Secret values never logged (valid/invalid + scope/expiry metadata only); a secret-scan…

**`fleet-health-watch`** — **P1** · 🆕 net-new · _deterministic-script for all detectors/threshold math; haiku to compose the digest…_

ONE daily watcher that absorbs the former telemetry-anomaly-watch + fleet-run-watchdog + the monitor-half of fleet-cost-governor — they all read the IDENTICAL {telemetry/evolution.jsonl.gz, Actions API, _data/lineage.yml} and emitted near-identical sticky issues (alert fragmentation). Reads those sources ONCE and edits ONE sticky 'Fleet health' issue with labeled sections: (a) RUN STATUS — each expected workflow's last run + age, missing per-repo grow dispatches; (b) TICK-CLOCK ADVANCE — repos whose ticks_logged…

- **Trigger / cadence:** Scheduled cron ~07:00 UTC (after the daily growth window) + workflow_dispatch; reads Actions runs API + _data/lineage.yml + telemetry + a queue-age… — Daily aggregate + a weekly org-wide roll-up section. Fast per-tick anomaly handled in the collector.
- **Touches:** One labeled hub issue + a dashboard JSON artifact. Read-only on Actions/ledger/lineage.
- **Guardrails:** Read-only — does NOT auto-retrigger workflows (avoids dispatch storms) or auto-remediate auth; reports gaps. Per-section issue LABEL + a precedence de-dupe rule (auth &gt; automation &gt; cost &gt; anomaly) so one root cause yields one section, not duplicate alerts.…

**`fleet-cost-governor`** — **P2** · 🆕 net-new · _deterministic-script for threshold math; haiku for the breach-issue narrative._

Cost-lens safety rail on the orchestrator, now a NARROW survivor after its monitor-half merged into fleet-health-watch: it owns ONLY the throttle/budget mutation + the same-day pre-flight ceiling. orchestrate.yml fans a grow tick to EVERY member daily (lines 105-118) with NO spend awareness and NO read of any budget file — a runaway (Opus pinning max-turns on every repo) or a price spike burns a full fleet-day before anyone reacts. Adds (a) a PRE-FLIGHT ceiling: a deterministic step at the TOP of orchestrate's…

- **Trigger / cadence:** A deterministic guard INSIDE orchestrate.yml's fan-out loop (reads fleet_budget.yml + fleet_pause.yml at the TOP) + a daily post-fan-out reconcile… — Per fan-out (pre-flight guard) + daily reconcile.
- **Touches:** _data/fleet_budget.yml + (hard breach only) _data/fleet_pause.yml. No content/policy.
- **Guardrails:** Throttle is ADVISORY + FLOORED (&gt;=1 repo always grows); alert-before-act for any throttle beyond a small cap. Exactly ONE writer + ONE reader of the budget signal (orchestrate must be wired to read fleet_budget.yml + fleet_pause.yml at the top of fan-out —…

**`lineage-state-report`** — **P2** · 🆕 net-new · _haiku (formatting/linking a rollup over already-derived signals); no detection model._

Single human-in-the-loop pane of glass — a PURE AGGREGATOR with ZERO new detection logic (so it doesn't become a competing 7th alert). The merged fleet still emits the fleet-health-watch issue + the auth issue + a stream of human-gated PRs; a maintainer has no single 'is the model-for-models healthy and improving?' view, so the human-gate decisions the doctrine relies on (approve tier changes, model swaps, rollbacks, deletions) decay into alert fatigue — silently defeating the human-gate safety design. Reads the…

- **Trigger / cadence:** Scheduled cron weekly + workflow_dispatch; reads the sticky issues + dashboards + ledger. First step checks fleet_pause. — Weekly.
- **Touches:** One rollup issue/dashboard JSON. Read-only everywhere.
- **Guardrails:** Read-only, ZERO new detection — it links to source stickies and never re-derives anomalies (so it cannot multiply alerts). Idempotent rollup, edited in place.

### Review

**`prepublish-gate`** — **P0** · 🆕 net-new · _deterministic for the jekyll build + front-matter/link checks (delegating to…_

THE biggest hole, now ONE inline gate (merging the former prepublish-verifier + prepublish-build-gate): grow-lineage.yml's publish step (lines 261-289) commits the dirty tree straight to each year repo's main with ZERO pre-publish review — the only net is the deterministic tick-clock advance + the single-run is_error fallback. This runs INLINE after the enhance/fallback pass and BEFORE publish, in ONE job over ONE checkout of the staged tree, in two stages: (1) RENDER correctness — a cached, token-authenticated…

- **Trigger / cadence:** Step in grow-lineage.yml gated to run only on a dirty content tree (successful tick), between 'Upload agent telemetry artifact' (line 210) and the… — Every grow tick that produces content (~once/day/repo).
- **Touches:** Read-only on content; writes only its verdict + job summary under /tmp. Sole authority is to SET THE PUBLISH GATE the existing step honors.
- **Guardrails:** Read-only allowedTools (Read, Grep, Glob, WebFetch/WebSearch BOUNDED to a per-tick claim cap, Bash limited to jekyll build + content-review.rb + git diff + link-check); cannot edit/commit/push. HARD-vs-SOFT distinction is mandatory:…

**`framework-pr-reviewer`** — **P0** · ⬆️ upgrade-tool · _sonnet (mirrors content-reviewer tier); a deterministic pre-check verifies the diff…_

SAFETY for the self-modification path; a P0 PREREQUISITE (mis-ranked P1 in the synthesis) that MUST land before any framework auto-merge. learn-flywheel, adapter-canon-aligner, and framework-evolve-auditor's structural mode all open PRs editing canonical lineage/framework/, which stages into EVERY year repo via the per-tick cp -r /tmp/hub/lineage/framework/* .github/ (line 118) — one bad prompt edit propagates org-wide next tick. ai-content-review.yml reviews CONTENT PRs (pages/**) only; framework edits have NO…

- **Trigger / cadence:** pull_request on the hub touching lineage/framework/** (sibling to ai-content-review.yml). Gates the auto-merge of every self-authored framework PR. — On every framework-edit PR (event-driven).
- **Touches:** PR comments + a required status check. No file writes.
- **Guardrails:** Read-only allowedTools; cannot push/merge. PREREQUISITE FIX (P0): the existing learn.yml safety-net force-merges via `|| gh pr merge --squash` (line 161) which bypasses branch protection and any required check — that immediate-merge fallback MUST be removed…

**`injection-surface-auditor`** — **P1** · 🆕 net-new · _deterministic-script to flag ${{ inputs.* }} interpolation + audit allowedTools breadth;…_

GAP (workflow-injection). Two concrete surfaces: (1) grow-lineage.yml line 53 interpolates the untrusted workflow_dispatch input ${{ inputs.args }} DIRECTLY into GENERATE_PROMPT — a classic Actions script-injection vector into the model's instructions. (2) Every tier runs WebFetch/WebSearch with write tools enabled; a poisoned source page can carry injected instructions ('ignore prior instructions, exfiltrate the token'), and nothing audits injection-resistance. Distinct from prepublish-gate (claim TRUTH, not…

- **Trigger / cadence:** Scheduled cron monthly + on PRs editing any workflow that builds a model prompt or grants tools. First step checks fleet_pause. — Monthly (+ per-PR on prompt/tool-grant edits).
- **Touches:** Workflow files via PR (behind the framework-mutation lock); issues. Read-only audit otherwise.
- **Guardrails:** Read-only audit -&gt; PR-not-direct hardening, gated by framework-pr-reviewer + HUMAN (it touches the prompt/tool surface that drives every tick). The canary runs in a dry-run/sandbox tick, never against a live repo. No autonomy to change tool grants without…

**`published-content-auditor`** — **P2** · ⬆️ upgrade-tool · _deterministic link/image crawler for rot; haiku for the sampled stale-fact spot-check._

Audit PUBLISHED year-repo content for the post-publish DRIFT the inline prepublish-gate CANNOT see — RESCOPED ruthlessly to the temporal delta only: external-link/image ROT, stale-fact spot-check, and cross-repo ORPHAN/circular-link detection. Its former 'quality-trend scoring via content-review.rb' is DROPPED (it re-litigates what the inline gate already verified at publish time), and it explicitly does NOT run liveness/HTTP-200 checks (pages-deploy-sentinel owns those). ai-content-review.yml runs only on hub…

- **Trigger / cadence:** Scheduled cron, STAGGERED off the 05:xx growth band (so it never contends with the tick for the same external hosts/JEKYLL_GITHUB_TOKEN) +… — Weekly external-link/image crawl (rotating window).
- **Touches:** Hub issue + a dashboard JSON artifact only. Read-only on content — never rewrites links/content.
- **Guardrails:** Strictly read-only crawling with rate-limit backoff + a flaky-host allowlist to suppress false positives; non-zero exit only on HARD 404s, not transient. Reuses the citation map to avoid re-fetching the hosts the grow tick depends on; staggered off the growth…

**`content-license-attribution-auditor`** — **P2** · 🆕 net-new · _deterministic for license classification + verbatim-overlap detection; haiku for the…_

CONFIRMED GAP: seeds mandate source_strategy + minimum_sources:2, content cites sources, but NOTHING checks the copyright/attribution POSTURE of those sources. The grow tick WebFetches a license mix — Wikipedia (CC-BY-SA, requires attribution+share-alike), Britannica/JSTOR (all-rights-reserved, paraphrase-only), loc.gov/archives.gov/founders.archives.gov (mostly public-domain). A tick that pastes a verbatim Britannica/JSTOR passage, or reuses Wikipedia prose without CC-BY-SA attribution, creates real…

- **Trigger / cadence:** Scheduled cron weekly, STAGGERED off the growth band + workflow_dispatch; sampled (mirrors published-content-auditor's cost discipline). First step… — Weekly, sampled rotating window.
- **Touches:** Hub issues + (optionally) a framework PR for the enhance-prompt rule. Read-only on content.
- **Guardrails:** Read-only on content. Strictly SAMPLED, reuses the citation map instead of re-fetching (so it doesn't duplicate the grow tick's web cost or rate-limit shared hosts), with allowlist + backoff, STAGGERED off the growth band. Kept OUT of the inline tick gate (no…

### Fix

**`repo-write-serializer`** — **P0** · ♻️ rewire-dormant · _deterministic-script (concurrency config + a learnings.jsonl/open-PR lock check)._

NET-NEW coordination infrastructure (re-wiring of concurrency, not a model agent): close the RACE on each year-repo's main. grow-lineage.yml's publish (lines 285-289, a 3-try push||pull --rebase loop), tick-rollback-sentinel's revert PR, repo-hygiene-warden's cleanup PR, and adapter-canon-aligner's forward .claude/ fix all push/PR to the SAME year-repo main with NO shared lock — grow-lineage's concurrency group is only grow-${{inputs.repo}}. At worst a rebase silently re-applies a tick a rollback just withdrew.…

- **Trigger / cadence:** Read/declared (not fired): a concurrency-group + open-PR-guard convention adopted by grow-lineage and every repo/framework/policy-mutating agent. — Continuous (concurrency declaration).
- **Touches:** No files of its own — it constrains other agents' write windows.
- **Guardrails:** grow-lineage's concurrency extends to repo-write-&lt;repo&gt;; repo-hygiene-warden, tick-rollback-sentinel, and adapter-canon-aligner's forward fix JOIN that group. framework-mutation and policy-mutation groups allow exactly one open PR each; a second proposer…

**`repo-hygiene-warden`** — **P1** · 🆕 net-new · _deterministic-script for the path-manifest diff + adapter-pointer check; haiku only to…_

Enforce the ADR-0001 invariant that a year repo holds ONLY content + _config.yml + .claude/ (thin adapters) + telemetry/. grow-lineage's publish strips .github/seed.md/lifecycle.yml/seed-package/ROADMAP.md/LIFECYCLE.md each tick (line 272), but if the strip fails (push race, partial run), an old per-repo workflow leaks back, or someone hand-commits, hub files silently land on a year-repo main and the next stage layers staged files on dirty state — nothing detects it. Scans each member tree for forbidden paths and…

- **Trigger / cadence:** Scheduled scan weekly, OUTSIDE the 05:30 growth band by hours + workflow_dispatch single-repo target; reads each member tree via the gh trees API.… — Weekly across all year repos.
- **Touches:** Cleanup PR on the offending year repo via LIFECYCLE_PAT to a branch, joining the shared repo-write-&lt;repo&gt; lock. Never direct-commits, never…
- **Guardrails:** PR-not-direct + HUMAN GATE on deletions (never auto-merges a deletion). SKIPS any repo with a grow-lineage run in-progress or completed within the last hour (so it never deletes transient staged tick state). Requires a path to be 'leaked' on TWO consecutive…

**`model-id-drift-checker`** — **P1** · ⬆️ upgrade-tool · _haiku._

Keep lineage/policy.yml's hardcoded model IDs (claude-haiku-4-5 / claude-sonnet-4-6 / claude-opus-4-8 / distill) from going stale or deprecated. grow-lineage.yml greps these IDs straight out of policy.yml every tick; if Anthropic deprecates or renames one, EVERY OAuth tier silently errors into the fallback with no diagnosis. Validates each ID against the live Anthropic model catalog and, on deprecation/supersession, opens a PR bumping policy.yml to the recommended successor. A cheap correctness check, distinct…

- **Trigger / cadence:** Scheduled cron weekly + workflow_dispatch + on PRs editing lineage/policy.yml; reads the models block + the Anthropic models API/changelog… — Weekly (+ per-PR validity check).
- **Touches:** lineage/policy.yml via PR only, behind the policy-mutation single-PR lock.
- **Guardrails:** PR-not-direct + HUMAN GATE (a model swap changes every repo's growth — no auto-merge). TAKES PRECEDENCE over tier-roi-auditor on the shared policy-mutation lock (correctness before economics); a merged bump forces tier-roi-auditor to re-baseline/auto-close…

**`supply-chain-security-warden`** — **P1** · 🆕 net-new · _deterministic-script for the action-ref + CVE scans; haiku for advisory issue bodies._

CONFIRMED GAP (grep-confirmed: NO .github/dependabot.yml, no CodeQL/Trivy/bundle-audit). Two exposures: (1) ALL workflows pin third-party actions to FLOATING tags — actions/checkout@v4, actions/upload-artifact@v4, and critically anthropics/claude-code-action@v1 — running in jobs that hold CLAUDE_CODE_OAUTH_TOKEN, ANTHROPIC_API_KEY, and LIFECYCLE_PAT; a compromised upstream tag would exfiltrate all three secrets org-wide. (2) Year repos carry Gemfile/Gemfile.lock + _config.yml; CVEs in the github-pages/Jekyll set…

- **Trigger / cadence:** Scheduled cron weekly + workflow_dispatch; audits every workflow's action refs + runs bundle-audit/Dependabot-style checks on the hub + member… — Weekly.
- **Touches:** Workflow files + .github/dependabot.yml via PR; advisory issues. Behind the framework-mutation/policy locks where it touches shared surfaces.
- **Guardrails:** PR-not-direct + ABSOLUTE HUMAN GATE on any workflow action-ref or permission change (highest blast radius — a wrong/yanked SHA breaks every workflow incl. the daily tick; mirrors the model-swap/rollback gating). NEVER auto-merges a security PR touching the…

**`tick-rollback-sentinel`** — **P2** · 🆕 net-new · _sonnet to confirm the offending commit + author a precise revert + incident writeup; the…_

Bounded, HUMAN-INITIATED withdrawal of a bad publish — closes the 'no rollback' gap: today a bad commit sits on a year-repo main until a human intervenes. The FIX counterpart to the inline gate (which prevents bad output) and the single downstream of pages-deploy-sentinel (the SOLE liveness signal). If a published tick broke the live site or shipped a hallucination, it reverts that SINGLE tick's commit via a revert PR (never a force-push, never a direct main edit) and files an incident.

- **Trigger / cadence:** A human-initiated dispatch (one-click 'revert this SHA' from the incident issue pages-deploy-sentinel files) — NOT auto-fired from a monitor verdict… — Event-driven, human-initiated; expected rare.
- **Touches:** A PR on the year repo (joins the shared repo-write-&lt;repo&gt; lock; NOT merged without the human gate); an issue; a seed §8 correction via PR to the hub.
- **Guardrails:** PR-not-direct, never force-pushes, HUMAN GATE (revert PR not auto-merged) AND human-INITIATED (no auto-fire from a monitor). PREREQUISITE FIX: grow-lineage must stamp each publish commit with repo + run_id + §8 tick id (today every tick shares the identical…

### Align

**`ledger-tickclock-auditor`** — **P1** · ♻️ rewire-dormant · _deterministic-script (extends the existing §8 parser); NO model — a detected real…_

Validate the central source of truth — the seed §8 Evolution Log / tick clock — via a CI --check GATE ONLY (the standalone daily correction-PR mode is dropped: it overlapped orchestrate's refresh cadence and risked fighting the by-design safety-net phantom entries, and sync-lineage-state.rb already recounts ticks every run). Re-wires check-lifecycle's dormant reconciler to run CENTRALLY. The genuine net-add gap (nothing checks this today): §8 entries follow the G&lt;gen&gt;-T&lt;seq&gt;/Tick N spec and are MONOTONIC with no…

- **Trigger / cadence:** Step in orchestrate.yml right after 'Refresh lineage ledger' (line 71, before dispatching growth, read-only gate) + a hardened --check CI gate on PRs… — Daily (with orchestrate, read-only) + on every seed/ledger PR.
- **Touches:** Read-only everywhere. No PRs, no direct commits.
- **Guardrails:** Read-only. --check mode just gates a PR; daily mode just flags. A detected phantom tick (clock advanced, no content) is FLAGGED, not deleted — it may be a legitimate withheld tick. No autonomy to mutate §8 or the ledger.

### Update

**`claude-md-canon-warden`** — **P1** · ♻️ rewire-dormant · _sonnet (render the concept-agnostic template + judge meaningful drift vs legitimate…_

CONFIRMED GAP: the publish strip-list (line 272) deliberately does NOT touch CLAUDE.md, and grow-lineage stages only lineage/framework/* -&gt; .github/ + the seed — so a year repo's CLAUDE.md ships ONCE from lineage/repo-template/CLAUDE.md at spawn and is NEVER re-synced. When adapter doctrine evolves (via learn-flywheel), every year-repo CLAUDE.md silently goes stale and mis-describes how the repo grows — the named 'stale year-repo CLAUDE.md' failure mode. repo-hygiene-warden only DELETES forbidden files;…

- **Trigger / cadence:** Scheduled cron bi-weekly, staggered off the growth band + workflow_dispatch; reads each member's published CLAUDE.md vs the rendered canonical… — Bi-weekly; at most one PR per repo per run; skips clean repos.
- **Touches:** Member CLAUDE.md via PR only (joins the shared repo-write-&lt;repo&gt; lock). Never content/_config.yml/.claude content/telemetry/seed.
- **Guardrails:** PR-not-direct, one PR per repo per run, idempotent (clean repo =&gt; no PR). Concept-agnostic template guard (no subject baked in). Joins repo-write-&lt;repo&gt; concurrency so it never opens a PR against a repo mid-tick (also skips repos with a recent/in-progress…

**`adapter-canon-aligner`** — **P2** · ♻️ rewire-dormant · _sonnet — novelty/conflict judgement per pollinate SKILL.md + evolve's…_

The ONLY agent doing the BACKWARD published-.claude/-to-canon diff — re-wires pollinate's dormant Direction 2 + evolve's discoverability checks to keep the framework converging instead of fragmenting. GROUNDING: forward pollination (lineage.sh) is wired only to the DORMANT per-repo grow.yml (line 170), NOT the central grow-lineage.yml, which re-stages canon fresh every tick (cp -r framework -&gt; .github/) and strips .github/ before publish — so forward propagation is implicit and the ONLY surviving framework…

- **Trigger / cadence:** Scheduled cron bi-weekly, after learn-flywheel's run + workflow_dispatch; reads each member's published .claude/ vs canon. First step checks… — Bi-weekly; at most one PR per repo per direction per run.
- **Touches:** hub lineage/framework/** (backward, behind the framework-mutation lock) + member .claude/ (forward fix, behind the shared repo-write-&lt;repo&gt; lock) —…
- **Guardrails:** PR-not-direct in BOTH directions. Backward + both-changed are NEVER auto-merged — pass framework-pr-reviewer's required check + a human (Sonnet novelty judgement must not silently bake a deliberate member divergence into org-wide canon). Forward .claude/ fix…

### Learn

**`learn-flywheel`** — **P1** · ♻️ rewire-dormant · _sonnet (matches policy.models.learn); a deterministic pre-pass extracts the friction set…_

Close the broken learning loop AND own the structural-scorecard pass (absorbing the former framework-evolve-auditor as a second MODE, so two sonnet proposers don't race on the same lineage/framework/ files on colliding cadences). CONFIRMED dead: learn.yml gates on grepping telemetry for 'Replant Summary|Generation closed|Distillation Report' (line 54), but perpetual growth (policy.yml perpetual:true/consolidate:false) NEVER emits those markers, so /learn never fires — and it is wired to the never-triggered…

- **Trigger / cadence:** Scheduled daily/weekly cron on the hub (NOT per-collector-completion — that would form a self-triggering workflow_run cascade), gated to fire only… — Weekly (rolling window of the prior ~15-30 ticks), bounded to &lt;=3 edits/run total across both modes; ONE PR…
- **Touches:** A PR against lineage/framework/** + the learnings ledger. Never content, seed.md, README.md, ROADMAP.md, or lifecycle state.
- **Guardrails:** PR-not-direct. STABILIZATION QUARANTINE: SKIPS any telemetry window whose runs executed under a framework SHA newer than the quarantine threshold, so an edit's effect is observed under steady state before the next edit (breaks the observe-&gt;edit-&gt;act-&gt;observe…

### Evolve

**`tier-roi-auditor`** — **P2** · 🆕 net-new · _sonnet to synthesize the ROI analysis; deterministic pre-aggregation does the jq rollups…_

Make model-tier selection data-driven instead of fixed-by-intuition. policy.yml hardcodes Haiku/Sonnet/Opus for generate/expand/enhance forever; grow-lineage hardcodes per-tier --max-turns caps (80/80/120/150). Reads aggregate telemetry across all ~11 repos to compute per-tier/per-repo cost/quality/turns/latency/yield ROI: is Haiku failing draft so often Sonnet redoes it? Are Opus max-turns routinely under-used (right-size down) or pinned (waste)? Which repos burn most tokens per published topic? Is Opus enhance…

- **Trigger / cadence:** Scheduled cron monthly + on PRs editing lineage/policy.yml as a sanity check; reads the collector's ledger. First step checks fleet_pause. — Monthly.
- **Touches:** Read-only on telemetry/policy. An issue + at most a DRAFT PR to lineage/policy.yml, behind the policy-mutation lock.
- **Guardrails:** HUMAN GATE absolute: tier/max-turns are economically + qualitatively load-bearing — PROPOSE only, draft PR requires explicit human merge. YIELDS to model-id-drift-checker on the shared policy-mutation lock; auto-closes/re-baselines its draft if a model-id…

**`recovery-rehearsal-agent`** — **P2** · 🆕 net-new · _the full Haiku->Sonnet->Opus tick (it must exercise the real germination path);…_

CONFIRMED GAP (grep-confirmed: no restore/recover/re-seed/backup/germinate workflow). The recovery story is theoretical: distill.prompt.md asserts a 'Test of done — a reader with the package, an org, and two secrets reaches a germinated self-growing first repo' that is NEVER exercised; plant-lineage.rb + lineage/repo-template/ run only on a real spawn. If a year repo is corrupted, force-pushed, or deleted — or a bad publish compounds past tick-rollback-sentinel — there is NO validated rebuild path, and the seed §8…

- **Trigger / cadence:** Scheduled cron monthly + workflow_dispatch; operates ONLY in an ephemeral scratch org/repo. First step checks fleet_pause. — Monthly.
- **Touches:** An ephemeral scratch org/repo ONLY (torn down after). Never live year repos. A report issue on the hub.
- **Guardrails:** HARD-ISOLATED to an ephemeral scratch org/repo with a name-prefix guard that REFUSES to run if the target matches ANY live member in _data/lineage.yml (mis-targeting could clobber a real repo or spawn a stray public one). Caps to ONE tick. Monthly (not daily)…

**`fleet-meta-auditor`** — **P2** · 🆕 net-new · _deterministic-script for the registry/last-run/guardrail-drift checks; haiku to narrate…_

The 'who watches the watchers' recursion terminator — the prompt's explicit meta agent that audits the AGENT FLEET ITSELF (NOT the content-growth framework, which learn-flywheel/framework-pr-reviewer own). The deepest blind spot: the ops/learning agents monitor the GROWTH engine, but NOTHING monitors the MONITORS — a dead pages-deploy-sentinel cron, a secret-expiry-watch that lost its probe permission, a learn-flywheel that hasn't merged a learning in months, or a NEW ops agent that hardcodes a year/subject…

- **Trigger / cadence:** Scheduled cron monthly + workflow_dispatch; reads the Actions API for each ops agent's last run + each agent's workflow definition. First step checks… — Monthly.
- **Touches:** One sticky hub issue. Read-only on the Actions API + agent workflow files.
- **Guardrails:** Read-only, one idempotent sticky issue (near-zero cost, cannot mutate the fleet it audits). Explicitly EXCLUDES the content-growth framework from scope (that's framework-pr-reviewer/learn-flywheel). PAIRED with an EXTERNAL dead-man's-switch independent of the…

## Recommended rollout order

- **Phase 0 — safety scaffolding (wire BEFORE any mutating agent is live):** `fleet-pause-killswitch`, `repo-write-serializer`, removing the `learn.yml` immediate-merge fallback, and `framework-pr-reviewer`. None spend model budget on the hot path; all are prerequisites for safe self-modification.
- **Phase 1 — the keystone + gates + canaries:** `telemetry-ledger-collector` first (its `v1` schema is a reviewed contract every other agent reads), then the inline `prepublish-gate` (with `run_id`+tick-id commit stamping for rollback attribution), then `secret-expiry-watch` + `pages-deploy-sentinel` + `fleet-health-watch`.
- **Phase 2 — the loops (now safe to enable):** `learn-flywheel`, `ledger-tickclock-auditor`, `repo-hygiene-warden`, `claude-md-canon-warden`, `model-id-drift-checker`, `supply-chain-security-warden`, `injection-surface-auditor`.
- **Phase 3 — slow structural / economic + meta:** `tier-roi-auditor`, `fleet-cost-governor`, `published-content-auditor`, `content-license-attribution-auditor`, `adapter-canon-aligner`, `tick-rollback-sentinel`, `recovery-rehearsal-agent`, `lineage-state-report`, `fleet-meta-auditor` (with an external dead-man's-switch).

## Most debatable call (flagged honestly)

`fleet-cost-governor` is kept as its own entry rather than dissolved into `orchestrate.yml`. Its detection half merged into `fleet-health-watch`, so it is now narrow — only the pre-flight cost ceiling, the `fleet_budget.yml` writer, and the hard-breach pause-set. A maintainer who prefers can collapse those into deterministic steps inside `orchestrate.yml` with no separate workflow; the capability is identical.

## Consequences

- **Easier:** the system gains eyes and a memory — it can detect regressions, learn from its own telemetry to get cheaper each cycle, and keep 11+ repos aligned to one canon without a human babysitting each tick.
- **Harder / watch-outs:** a meta-layer is itself attack/feedback surface — hence the quarantine, the kill-switch, serialized writes, human gates on the riskiest mutations, and `fleet-meta-auditor` (who watches the watchers) with an external heartbeat so its own death isn't silent.
- **Not duplicated:** nothing here repeats the 3-tier grow tick, the §8 safety net, the inline fallback, `lineage.sh`, the `sync-*` scripts, or PR-time `ai-content-review`. There is no routine `distill` agent — its value is absorbed by `learn-flywheel`'s two modes + `tier-roi-auditor`, and its seed-package regen fires on demand at spawn (ADR-0002).

## Action Items

1. [ ] Owner approves the fleet + doctrine, and the Phase-0 → Phase-3 rollout.
2. [ ] Fix the six surfaced defects (ledger trigger/pattern, Dependabot+CodeQL, `learn.yml` force-merge, publish race, injection surface, `CLAUDE.md` drift).
3. [ ] Build Phase 0 (safety scaffolding), then Phase 1 (keystone + gates + canaries).
4. [ ] Enable Phase 2 loops once Phase 0 is live; then Phase 3.
5. [ ] Mark this ADR Accepted once Phase 0–1 are in place.
