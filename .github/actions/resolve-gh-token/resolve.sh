#!/usr/bin/env bash
# =============================================================================
# resolve.sh — pick a GitHub token that actually WORKS, not merely one that is set
# -----------------------------------------------------------------------------
# The bug this exists to prevent (bamr87/bamr87#53):
#
#   GH_TOKEN: ${{ secrets.FLEET_TOKEN || github.token }}
#
# `||` in a GitHub Actions expression returns the first non-falsy operand, and an
# EXPIRED PAT is a perfectly non-empty string. So an expired FLEET_TOKEN wins the
# `||`, `github.token` is never reached, and the documented "degrade to a
# human-reviewed PR" path is unreachable. An expired secret ends up strictly
# WORSE than no secret at all — the inverse of the intent. content-scout burned
# 11 consecutive days (2026-07-25 → 08-04) that way: ~10 minutes of agent work
# per run, pushed to a branch, then a 401 on `gh pr create`.
#
# Presence is not validity. This probes the candidate against the API and falls
# back when it is missing OR rejected, so a future expiry costs one warning
# instead of days of silence.
#
# Inputs (environment):
#   CANDIDATE       the preferred token (e.g. FLEET_TOKEN). May be empty.
#   FALLBACK        the token to degrade to — normally github.token.
#   CANDIDATE_NAME  name used in log lines. Default: FLEET_TOKEN.
#   EXPORT_GH_TOKEN 'true' (default) to export GH_TOKEN to later steps.
#
# Outputs:
#   $GITHUB_OUTPUT  source=fleet|default
#   $GITHUB_ENV     GH_TOKEN=<chosen>   (when EXPORT_GH_TOKEN=true)
#
# Exit status is 0 on BOTH paths: degrading is a warning, not a failure. The
# point is to keep delivering, loudly — not to trade a late red run for an
# early one.
#
# Unit tests: scripts/ci/test_resolve_gh_token.sh (stubs `gh` on PATH).
# =============================================================================
set -euo pipefail

NAME="${CANDIDATE_NAME:-FLEET_TOKEN}"
CANDIDATE="${CANDIDATE:-}"
FALLBACK="${FALLBACK:-}"

# Writable even outside Actions, so the script is testable as a plain script.
: "${GITHUB_OUTPUT:=/dev/null}"
: "${GITHUB_ENV:=/dev/null}"

source="default"
chosen="$FALLBACK"

if [ -z "$CANDIDATE" ]; then
  echo "::notice::${NAME} is not set — using github.token. A PR will still open, for a human; it will not auto-merge."
elif GH_TOKEN="$CANDIDATE" gh api user --silent >/dev/null 2>&1; then
  source="fleet"
  chosen="$CANDIDATE"
  echo "${NAME} accepted by the API — using it."
else
  # The case the `||` form could not see.
  echo "::warning::${NAME} is set but REJECTED by the API (expired or revoked) — falling back to github.token. The PR will open for a human and will not auto-merge. Rotate the secret: gh secret set ${NAME} -R \"\${GITHUB_REPOSITORY}\""
fi

if [ -z "$chosen" ]; then
  echo "::error::No usable token: ${NAME} is unusable and no fallback was supplied."
  exit 1
fi

echo "source=${source}" >> "$GITHUB_OUTPUT"

if [ "${EXPORT_GH_TOKEN:-true}" = "true" ]; then
  echo "GH_TOKEN=${chosen}" >> "$GITHUB_ENV"
fi
