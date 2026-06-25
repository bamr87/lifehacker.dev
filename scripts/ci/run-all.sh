#!/usr/bin/env bash
# =============================================================================
# run-all.sh — run the whole lifehacker.dev test harness, then aggregate.
# -----------------------------------------------------------------------------
# Build is the hard gate (a non-building site is the finding). The lint checks
# then run even if one fails (so you get the full picture in one pass), and
# aggregate.rb produces findings.jsonl + the verdict exit code.
#
#   scripts/ci/run-all.sh             # full run incl. build
#   LH_SKIP_BUILD=1 scripts/ci/run-all.sh   # reuse an existing _site/
# =============================================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
cd "$REPO"
rm -rf test-results

# Build, but DON'T early-exit on failure: record the sev1 build finding and keep
# going so aggregate still emits a findings.jsonl (the worst case must be the
# loudest, not the emptiest — triage/fleet downstream depend on it existing).
# CI builds once via the cached build-overlay action and passes the outcome in
# LH_BUILD_RC (with LH_SKIP_BUILD=1), so the harness never double-builds.
build_rc="${LH_BUILD_RC:-0}"
if [[ "${LH_SKIP_BUILD:-0}" != "1" ]]; then
  bash "$HERE/build.sh" build
  build_rc=$?
fi
ruby "$HERE/record_build.rb" "$build_rc"
[[ "$build_rc" != "0" ]] && echo "BUILD FAILED — recorded as sev1; continuing to lint + aggregate"

# Each check writes its own test-results/<check>.json; keep going on failure.
ruby "$HERE/lint_frontmatter.rb"   || true
ruby "$HERE/check_drift.rb"        || true
ruby "$HERE/lint_brand.rb"         || true
ruby "$HERE/lint_artifacts.rb"     || true
ruby "$HERE/run_hack_commands.rb"  || true
ruby "$HERE/htmlproofer_check.rb"  || true

# Aggregate decides the gate (exit non-zero iff any error-severity finding).
ruby "$HERE/aggregate.rb"
