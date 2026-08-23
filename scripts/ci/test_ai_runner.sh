#!/usr/bin/env bash
# =============================================================================
# test_ai_runner.sh — unit tests for the universal AI runner's exit contract
# -----------------------------------------------------------------------------
# Covers scripts/ai/run.sh by stubbing `claude` on PATH so a run can be made to
# succeed, to fail with a real `--output-format json` error payload, or to be
# missing entirely — no network, no credentials, no tokens spent.
#
# The case that matters is case 2: a call that was ATTEMPTED and REJECTED, with
# no ANTHROPIC_API_KEY to fall back to, must exit NON-ZERO and name the reason.
# It used to exit 0, which is how six days of content-factory runs (2026-08-17
# onward) reported a dead credential as "no PR was opened — auth? duplicate?
# build failure?" one step downstream, with the error payload already deleted.
# Case 4 pins the other half: a genuine no-op (nothing ever attempted) stays
# exit 0, so a human running a skill locally without credentials still degrades
# gracefully instead of aborting.
#
#   scripts/ci/test_ai_runner.sh
# =============================================================================
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
SUT="$REPO/scripts/ai/run.sh"

if [[ ! -f "$SUT" ]]; then
  echo "FAIL: $SUT does not exist"
  exit 1
fi

pass=0
fail=0

# A throwaway PATH whose `claude` prints $2 on stdout and exits $1. An empty $2
# means "print nothing" (the CLI died before producing a payload).
stub_claude() {
  local rc="$1" payload="${2:-}" dir
  dir="$(mktemp -d)"
  {
    printf '#!/usr/bin/env bash\n'
    printf 'cat <<'"'"'STUBJSON'"'"'\n%s\nSTUBJSON\n' "$payload"
    printf 'exit %s\n' "$rc"
  } > "$dir/claude"
  chmod +x "$dir/claude"
  echo "$dir"
}

# run_case <name> <stub-dir|"none"> <want-rc> [want-stdout-substring] [want-stderr-substring]
run_case() {
  local name="$1" stub="$2" want_rc="$3" want_out="${4:-}" want_err="${5:-}"
  local outf errf rc usage_dir path
  outf="$(mktemp)"; errf="$(mktemp)"; usage_dir="$(mktemp -d)"
  # A PATH that keeps ruby/coreutils but holds only the stub `claude` we chose.
  path="${stub}:/usr/local/bin:/usr/bin:/bin"
  [[ "$stub" == "none" ]] && path="/usr/local/bin:/usr/bin:/bin"

  env -i \
    PATH="$path" \
    HOME="${HOME:-/root}" \
    LH_AI_USAGE_DIR="$usage_dir" \
    CLAUDE_CODE_OAUTH_TOKEN="stub-token" \
    bash "$SUT" --prompt "hello" --agent test-agent >"$outf" 2>"$errf"
  rc=$?

  local why=""
  [[ "$rc" != "$want_rc" ]] && why="exit $rc, wanted $want_rc"
  if [[ -z "$why" && -n "$want_out" ]] && ! grep -qF "$want_out" "$outf"; then
    why="stdout missing '$want_out'"
  fi
  if [[ -z "$why" && -n "$want_err" ]] && ! grep -qF "$want_err" "$errf"; then
    why="stderr missing '$want_err'"
  fi

  if [[ -z "$why" ]]; then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name — $why"
    echo "  stdout: $(head -c 300 "$outf")"
    echo "  stderr: $(head -c 300 "$errf")"
    fail=$((fail + 1))
  fi
  rm -rf "$outf" "$errf" "$usage_dir"
}

OK_JSON='{"type":"result","subtype":"success","is_error":false,"duration_ms":1200,"num_turns":2,"session_id":"s1","total_cost_usd":0.01,"usage":{"input_tokens":10,"output_tokens":5},"modelUsage":{"claude-opus-4-8":{"inputTokens":10,"outputTokens":5,"costUSD":0.01}},"result":"THE ANSWER"}'
# The shape a rejected call actually produced on 2026-08-22: one turn, ~1.8s,
# zero tokens, no model, is_error — the request never reached the model.
ERR_JSON='{"type":"result","subtype":"error_during_execution","is_error":true,"duration_ms":1803,"num_turns":1,"session_id":"s2","total_cost_usd":0,"usage":{"input_tokens":0,"output_tokens":0},"result":"Claude AI usage limit reached"}'

s_ok="$(stub_claude 0 "$OK_JSON")"
s_err="$(stub_claude 1 "$ERR_JSON")"
s_silent="$(stub_claude 1 "")"

# 1. A clean run emits the result text and succeeds.
run_case "success: emits result text, exit 0" "$s_ok" 0 "THE ANSWER"

# 2. THE REGRESSION: rejected call, no fallback key -> exit 1, reason + hint.
run_case "rejected call: exit 1 and names the reason" "$s_err" 1 "" "usage limit reached"
run_case "rejected call: names the operator action" "$s_err" 1 "" "likely cause:"

# 3. A CLI that dies without a payload is still a failure, not a no-op.
run_case "no payload: still exit 1" "$s_silent" 1 "" "Claude Code failed"

# 4. Nothing attempted (no claude, no key) stays a graceful no-op.
run_case "no claude, no key: no-op exit 0" "none" 0 "" "no-op"

# 5. An exit-0 run whose payload carries is_error is a failure too — and it must
#    record its usage exactly ONCE. That path already ingested on the way in, so
#    a second ingest in the failure branch would double-count the call in the
#    step summary and the ledger.
ERR0_JSON='{"type":"result","subtype":"error_during_execution","is_error":true,"duration_ms":900,"num_turns":1,"session_id":"s3","total_cost_usd":0,"usage":{"input_tokens":3,"output_tokens":0},"result":"authentication_error: invalid api key"}'
s_err0="$(stub_claude 0 "$ERR0_JSON")"
run_case "exit 0 but is_error: still exit 1" "$s_err0" 1 "" "unusable result"

usage_dir="$(mktemp -d)"
env -i PATH="${s_err0}:/usr/local/bin:/usr/bin:/bin" HOME="${HOME:-/root}" \
  LH_AI_USAGE_DIR="$usage_dir" CLAUDE_CODE_OAUTH_TOKEN="stub-token" \
  bash "$SUT" --prompt "hello" --agent test-agent >/dev/null 2>&1
n="$(wc -l < "$usage_dir/records.jsonl" 2>/dev/null | tr -d ' ')"
if [[ "$n" == "1" ]]; then
  echo "PASS: exit 0 but is_error: records the call exactly once"
  pass=$((pass + 1))
else
  echo "FAIL: exit 0 but is_error: recorded ${n:-0} usage record(s), wanted 1"
  fail=$((fail + 1))
fi
rm -rf "$usage_dir"

rm -rf "$s_ok" "$s_err" "$s_silent" "$s_err0"

echo
echo "ai runner contract: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]] || exit 1
