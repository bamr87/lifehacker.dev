# Runbook — the lifehacker.dev autonomy fleet (PR1: testing)

Operator notes for the testing harness shipped in PR1, and the human-gate machinery the later PRs (reporting, load-balancing) build on. This file is excluded from the site build (it lives under `docs/`).

> **The one invariant:** no agent ever merges. A pull request — including one
> opened by the autopilot bot — reaches `main` only after a code-owner review.
> Everything below exists to make that enforceable by the *repository*, not by
> an agent's good behavior.

## 1. The bot identity (do this first)

The no-self-merge guarantee depends on the autopilot running as a GitHub identity that is **not** `@bamr87`. Otherwise its approval could satisfy CODEOWNERS.

1. Create a dedicated machine account, e.g. `lifehacker-bot`.
2. Invite it to `bamr87/lifehacker.dev` as a **collaborator with Write** (not
   Admin — it must never be able to edit branch protection or workflows).
3. For upstream bug filing, give it **Triage/Write on issues** for
   `bamr87/zer0-mistakes` only.
4. When PR3 lands, the fleet authenticates as this account with a fine-grained
PAT scoped to `contents`, `issues`, `pull_requests` (write) — **no `administration`, no `workflows`** scope. A compromised agent then can't touch the gates. PR1 itself needs no bot token: CI uses the default `GITHUB_TOKEN` to post comments, and that token cannot approve PRs.

## 2. Branch protection (makes the gate real)

Run once as `@bamr87` (an admin). Confirm the required check name after the first PR run — it appears as the job id `verify` (shown as `test / verify` in some UIs; adjust `contexts` if so).

```bash
gh api -X PUT repos/bamr87/lifehacker.dev/branches/main/protection --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["verify"] },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
```

This requires the `verify` check to pass **and** a review from `@bamr87` (CODEOWNERS) before merge, blocks force-pushes, and keeps history linear. `enforce_admins:false` lets the human owner merge after reviewing; the bot, not being an admin or a code owner, cannot.

## 3. One-time: pin the bundle

CI is reproducible only with a committed lockfile. Generate it once and commit:

```bash
bundle install          # resolves github-pages + html-proofer
git add Gemfile.lock && git commit -m "ci: pin github-pages + html-proofer"
```

(`.gitignore` no longer ignores `Gemfile.lock`.)

## 4. Secrets

