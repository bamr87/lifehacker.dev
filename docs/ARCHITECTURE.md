# Architecture — the lifehacker.dev autopilot

lifehacker.dev is a Jekyll site on GitHub Pages (rendered by the
`bamr87/zer0-mistakes` remote theme) that operates itself as a **headless CMS
driven by Claude Code**. A team of agents tests the site, reports what's wrong,
and load-balances the work — but **a human is the only commit authority.** This
doc is the map.

## Mental model

One closed loop. Production signal (failing tests, broken links, drifting data,
inbound issues, traffic) enters; deterministic code turns it into a ranked queue
and a dispatch decision; agents turn queue items into pull requests; **one human
merge gate** is the only way anything reaches `main`; GitHub Pages deploys; the
live site becomes the next cycle's signal.

```
                 ┌───────────────────────── the flywheel ─────────────────────────┐
                 ▼                                                                 │
  signal ─▶ TEST (harness) ─findings.jsonl▶ REPORT (triage) ─queue.json▶ BALANCE (fleet)
            scripts/ci          (frozen        scripts/triage   (frozen     scripts/fleet
            the gate            contract)      ranked queue      contract)   the dispatcher
                 │                                                                 │
                 └──────────────▶  role agents open ONE PR each  ◀────────────────┘
                                            │
                                   HUMAN MERGE GATE   ← branch protection + CODEOWNERS
                                   (the only commit authority; no agent can bypass)
                                            │
                                   GitHub Pages deploys main ─▶ live site ─▶ signal
```

## The three layers + their contracts

| Layer | Owns | Key files | Produces / consumes |
|---|---|---|---|
| **Test** | Is the site correct? Reproduces GitHub Pages safe mode (overlay the theme, strip `_plugins`), then lints build, front matter, links, drift, brand voice, and *runs* hack commands in a sandbox. | `scripts/ci/` (`build.sh`, `lint_*.rb`, `check_drift.rb`, `run_hack_commands.rb`, `htmlproofer_check.rb`, `record_build.rb`, `aggregate.rb`) | **Writes** `test-results/findings.jsonl` |
| **Report** | What's broken and what matters most? Dedups findings by fingerprint, RICE-ranks them (severity dominates; traffic tiebreaks), files deduplicated GitHub issues, publishes `/docs/health/`. | `scripts/triage/` (`build_queue.rb`, `file_issues.rb`, `gen_dashboard.rb`, `bootstrap-labels.sh`) | **Reads** findings.jsonl · **writes** `_data/health/queue.json` |
| **Balance** | What should the fleet do now, without flooding the human? Budget split by site health, collision-free leasing, caps, kill switch. | `scripts/fleet/` (`policy.rb`, `plan.rb`, `lease.rb`, `dispatch.rb`) | **Reads** queue.json + backlog.yml |

The **frozen contracts** are the seams:

- `findings.jsonl` — one finding per line: `{check_id, severity, file, line, rule,
  evidence, route_to, fingerprint, prime_directive_candidate}`. `fingerprint =
  sha1(check_id | downcased-path | rule)[0,12]` — line excluded, so identity is
  stable as files shift. The *only* sev1 producer is `record_build.rb` (the build
  break the fleet freezes growth on), used by every harness entrypoint.
- `queue.json` — one ranked work item per fingerprint: `{fingerprint, type, area,
  severity (sev1–4), route, repo, url_path, reach_views, score, occurrences,
  prime_directive_candidate, issue_number, blocked_on}`.

## The deterministic / judgment split

Everything load-bearing and auditable is **plain Ruby** (the fingerprint scheme,
the RICE math, the budget policy, the lease CAS, the dispatch decision). Models
do only the **judgment** work, inside leased role agents: `grow-lifehacker`
(content), `fleet-bugfix` (one content/infra fix per PR), `triage-lifehacker`
(reporting), `brand-reviewer` (sincere-vs-satire), `devops-manager` (the pipeline
itself). The split is why the system can be simulated end-to-end and why a model
mistake can, at worst, open a PR — never merge one.

## Invariants (enforced in code, not prose)

1. **No push to `main`, no self-merge.** Branch protection + `CODEOWNERS @bamr87`
   + a distinct bot identity. This makes prompt injection non-catastrophic: the
   worst case is a label or a spam PR, never a merge.
2. **One frozen `findings.jsonl` contract**, one `record_build.rb` sev1 producer.
3. **Single writer per shared file** — all data writes go through the PR/merge
   gate; the sitemap's drift-prone block self-heals via Liquid (no unattended
   writer).
4. **Fail-safe fleet** — a missing/stale queue dispatches *nothing* (absence is
   never read as "safe to grow"); `FLEET_ENABLED` (a repo variable the bot can't
   set) is the kill switch; `MAX_OPEN_PRS` clamps throughput to review speed.
5. **Untrusted input is data, never instructions** (`_shared/quarantine.md`).
6. **Loosening any guardrail requires a dated line in `/about/colophon/`.**

The end-to-end simulation (`scripts/sim/simulate.rb`, 15 scenarios / 50
assertions) is the regression net for every one of these.

## How to extend

- **Add a test:** a `scripts/ci/*.rb` that emits findings in the frozen shape via
  `LH.finding`; add it to `run-all.sh` and `aggregate.rb`'s `CHECK_FILES`. Map its
  `check_id`/`rule` to a tier in `Triage.classify`. Add a sim assertion to the
  severity-tier table.
- **Add a triage rule:** extend `Triage.classify` (type/area/severity/route) and,
  if needed, the RICE inputs in `Triage.score`. Add a sim scenario.
- **Add a fleet role:** a `.claude/skills/<role>/SKILL.md` that opens one PR and
  never merges; teach `Fleet::Plan.compute` when to dispatch it (key off `type`).

## Learning loop (memory across threads AND across runs)

The autopilot runs inside Claude Code threads, and each thread learns things that
otherwise die with its context window. The **session-retrospective hook** captures
that: a `SessionEnd` hook (`.claude/settings.json` → `.claude/hooks/retrospective-enqueue.rb`)
queues every finished thread, and the `session-retrospective` agent later reads the
transcript and publishes an honest Field Note about what the thread learned —
indexed in `_data/retrospectives.yml`. So the *next* thread starts knowing what the
last one cost. See `docs/RETROSPECTIVE-HOOK.md`.

The **machine itself** has the same property (see "The compounding loop" in
`AUTOPILOT.md`): the loop-tuner records every tuning change in
`_data/fleet/improvements.yml` with the metric it claims to move and its
baseline, appends a per-run snapshot to `_data/metrics/history.jsonl`, and the
next run's first job is settling those claims deterministically
(`scripts/devops/verify_improvements.rb`) — verified changes compound, regressed
ones get fixed or reverted first, abandoned hypotheses are never re-tried. Both
memories are committed data behind the same human merge gate.

See `docs/CICD.md` for the pipeline and `docs/RETROSPECTIVE.md` for how it was
built (and the bugs the harness caught building it).
