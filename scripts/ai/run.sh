#!/usr/bin/env bash
# =============================================================================
# run.sh — the universal AI runner (Claude Code first, Claude API fallback)
# -----------------------------------------------------------------------------
# EVERY AI call in the repo goes through here — every workflow agent step and
# every skill — so model, auth, and the fallback are configured in ONE place
# (_data/ai.yml + the auth env below). Primary is Claude Code (the full agent
# with tools); if the `claude` CLI is missing or the run fails, it falls back to
# the Claude API (scripts/ai/api_call.rb) for a single-shot text result.
#
#   scripts/ai/run.sh --prompt "..." [--tools "Bash,Read,..."] [--mcp cfg.json] \
#                     [--system "..."] [--out file]
#   echo "..." | scripts/ai/run.sh            # stdin prompt
#
# Auth (either works for the primary Claude Code path):
#   CLAUDE_CODE_OAUTH_TOKEN — a Claude Code token from `claude setup-token`
#                             (subscription auth; the preferred CI credential).
#   ANTHROPIC_API_KEY       — a pay-per-use API key; ALSO the only credential the
#                             Claude API fallback (api_call.rb) can use.
# Env: LH_AI_FORCE_API=1 (skip Claude Code, go straight to the API),
#      LH_AI_MODEL (override the model from _data/ai.yml).
#
# EXIT CODES — a failed call is never silently green:
#   0  the call ran, or no AI call was ever attempted (no `claude` on PATH and
#      no API key: the documented no-op, so a human running a skill locally
#      without credentials degrades gracefully instead of aborting).
#   1  the call was ATTEMPTED and FAILED with no usable fallback. The reason the
#      run gave (auth rejected, quota exhausted, model unavailable) is printed
#      and, under Actions, raised as a ::error:: annotation. Before this, such a
#      run exited 0 and the caller only learned of it a step later, as a generic
#      "no PR was opened", with the evidence already deleted.
# =============================================================================
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# The Claude Code CLI reads CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY from the
# env. Prefer the OAuth token when present, and drop an empty ANTHROPIC_API_KEY
# (an unset GitHub secret renders as "") so the CLI never attempts empty-key auth.
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  unset ANTHROPIC_API_KEY
fi

MODEL="$(ruby -ryaml -e '
  c = (YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(File.read(ARGV[0])) : YAML.load(File.read(ARGV[0]))) rescue {}
  puts(ENV["LH_AI_MODEL"] || (c && c["model"]) || "claude-opus-4-8")
' "$REPO/_data/ai.yml" 2>/dev/null || echo claude-opus-4-8)"

prompt=""; tools=""; mcp=""; system=""; out=""; agent=""
while [ $# -gt 0 ]; do
  case "$1" in
    --prompt|-p) prompt="$2"; shift 2;;
    --tools)     tools="$2";  shift 2;;
    --mcp)       mcp="$2";    shift 2;;
    --system)    system="$2"; shift 2;;
    --out)       out="$2";    shift 2;;
    --agent)     agent="$2";  shift 2;;
    *) shift;;
  esac
done
# No --prompt? read stdin.
[ -z "$prompt" ] && [ ! -t 0 ] && prompt="$(cat)"

run_claude_code() {
  # --output-format json: same run, but the final payload carries usage + cost
  # (total_cost_usd, per-model tokens) alongside the result text. usage.rb
  # records the usage and re-emits the text, so callers see exactly what they
  # always did on stdout/--out.
  local args=(-p "$prompt" --model "$MODEL" --permission-mode acceptEdits --output-format json)
  # Run AS a named agent (.claude/agents/<name>.md) when given — its system prompt,
  # tool scope, and role constraints are the single source of truth, so every CI
  # invocation of that role behaves identically. --tools/--system still layer on.
  [ -n "$agent" ]  && args+=(--agent "$agent")
  [ -n "$tools" ]  && args+=(--allowedTools "$tools")
  [ -n "$mcp" ]    && args+=(--mcp-config "$mcp")
  # Same system prompt the API fallback gets — appended so Claude Code's own
  # agent prompt (tools/permissions) stays intact. Without this, a guardrail
  # like "never merge" would only bind the fallback path, not the primary one.
  [ -n "$system" ] && args+=(--append-system-prompt "$system")
  # OAuth-first invariant: when the subscription token exists, the CLI must
  # never see the metered API key (with both set it would silently bill the
  # key). The key stays exported in THIS shell for the API fallback below.
  if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
    env -u ANTHROPIC_API_KEY claude "${args[@]}"
  else
    claude "${args[@]}"
  fi
}

# `claude -p --output-format json` writes its FAILURE to stdout too: a result
# payload carrying `subtype` and a `result` message that says what the API
# refused and why. Pull that out (secrets scrubbed, one line, bounded) so the
# job log names the cause instead of guessing at it.
claude_failure_reason() {
  ruby -rjson -e '
    raw = (File.read(ARGV[0], encoding: "UTF-8") rescue "")
    res = (JSON.parse(raw) rescue nil)
    text = res.is_a?(Hash) ? [res["subtype"], res["result"] || res["error"]].compact.map(&:to_s).reject(&:empty?).join(": ") : raw
    puts text.to_s.gsub(/sk-ant-[A-Za-z0-9_-]{8,}/, "sk-ant-***").gsub(/\s+/, " ").strip[0, 600].to_s
  ' "$1" 2>/dev/null
}