| Secret | Used by | Needed for |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` *or* `ANTHROPIC_API_KEY` | every AI step (`pipeline.yml` brand-review + content-review, content-factory, explore, auto-fix, devops-manager) | Claude auth. The OAuth token (`claude setup-token`, subscription auth) is preferred and drives the Claude Code path; an API key also works and is the only credential the API fallback can use. **Optional** — without either, the deterministic gate still runs; the agent tiers just skip. Set in repo → Settings → Secrets → Actions. |

`pipeline.yml` runs on `pull_request` (not `pull_request_target`), so secrets are **never** exposed to fork PRs.

## 5. Running the harness

- **Locally / in Claude Code:** `scripts/ci/run-all.sh`, or the `/test-lifehacker`
  skill. Same scripts CI runs.
- **In CI:** automatic on every PR (`.github/workflows/test.yml`). Posts a sticky
  comment and uploads `findings.jsonl`.
- **Nightly sweep:** `.github/workflows/nightly.yml` (external links, fresh-theme
  drift, full Prime Directive). Files one coarse issue on failure.

### What blocks a merge (severity: error)

- the safe-mode `jekyll build --strict` fails;
- a required front-matter key is missing / a post's filename date mismatches;
- a backlog `done` item points at a non-existent page, or a hand-authored sitemap
  link is dead;
- a broken internal link/image/anchor (html-proofer);
- a glossary `avoid_phrase` (weasel phrase) used anywhere.

### What only reports (warning / info — never blocks)

- over-length SEO descriptions;
- `banned_when_sincere` word candidates (the tier-2 reviewer comments on the
  ambiguous ones);
- Prime Directive command failures → flagged as Field Note candidates.

## 5b. Triage & reporting (PR2)

Turns the harness's findings into a ranked queue and deduplicated GitHub issues.

- **Scripts (deterministic, testable):**
  - `scripts/triage/build_queue.rb` — `findings.jsonl` → `_data/health/queue.json`
    + `summary.yml` (+ committed `findings.jsonl` snapshot). Classifies, RICE-scores,
    and dedups by the PR1 fingerprint. Severity dominates the score; reach (from
    `_data/analytics/summary.json`) is a tiebreaker that defaults to 1.0.
  - `scripts/triage/file_issues.rb [--apply] [--max-new N]` — finds-or-files an
    issue per item, deduped by the `triage-fp:` body marker. **Dry-run by default.**
    Never closes an issue; only ever touches issues carrying its own marker.
  - `scripts/triage/bootstrap-labels.sh [repo]` — idempotent label taxonomy
    (`type/* area/* severity/* source/*`).
  - `scripts/triage/gen_dashboard.rb` — writes `SITE_HEALTH.md`; the live page is
    `/docs/health/`, rendered from `_data/health/` with plain Liquid (no plugin).
- **Skill / workflow:** `/triage-lifehacker` (or `.github/workflows/triage.yml`,
`workflow_dispatch`). The workflow files **local** issues with `GITHUB_TOKEN`; **upstream** filing on `bamr87/zer0-mistakes` needs the bot PAT (set secret `FLEET_TOKEN`) — until then upstream items are reported and deferred.
- **Reach via analytics:** if the Google Analytics MCP is connected, the skill
refreshes `_data/analytics/summary.json` (`getPageViews`); headless/cron runs fall back to the committed cache. A GA outage never blocks ranking.
- **Inbound issues:** the skill classifies troll/spam/dup but **never closes a
human's issue** — it labels + drafts a reply + @-mentions the owner. All issue text is treated as untrusted (`.claude/skills/_shared/quarantine.md`).

## 5c. Orchestration / the fleet (PR3)

The dispatcher distributes work across role agents without collisions, runaway cost, or guardrail violations — deterministic Ruby on purpose (budget math and lease arbitration must be reproducible, not model judgment).

- **`scripts/fleet/policy.rb`** — the load-balancing math (pure, unit-tested):
`sev1` open → freeze growth, all slots fixing; `sev2` → one grower, rest fixing; clean → mostly growing. `MAX_OPEN_PRS` is the primitive — the dispatcher never leaves more PRs awaiting the human than the cap, so adding agents drains faster but never floods the gate. Knobs live in `_data/fleet/budget.yml`.
- **`scripts/fleet/lease.rb`** — collision-free claiming via git ref creation
(`refs/lease/<id>`, compare-and-swap with no server) + a committed `_data/fleet/leases.yml` record with a TTL so a crashed agent's lease is reclaimed. Two agents can never grab the same item.
- **`scripts/fleet/dispatch.rb`** — the OODA loop: observe (queue + backlog +
open-PR count) → decide (policy) → act (lease + spawn). **Plan-only by default**; `--apply` leases and spawns. Opens zero PRs itself.
- **`.github/workflows/fleet-dispatch.yml`** — `workflow_dispatch` only (no
schedule). Honors the kill switch; the `run.sh --prompt "/<role> <target>"` spawn commands it prints are the final wiring step (needs `CLAUDE_CODE_OAUTH_TOKEN` or `ANTHROPIC_API_KEY` + a worktree each).
- **Role agents:** `grow-lifehacker` (growth), `fleet-bugfix` (one content/infra
fix per PR), `triage-lifehacker` (reporting), `brand-reviewer` (comment-only). Each opens one PR and stops; none merges.

### Turning the fleet ON (deliberate, reversible)

1. Set the kill switch: `gh variable set FLEET_ENABLED true` (a repo **variable** —
   instant, no merge; the bot token can't set it back, having no admin scope).
2. Run it manually first: Actions → fleet-dispatch → Run (leave `apply` off to see
   the plan; check `apply` to lease + spawn).
3. To go hands-off: uncomment the `schedule:` in `fleet-dispatch.yml`, wire the
spawn step, and **add a dated bold line to `/about/colophon/`** (per AUTOPILOT.md — enabling scheduled autonomy is the guardrail change that requires it).

## 6. Kill / disable

- **Instant soft kill:** `gh variable set FLEET_ENABLED false` (or delete it). Every
  dispatch idles on the next run; no merge needed, and the bot can't undo it.
- Disable a workflow entirely: `gh workflow disable fleet-dispatch.yml` (also
  `triage.yml`, `nightly.yml`, `test.yml`).
- **Hard kill:** revoke the bot PAT — stops all fleet writes everywhere at once.

## 7. The contract (for PR2 / PR3)

Every check writes `test-results/findings.jsonl`, one finding per line:

```json
{"check_id":"…","severity":"error|warning|info","file":"…","line":12,"rule":"…","evidence":"…","route_to":"local|upstream|backlog","fingerprint":"…","prime_directive_candidate":false}
```

`fingerprint = sha1(check_id | downcased-path | rule)[0,12]` — **line excluded**,
so identity is stable as files shift. PR1 owns it; PR2 (triage) dedups against it and routes; PR3 (dispatch) ranks from it. Do not reshape these fields without updating every consumer.
