#!/usr/bin/env bash
# =============================================================================
# run.sh — the universal AI runner (Claude Code first, Claude API fallback)
# -----------------------------------------------------------------------------
# EVERY AI call in the repo goes through here — every workflow agent step and
# every skill — so model, auth, and the fallback are configured in ONE place
# (_data/ai.yml + ANTHROPIC_API_KEY). Primary is Claude Code (the full agent
# with tools); if the `claude` CLI is missing or the run fails, it falls back to
# the Claude API (scripts/ai/api_call.rb) for a single-shot text result.
#
#   scripts/ai/run.sh --prompt "..." [--tools "Bash,Read,..."] [--mcp cfg.json] \
#                     [--system "..."] [--out file]
#   echo "..." | scripts/ai/run.sh            # stdin prompt
#
# Env: ANTHROPIC_API_KEY (required for both paths in practice),
#      LH_AI_FORCE_API=1 (skip Claude Code, go straight to the API),
#      LH_AI_MODEL (override the model from _data/ai.yml).
# =============================================================================
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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
api=("$REPO/scripts/ai/api_call.rb" --prompt "$prompt")
[ -n "$system" ] && api+=(--system "$system")
if [ -n "$out" ]; then
  ruby "${api[@]}" > "$out"
else
  ruby "${api[@]}"
fi
