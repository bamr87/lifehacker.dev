#!/usr/bin/env bash
# =============================================================================
# scripts/sim/bootstrap.sh — bootstrap the whole autopilot end-to-end, locally
# -----------------------------------------------------------------------------
# Drives all three layers in one command, then runs the synthetic E2E
# simulation. Use it to see the combined system work without GitHub, secrets, or
# the live site:
#   1. TEST    — run the real harness over the repo -> test-results/findings.jsonl
#   2. REPORT  — rank findings -> _data/health/queue.json + the dashboard
#   3. BALANCE — the dispatcher's plan for this state (plan-only, never mutates)
#   4. SIMULATE— synthetic scenarios assert the contracts between the layers
#
# Exit code is the simulation's (the load-bearing assertion). The earlier stages
# are demonstrations and never fail the bootstrap.
#
#   scripts/sim/bootstrap.sh                 # skips the slow jekyll build by default
#   LH_FULL_BUILD=1 scripts/sim/bootstrap.sh # also run the real safe-mode build
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
cd "$REPO"

line() { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }

line "1/4  TEST — run the verification harness"
if [[ "${LH_FULL_BUILD:-0}" == "1" ]]; then
  bash scripts/ci/run-all.sh || true
else
  LH_SKIP_BUILD=1 bash scripts/ci/run-all.sh || true
fi

line "2/4  REPORT — rank findings into the queue + dashboard"
ruby scripts/triage/build_queue.rb || true
ruby scripts/triage/gen_dashboard.rb || true

line "3/4  BALANCE — the dispatcher's plan for this state (plan-only)"
FLEET_ENABLED=true ruby scripts/fleet/dispatch.rb || true

line "4/4  SIMULATE — synthetic scenarios assert the end-to-end contracts"
ruby scripts/sim/simulate.rb
rc=$?

line "bootstrap complete"
echo "Queue: $(ruby -rjson -e 'puts JSON.parse(File.read("_data/health/queue.json")).size rescue 0') item(s) · simulation exit=$rc"
exit $rc
