#!/usr/bin/env bash
# =============================================================================
# scripts/scout/bootstrap-labels.sh — content-scout label namespace (idempotent)
# -----------------------------------------------------------------------------
# The content-scout opens ONE PR per run carrying its backlog additions. It is
# labeled `auto:content` (so the auto-merge gate recognizes it, same as a factory
# PR) plus a source label so a human can tell at a glance where the ideas came
# from. `gh label create --force` upserts, so re-running is safe.
#
#   scripts/scout/bootstrap-labels.sh [owner/repo]   (default: bamr87/lifehacker.dev)
#
# FAILURE POLICY (bamr87/bamr87#53). This used to be invoked as `… || true`, so
# the FIRST `HTTP 401: Bad credentials` of a dead-PAT run was swallowed here at
# second one and the workflow marched on for another ~12 minutes before failing
# at `gh pr create`. The mask is gone; instead this script tells the difference
# between the two failures it can have:
#
#   * auth failure  -> ::error:: and exit 1. Nothing downstream can be
#                      delivered with a credential the API refuses, so stopping
#                      now saves the whole agent run.
#   * anything else -> ::warning:: and exit 0. A label that could not be
#                      upserted is cosmetic; it must not block the scout.
#
# The workflow's preflight (.github/actions/resolve-gh-token) should already
# have degraded to github.token before we get here, so reaching the auth branch
# means even that is unusable — genuinely fatal.
# =============================================================================
set -euo pipefail
REPO="${1:-bamr87/lifehacker.dev}"

echo "==> content-scout labels on $REPO"

# Probe once, so a dead credential is reported as a credential problem rather
# than as a mysterious label failure.
if ! auth_err="$(gh api user --silent 2>&1)"; then
  echo "::error::content-scout cannot authenticate to the GitHub API — labels not bootstrapped and the run cannot open a PR. Rotate the credential: gh secret set FLEET_TOKEN -R ${REPO}"
  echo "  gh api user said: ${auth_err}"
  exit 1
fi

label() {
  local name="$1" color="$2" desc="$3" err
  if err="$(gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force 2>&1)"; then
    echo "  $name"
    return 0
  fi
  if grep -qiE 'bad credentials|401|requires authentication' <<<"$err"; then
    echo "::error::content-scout lost API authentication while creating '${name}'. Rotate the credential: gh secret set FLEET_TOKEN -R ${REPO}"
    echo "  gh said: ${err}"
    exit 1
  fi
  # Non-auth (rate limit, transient 5xx, permissions on one label): cosmetic.
  echo "::warning::could not upsert label '${name}' on ${REPO} — continuing without it. gh said: ${err}"
  return 0
}

label "source/content-scout" "0e8a16" "Backlog ideas scouted from a sister site (it-journey.dev)"
echo "==> done"
