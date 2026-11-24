# Rotating `CLAUDE_CODE_OAUTH_TOKEN`

> Where the org's Claude credential lives, which workflows read it, and the procedure the org owner follows to re-mint it and store it without the value reaching a terminal log, a file or a commit.

`CLAUDE_CODE_OAUTH_TOKEN` is the primary model credential for everything this hub runs: the growth engine, the planter and the PR reviewers. `claude setup-token` mints it in a browser, against the Claude subscription of whoever signs in, and saves it nowhere. No workflow can re-mint it, so rotating it is always a job for the org owner. This page is that job, written down.

## Where it lives and who reads it

- **Scope:** an **organization-level** Actions secret on `ai-world-view`, shared with every repository in the org (`ai-world-view.github.io`, `china`, `japan`, `north-korea`, `south-korea` as of 2026-11-11). No repository carries its own copy. Check with `gh api repos/ai-world-view/<repo>/actions/organization-secrets --jq '.secrets[] | "\(.name) \(.updated_at)"'`, which lists names and dates, never values.
- **Readers:** only this hub's workflows. The country repos hold content and no workflows, so nothing there reads it.

| Workflow | What it uses the token for |
| --- | --- |
| `grow-lineage.yml` | The three growth passes and the Illustrate step of every tick |
| `plant-lineage.yml` | The DECIDE pass that authors a new country's seed |
| `ai-content-review.yml` | The Claude tier of the PR content review |
| `framework-pr-reviewer.yml` | The framework PR gate's model pass |
| `claude.yml` | `@claude` mentions, when the auth order picks OAuth |
| `secret-expiry-watch.yml` | The daily one-turn probe that tells us the token still works |
| `verify.yml` | The optional agent pass (label `verify`), through `secrets: inherit` |

`LIFECYCLE_PAT` is the org's other secret. The same daily probe watches it, and it is rotated in GitHub's token settings, not with this procedure.

## When to rotate

- `secret-expiry-watch` opens or updates the issue **"Secret Expiry Watch — credential degraded"** naming `CLAUDE_CODE_OAUTH_TOKEN`. The probe's log says why: look for the `result` line of the "Probe CLAUDE_CODE_OAUTH_TOKEN" step (`gh run view <id> --log`).
- The token is close to a year old. A `claude setup-token` credential lasts one year, and the secret's `updated_at` is its age.
- The value may have been exposed. Rotate first, investigate second.

## Procedure

Run this on the owner's own machine. Steps 1 and 3 open a browser, so no agent or workflow can do them.

1. **Give `gh` the org-secrets scope, once.** Reading or writing an organization secret needs `admin:org`, which the default `gh` login does not carry.

   ```bash
   gh auth refresh -h github.com -s admin:org
   ```

2. **Read the secret's current visibility**, so the rotation does not change who can read it.

   ```bash
   gh api orgs/ai-world-view/actions/secrets/CLAUDE_CODE_OAUTH_TOKEN --jq .visibility
   ```

   Expect `all` or `selected`. Every member repository is public, and a `private` secret is invisible to public repositories.

3. **Mint the new token.** Sign in with the Claude account whose subscription the fleet runs on, then copy the token it shows. It is displayed once.

   ```bash
   claude setup-token
   ```

4. **Store it straight from the clipboard**, then empty the clipboard. The value is never typed, echoed or written to disk.

   ```bash
   pbpaste | gh secret set CLAUDE_CODE_OAUTH_TOKEN --org ai-world-view --visibility all && pbcopy < /dev/null
   ```

   If step 2 printed `selected`, keep that list instead: replace `--visibility all` with `--repos ai-world-view.github.io,china,japan,north-korea,south-korea`. Without a clipboard tool, run `gh secret set CLAUDE_CODE_OAUTH_TOKEN --org ai-world-view --visibility all` with no pipe and paste at its hidden prompt.

   **Always pass the visibility.** `gh secret set --org` defaults to `--visibility private`, which would hide the secret from all five public repositories and stop every lane above.

5. **Prove it works.** Dispatch the probe, give it two minutes, then look for the issue. The run is green whether or not the credential is healthy, so read the verdict, not the conclusion: its last step prints `LIFECYCLE_PAT: ok | CLAUDE_CODE_OAUTH_TOKEN: ok`, and a healthy run closes the "credential degraded" issue by itself.

   ```bash
   gh workflow run secret-expiry-watch.yml --repo ai-world-view/ai-world-view.github.io
   gh issue list --repo ai-world-view/ai-world-view.github.io --state open --search "Secret Expiry Watch in:title"
   ```

   An empty list means the probe passed and closed the issue.

6. **Record it** in the log below: the date, the reason and the issue. Never the value.

## Rules

- The token goes from the browser to the clipboard to `gh secret set`, and nowhere else. No `--body "<token>"` (it lands in shell history), no `.env` in this repository, no issue, PR, commit or chat message.
- Nothing prints a secret. To see whether a rotation landed, read the secret's `updated_at`, not its value.
- An agent may prepare this procedure and verify the result. It never runs `claude setup-token` and never handles the value.

## Rotation log

| Date | Event |
| --- | --- |
| 2026-08-18 | Secret last set (`updated_at`). |
| 2026-09-19 | `secret-expiry-watch` opened [#29](https://github.com/ai-world-view/ai-world-view.github.io/issues/29): `CLAUDE_CODE_OAUTH_TOKEN` degraded. |
| 2026-11-11 | The probe still fails with HTTP 401, "OAuth token revoked" ([run 43093812471](https://github.com/ai-world-view/ai-world-view.github.io/actions/runs/43093812471)); `LIFECYCLE_PAT` probes `ok`. No `ANTHROPIC_API_KEY` is shared with the org's repositories, so the lanes have no fallback while the OAuth token is dead. This procedure was written; the re-mint is pending the owner. |
