# Runbook — the lifehacker.dev autonomy fleet (PR1: testing)

Operator notes for the testing harness shipped in PR1, and the human-gate
machinery the later PRs (reporting, load-balancing) build on. This file is
excluded from the site build (it lives under `docs/`).

> **The one invariant:** no agent ever merges. A pull request — including one
> opened by the autopilot bot — reaches `main` only after a code-owner review.
> Everything below exists to make that enforceable by the *repository*, not by
> an agent's good behavior.

## 1. The bot identity (do this first)

The no-self-merge guarantee depends on the autopilot running as a GitHub identity
that is **not** `@bamr87`. Otherwise its approval could satisfy CODEOWNERS.

1. Create a dedicated machine account, e.g. `lifehacker-bot`.
2. Invite it to `bamr87/lifehacker.dev` as a **collaborator with Write** (not
   Admin — it must never be able to edit branch protection or workflows).
3. For upstream bug filing, give it **Triage/Write on issues** for
   `bamr87/zer0-mistakes` only.
4. When PR3 lands, the fleet authenticates as this account with a fine-grained
   PAT scoped to `contents`, `issues`, `pull_requests` (write) — **no
   `administration`, no `workflows`** scope. A compromised agent then can't touch
   the gates. PR1 itself needs no bot token: CI uses the default `GITHUB_TOKEN`
   to post comments, and that token cannot approve PRs.

## 2. Branch protection (makes the gate real)

Run once as `@bamr87` (an admin). Confirm the required check name after the first
PR run — it appears as the job id `verify` (shown as `test / verify` in some UIs;
adjust `contexts` if so).

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

This requires the `verify` check to pass **and** a review from `@bamr87`
(CODEOWNERS) before merge, blocks force-pushes, and keeps history linear.
`enforce_admins:false` lets the human owner merge after reviewing; the bot, not
being an admin or a code owner, cannot.

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
| `ANTHROPIC_API_KEY` | `test.yml` → `brand-review` job | The paid tier-2 brand review. **Optional** — without it the deterministic gate still runs; tier-2 just skips. Set it in repo → Settings → Secrets → Actions. |

`test.yml` runs on `pull_request` (not `pull_request_target`), so secrets are
**never** exposed to fork PRs.

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

## 6. Kill / disable

- Disable a workflow: `gh workflow disable test.yml` (and `nightly.yml`).
- Revoke the bot's PAT to stop all fleet writes instantly (PR3).
- PR3 adds a `FLEET_ENABLED` repo variable as the soft kill switch the bot can't
  flip.

## 7. The contract (for PR2 / PR3)

Every check writes `test-results/findings.jsonl`, one finding per line:

```json
{"check_id":"…","severity":"error|warning|info","file":"…","line":12,"rule":"…","evidence":"…","route_to":"local|upstream|backlog","fingerprint":"…","prime_directive_candidate":false}
```

`fingerprint = sha1(check_id | downcased-path | rule)[0,12]` — **line excluded**,
so identity is stable as files shift. PR1 owns it; PR2 (triage) dedups against it
and routes; PR3 (dispatch) ranks from it. Do not reshape these fields without
updating every consumer.
