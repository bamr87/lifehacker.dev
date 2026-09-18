#!/usr/bin/env bash
# =============================================================================
# test_resolve_gh_token.sh — unit tests for the token preflight
# -----------------------------------------------------------------------------
# Covers .github/actions/resolve-gh-token/resolve.sh by stubbing `gh` on PATH so
# `gh api user` can be made to succeed (exit 0) or fail (exit 1) on demand — no
# network, no real credentials.
#
# The case that matters is case 2: a NON-EMPTY but REJECTED candidate must
# select `default`. That is precisely what `${{ secrets.X || github.token }}`
# gets wrong, and case 5 pins the contrast by modelling the old expression's
# semantics directly — it selects `fleet` for a token the API refuses, which is
# the bug in bamr87/bamr87#53.
#
#   scripts/ci/test_resolve_gh_token.sh
# =============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SUT="$REPO/.github/actions/resolve-gh-token/resolve.sh"

if [[ ! -f "$SUT" ]]; then
  echo "FAIL: $SUT does not exist"
  exit 1
fi

pass=0
fail=0

# Build a throwaway PATH whose `gh` exits with $1.
stub_gh() {
  local rc="$1" dir
  dir="$(mktemp -d)"
  printf '#!/usr/bin/env bash\nexit %s\n' "$rc" > "$dir/gh"
  chmod +x "$dir/gh"
  echo "$dir"
}

# run_case <name> <gh-exit> <candidate> <fallback> <want-source> <want-token> [want-log-re]
#
# `want-log-re` is optional. When given, the annotation the composite printed on
# stdout must match it — the degraded path is only correct if the operator is
# TOLD it degraded, so silence there is a defect even when the token is right.
run_case() {
  local name="$1" gh_rc="$2" candidate="$3" fallback="$4" want_source="$5" want_token="$6"
  local want_log_re="${7:-}"
  local stub work out env_file rc got_source got_token

  stub="$(stub_gh "$gh_rc")"
  work="$(mktemp -d)"
  out="$work/output"; env_file="$work/env"
  : > "$out"; : > "$env_file"

  PATH="$stub:$PATH" \
  CANDIDATE="$candidate" \
  FALLBACK="$fallback" \
  CANDIDATE_NAME="FLEET_TOKEN" \
  EXPORT_GH_TOKEN="true" \
  GITHUB_OUTPUT="$out" \
  GITHUB_ENV="$env_file" \
    bash "$SUT" >"$work/stdout" 2>&1
  rc=$?

  got_source="$(sed -n 's/^source=//p' "$out")"
  got_token="$(sed -n 's/^GH_TOKEN=//p' "$env_file")"

  if [[ "$rc" -ne 0 ]]; then
    echo "  FAIL $name — exited $rc"; sed 's/^/        /' "$work/stdout"; ((fail++))
  elif [[ "$got_source" != "$want_source" ]]; then
    echo "  FAIL $name — source: want '$want_source', got '$got_source'"; ((fail++))
  elif [[ "$got_token" != "$want_token" ]]; then
    echo "  FAIL $name — GH_TOKEN: want '$want_token', got '$got_token'"; ((fail++))
  elif [[ -n "$want_log_re" ]] && ! grep -Eq "$want_log_re" "$work/stdout"; then
    echo "  FAIL $name — annotation: want match /$want_log_re/, got:"
    sed 's/^/        /' "$work/stdout"; ((fail++))
  else
    echo "  ok   $name"; ((pass++))
  fi

  rm -rf "$stub" "$work"
}

echo "==> resolve-gh-token"

# 1. Valid PAT: the API accepts it, so keep it — auto-merge path preserved.
run_case "valid PAT is used"                      0 "fleet-pat" "gh-token" "fleet"   "fleet-pat"

# 2. THE REGRESSION. Non-empty but rejected (expired/revoked) => degrade.
#    `${{ secrets.X || github.token }}` returns the PAT here. That is the bug.
#    A rejected PAT must also be ANNOUNCED as a ::warning:: — this is the only
#    signal a human gets that the secret needs rotating, and a silent degrade
#    is how an expiry goes unnoticed for ten days (bamr87/bamr87#59).
run_case "expired PAT degrades to github.token"   1 "expired-pat" "gh-token" "default" "gh-token" \
  '^::warning::FLEET_TOKEN is set but REJECTED'

# 3. Unset PAT: degrade without even probing. A MISSING secret is a notice, not
#    a warning — nothing is broken, so it must not cry wolf like case 2 does.
run_case "absent PAT degrades to github.token"    1 ""           "gh-token" "default" "gh-token" \
  '^::notice::FLEET_TOKEN is not set'

# 4. Unset PAT with a passing probe still degrades (empty is never probed).
run_case "empty candidate is never probed"        0 ""           "gh-token" "default" "gh-token"

# 5. Contrast case: model the OLD `||` semantics and show they disagree with the
#    fix exactly where it counts. This documents the defect rather than testing
#    production code, so it asserts against a local reimplementation.
old_expression_choice() { [[ -n "$1" ]] && echo "$1" || echo "$2"; }
old_choice="$(old_expression_choice "expired-pat" "gh-token")"
if [[ "$old_choice" == "expired-pat" ]]; then
  echo "  ok   old '||' form would have selected the expired PAT (the bug, reproduced)"
  ((pass++))
else
  echo "  FAIL old '||' form did not reproduce as documented"
  ((fail++))
fi

echo "[resolve-gh-token] $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
