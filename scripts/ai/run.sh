#!/usr/bin/env bash
# =============================================================================
# scripts/ai/run.sh — a SHIM to the fleet's universal AI runner. No logic here.
# -----------------------------------------------------------------------------
# The runner (hub kit `ai-runner`) lives in bamr87/bamr87 at
# .github/actions/claude-run/run.sh and is consumed by reference: workflows use
# `uses: bamr87/bamr87/.github/actions/claude-run@main`. This shim exists for the
# two callers that are not a workflow step — a human running a fleet agent
# locally (.vscode/tasks.json) and a skill the agent runs from inside its own
# session (scripts/preview/illustrate.mjs). It finds the runner, in order:
#   1. $AI_RUNNER      — exported by the hub action for nested calls in CI
#   2. $FLEET_HUB      — a local clone of bamr87/bamr87
#   3. ../bamr87       — the sibling clone the workspace usually has
#   4. a daily-refreshed download of the hub's main copy (needs network)
# and runs it with AI_REPO_ROOT pointed at THIS repo. Same flags, same exit
# contract, same env (see the kit README: templates/ai-runner/ in the hub).
# =============================================================================
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HUB_RUNNER=".github/actions/claude-run/run.sh"
if [ -n "${AI_RUNNER:-}" ] && [ -f "$AI_RUNNER" ]; then exec env AI_REPO_ROOT="$REPO" bash "$AI_RUNNER" "$@"; fi
for hub in "${FLEET_HUB:-}" "$REPO/../bamr87" "$REPO/../../bamr87"; do
  [ -n "$hub" ] && [ -f "$hub/$HUB_RUNNER" ] && exec env AI_REPO_ROOT="$REPO" bash "$hub/$HUB_RUNNER" "$@"
done
cache="${XDG_CACHE_HOME:-$HOME/.cache}/fleet-hub"; mkdir -p "$cache"
if [ ! -f "$cache/run.sh" ] || [ -n "$(find "$cache/run.sh" -mmin +1440 2>/dev/null)" ]; then
  if ! curl -fsSL "https://raw.githubusercontent.com/bamr87/bamr87/main/$HUB_RUNNER" -o "$cache/run.sh.tmp"; then
    [ -f "$cache/run.sh" ] || { echo "::error::scripts/ai/run.sh: cannot find the fleet runner — no \$AI_RUNNER, no hub clone at \$FLEET_HUB or ../bamr87, and the download failed" >&2; exit 1; }
    echo "::warning::scripts/ai/run.sh: refresh of the fleet runner failed — using the cached copy" >&2
  else
    mv "$cache/run.sh.tmp" "$cache/run.sh"
  fi
fi
exec env AI_REPO_ROOT="$REPO" bash "$cache/run.sh" "$@"
