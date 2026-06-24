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

prompt=""; tools=""; mcp=""; system=""; out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --prompt|-p) prompt="$2"; shift 2;;
    --tools)     tools="$2";  shift 2;;
    --mcp)       mcp="$2";    shift 2;;
    --system)    system="$2"; shift 2;;
    --out)       out="$2";    shift 2;;
    *) shift;;
  esac
done
# No --prompt? read stdin.
[ -z "$prompt" ] && [ ! -t 0 ] && prompt="$(cat)"

run_claude_code() {
  local args=(-p "$prompt" --model "$MODEL" --permission-mode acceptEdits)
  [ -n "$tools" ]  && args+=(--allowedTools "$tools")
  [ -n "$mcp" ]    && args+=(--mcp-config "$mcp")
  # Same system prompt the API fallback gets — appended so Claude Code's own
  # agent prompt (tools/permissions) stays intact. Without this, a guardrail
  # like "never merge" would only bind the fallback path, not the primary one.
  [ -n "$system" ] && args+=(--append-system-prompt "$system")
  claude "${args[@]}"
}

# --- Primary: Claude Code ----------------------------------------------------
if [ "${LH_AI_FORCE_API:-0}" != "1" ] && command -v claude >/dev/null 2>&1; then
  if [ -n "$out" ]; then
    if run_claude_code > "$out"; then exit 0; fi
  else
    if run_claude_code; then exit 0; fi
  fi
  echo "[ai] Claude Code unavailable/failed — falling back to the Claude API." >&2
fi

# --- Fallback: Claude API (single-shot) --------------------------------------
# The raw API needs an ANTHROPIC_API_KEY. If there's none (OAuth-only auth, or no
# auth at all), don't hard-abort — no-op cleanly (exit 0), matching the claude-run
# action's "no auth -> no-op" behavior, so direct callers degrade gracefully.
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "[ai] no ANTHROPIC_API_KEY for the Claude API fallback — skipping (no-op)." >&2
  exit 0
fi
api=("$REPO/scripts/ai/api_call.rb" --prompt "$prompt")
[ -n "$system" ] && api+=(--system "$system")
if [ -n "$out" ]; then
  ruby "${api[@]}" > "$out"
else
  ruby "${api[@]}"
fi