# Name the operator action for the failures that actually recur here. Advisory
# only — the run's own message is always printed alongside it.
claude_failure_hint() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    *"usage limit"*|*rate_limit*|*"too many requests"*|*429*)
      echo "the Claude quota behind this credential is exhausted — wait for the window to reset, or move the lane to a metered ANTHROPIC_API_KEY" ;;
    *authentication*|*unauthorized*|*"invalid api key"*|*invalid_api_key*|*expired*|*"/login"*|*401*|*403*)
      echo "the Claude credential was rejected — mint a fresh CLAUDE_CODE_OAUTH_TOKEN with \`claude setup-token\` and update the repo secret" ;;
    *overloaded*|*529*|*503*|*502*)
      echo "the API was overloaded — transient; the next scheduled run should recover" ;;
    *not_found*|*"does not support"*|*"unknown model"*)
      echo "the model pinned in _data/ai.yml is not available to this credential — check \`model:\` there" ;;
    *) echo "" ;;
  esac
}

# --- Primary: Claude Code ----------------------------------------------------
primary_failed=0
reason=""
if [ "${LH_AI_FORCE_API:-0}" != "1" ] && command -v claude >/dev/null 2>&1; then
  tmp_json="$(mktemp "${TMPDIR:-/tmp}/lh-ai-result.XXXXXX")"
  run_claude_code > "$tmp_json"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    # Record usage, then emit the result text (the caller's contract). A parse
    # failure here means claude didn't produce a result payload — treat it
    # exactly like a failed run and let the fallback engage.
    if [ -n "$out" ]; then
      if ruby "$REPO/scripts/ai/usage.rb" ingest-claude "$tmp_json" --agent "$agent" --rc "$rc" --emit-result > "$out"; then
        rm -f "$tmp_json"; exit 0
      fi
    else
      if ruby "$REPO/scripts/ai/usage.rb" ingest-claude "$tmp_json" --agent "$agent" --rc "$rc" --emit-result; then
        rm -f "$tmp_json"; exit 0
      fi
    fi
  fi
  # Reaching here means the run failed: a non-zero exit, or an exit-0 payload the
  # ingester refused (an is_error result, or not a result at all). Tokens may
  # still have been spent — record them (status:error, with the reason) before
  # falling back, and no longer swallow the ingester's stderr, because that line
  # is half the diagnosis. Only the non-zero path ingests here: the exit-0 path
  # already ran the ingester above, and re-running it would append the record
  # twice (same stable id, but the step summary and ledger both count rows).
  primary_failed=1
  [ "$rc" -ne 0 ] && { ruby "$REPO/scripts/ai/usage.rb" ingest-claude "$tmp_json" --agent "$agent" --rc "$rc" || true; }
  reason="$(claude_failure_reason "$tmp_json")"
  rm -f "$tmp_json"
  if [ "$rc" -ne 0 ]; then
    echo "[ai] Claude Code failed (exit $rc): ${reason:-no result payload — claude produced no JSON}" >&2
  else
    echo "[ai] Claude Code exited 0 with an unusable result: ${reason:-no result payload — claude produced no JSON}" >&2
  fi
  hint="$(claude_failure_hint "$reason")"
  [ -n "$hint" ] && echo "[ai] likely cause: $hint" >&2
  echo "[ai] falling back to the Claude API." >&2
fi

# --- Fallback: Claude API (single-shot) --------------------------------------
# The raw API needs an ANTHROPIC_API_KEY. With none, what decides the exit code
# is what happened BEFORE this point, not whether a key exists:
#   * nothing was attempted (no `claude` on PATH, or LH_AI_FORCE_API with no key)
#     -> the documented no-op, exit 0, so direct callers degrade gracefully.
#   * the primary path RAN AND FAILED -> exit non-zero. A rejected model call is
#     a failure, and a green step that produced nothing is how six days of dead
#     content-factory runs came to read as "no PR was opened (auth? duplicate?
#     build failure?)" one step downstream.
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  if [ "$primary_failed" -eq 1 ]; then
    echo "[ai] no ANTHROPIC_API_KEY to fall back to — the AI step failed." >&2
    [ "${GITHUB_ACTIONS:-}" = "true" ] && \
      echo "::error::AI step failed${agent:+ (agent: $agent)}: ${reason:-Claude Code produced no result payload}"
    exit 1
  fi
  echo "[ai] no ANTHROPIC_API_KEY for the Claude API fallback — skipping (no-op)." >&2
  exit 0
fi
export LH_AI_ROLE="$agent"   # so the fallback's usage record carries the role
api=("$REPO/scripts/ai/api_call.rb" --prompt "$prompt")
[ -n "$system" ] && api+=(--system "$system")
if [ -n "$out" ]; then
  ruby "${api[@]}" > "$out"
else
  ruby "${api[@]}"
fi
