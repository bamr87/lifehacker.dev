#!/usr/bin/env bash
# =============================================================================
# session-scribe.sh — turn a Claude Code session into a shareable "dispatch"
# -----------------------------------------------------------------------------
# Wired to the SessionEnd hook (.claude/settings.json). When a Claude Code
# session ends, this records it and (in auto mode) spawns a headless `claude`
# run that reads the session transcript and writes an on-voice "Session
# Dispatch" article, then opens a DRAFT pull request for human review.
#
# Why: the compute already happened during the session. Writing it up once and
# sharing it means other people (and other agents) don't have to redo the same
# work — automatic knowledge-sharing for the greater good. (AIPD + COLAB.)
#
# Design principles (it-journey.dev/about):
#   DFF  — never break the user's session; every failure is logged, swallowed,
#          and falls back to a durable queue.
#   KIS  — one script, clear subcommands, env-overridable knobs.
#   REnO — ships as an MVP; the draft-PR gate keeps it safe to iterate.
#
# Subcommands:
#   hook                      read SessionEnd JSON on stdin, dispatch in background
#   write --session <id> --transcript <path> [--reason <r>]   write one dispatch
#   drain                     process any queued sessions not yet written
#   down|clean                (no-op placeholder for symmetry)
#
# Safety:
#   * Recursion guard: exits immediately if CLAUDE_SESSION_SCRIBE=1 (set on the
#     inner `claude` call) so the scribe can never trigger itself.
#   * The inner `claude` runs with --bare (skips hooks/skills) as belt-and-braces.
#   * Output is scrubbed for obvious secrets and lands as a DRAFT PR — a human
#     reviews before anything is published to the world.
#
# Key env knobs (all optional):
#   SCRIBE_DISABLED=1     turn the scribe off entirely
#   SCRIBE_MODE=auto|queue   auto (default) writes now; queue only records
#   SCRIBE_MIN_LINES=30   skip sessions whose transcript is shorter than this
#   SCRIBE_MODEL=...      model for the headless writer (default: claude-opus-4-8)
#   SCRIBE_PR_BASE=main   base branch for the draft PR
#   SCRIBE_WRITER_CMD=... TEST HOOK: command that emits the article body on
#                         stdout instead of calling claude (used by the tests)
#   SCRIBE_DRY_RUN=1      write the dispatch file but skip git/branch/PR
#   SCRIBE_DISPATCH_DIR=<dir>  where dispatches are written (tests override this)
# =============================================================================

# NOTE: deliberately NOT `set -e` — a SessionEnd hook must never abort or error
# out in a way that disrupts the session. We handle errors explicitly.
set -uo pipefail

# ── Recursion guard (must be first) ──────────────────────────────────────────
if [[ "${CLAUDE_SESSION_SCRIBE:-}" == "1" ]]; then
  exit 0
fi

# ── Locate the repo ──────────────────────────────────────────────────────────
REPO_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCRIBE_DIR="$REPO_DIR/.claude/scribe"
LOG="$SCRIBE_DIR/scribe.log"
QUEUE="$SCRIBE_DIR/queue.jsonl"
DISPATCH_DIR="${SCRIBE_DISPATCH_DIR:-$REPO_DIR/pages/_dispatches}"
mkdir -p "$SCRIBE_DIR" 2>/dev/null || true

log() { printf '%s [scribe] %s\n' "$(date -u +%FT%TZ)" "$*" >>"$LOG" 2>/dev/null || true; }

# ── Config ───────────────────────────────────────────────────────────────────
SCRIBE_DISABLED="${SCRIBE_DISABLED:-0}"
SCRIBE_MODE="${SCRIBE_MODE:-auto}"
SCRIBE_MIN_LINES="${SCRIBE_MIN_LINES:-30}"
SCRIBE_MODEL="${SCRIBE_MODEL:-claude-opus-4-8}"
SCRIBE_PR_BASE="${SCRIBE_PR_BASE:-main}"
SCRIBE_DRY_RUN="${SCRIBE_DRY_RUN:-0}"

# ── Helpers ──────────────────────────────────────────────────────────────────

# slugify <text> → kebab-case ascii slug
slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-60
}

# scrub_secrets: redact obvious credential patterns from stdin → stdout.
# Defense-in-depth only; the draft-PR human review is the real gate.
scrub_secrets() {
  sed -E \
    -e 's/(gh[pousr]_)[A-Za-z0-9]{16,}/\1[REDACTED]/g' \
    -e 's/(sk-(ant-)?)[A-Za-z0-9_-]{16,}/\1[REDACTED]/g' \
    -e 's/(phc_)[A-Za-z0-9]{16,}/\1[REDACTED]/g' \
    -e 's/(AKIA)[A-Z0-9]{12,}/\1[REDACTED]/g' \
    -e 's/(xox[baprs]-)[A-Za-z0-9-]{10,}/\1[REDACTED]/g' \
    -e 's/([Bb]earer )[A-Za-z0-9._-]{16,}/\1[REDACTED]/g' \
    -e 's/(-----BEGIN [A-Z ]*PRIVATE KEY-----).*/\1[REDACTED]/g'
}

# The writer prompt — what the headless claude is asked to produce.
build_prompt() {
  local transcript="$1"
  cat <<PROMPT
You are the Session Scribe for lifehacker.dev. Read the Claude Code session
transcript at this path (it is JSONL — one JSON object per line, with user
messages, assistant messages, and tool calls/results):

  $transcript

Also read these brand files in the repo to match the site's voice, and follow
them: $REPO_DIR/_data/brand/identity.yml, voice.yml, glossary.yml.

Write a single self-contained Markdown ARTICLE ("Session Dispatch") that teaches
the reader what this session was actually about and what was learned — so nobody
has to redo the work. Requirements:

- Voice: the site's deadpan-but-useful "meta-confession" profile. Lead with the
  problem and the outcome. Keep it genuinely useful: real commands/decisions,
  the dead ends left in, the why.
- Structure: a short intro, then the substance (what was attempted, what worked,
  what broke and the fix), then a tight "Takeaways" list a stranger could act on.
- Length: ~400-900 words.
- The FIRST line MUST be a single H1 title: "# <Title>" (no front matter — the
  tooling adds it). Do not include YAML.
- CRITICAL — never publish secrets. Do NOT include API keys, tokens, passwords,
  full home paths with usernames, private URLs, customer data, or anything that
  looks like a credential. Summarize around them. When in doubt, leave it out.
- Output ONLY the article Markdown. No preamble, no sign-off, no code fences
  around the whole thing.
PROMPT
}

# run_writer <transcript> → article body on stdout (or non-zero on failure)
run_writer() {
  local transcript="$1"
  if [[ -n "${SCRIBE_WRITER_CMD:-}" ]]; then
    # Test/override hook: a command that emits the body on stdout.
    SCRIBE_TRANSCRIPT="$transcript" bash -c "$SCRIBE_WRITER_CMD" "$transcript"
    return $?
  fi
  command -v claude >/dev/null 2>&1 || { log "claude not on PATH"; return 3; }
  # Inner call: recursion guard env + --bare (no hooks/skills) + Read only.
  CLAUDE_SESSION_SCRIBE=1 claude -p "$(build_prompt "$transcript")" \
    --bare \
    --allowedTools "Read" \
    --output-format text \
    --model "$SCRIBE_MODEL" 2>>"$LOG"
}

# write_dispatch <session_id> <transcript_path> <reason>
write_dispatch() {
  local sid="$1" transcript="$2" reason="${3:-other}"
  local sid8="${sid:0:8}"
  [[ -z "$sid8" ]] && sid8="unknown"

  if [[ "$SCRIBE_DISABLED" == "1" ]]; then log "disabled; skipping $sid8"; return 0; fi

  # Idempotency: one dispatch per session.
  if compgen -G "$DISPATCH_DIR/*-$sid8.md" >/dev/null 2>&1; then
    log "dispatch for $sid8 already exists; skipping"; return 0
  fi

  # Trivial-session skip (cost + signal control).
  local lines=0
  if [[ -f "$transcript" ]]; then lines=$(wc -l <"$transcript" 2>/dev/null | tr -d ' '); fi
  if [[ "${lines:-0}" -lt "$SCRIBE_MIN_LINES" ]]; then
    log "session $sid8 trivial ($lines < $SCRIBE_MIN_LINES lines); skipping"; return 0
  fi

  log "writing dispatch for $sid8 (reason=$reason, $lines lines)"
  local body
  body="$(run_writer "$transcript")"
  if [[ -z "${body// }" ]]; then
    log "writer produced no output for $sid8; leaving in queue for drain"; return 4
  fi

  body="$(printf '%s' "$body" | scrub_secrets)"

  # Title = first H1; slug from it.
  local title slug
  title="$(printf '%s\n' "$body" | grep -m1 -E '^# ' | sed -E 's/^# +//')"
  [[ -z "$title" ]] && title="Session dispatch $sid8"
  slug="$(slugify "$title")"
  [[ -z "$slug" ]] && slug="session-$sid8"
  # Strip the leading H1 from the body (it becomes the frontmatter title).
  # awk, not `sed 0,/re/` — the latter is a GNU extension that no-ops on BSD/macOS.
  body="$(printf '%s\n' "$body" | awk 'BEGIN{s=0} (!s && /^# /){s=1; next} {print}')"

  local today; today="$(date -u +%F)"
  local fname="${today}-${slug}-${sid8}.md"
  mkdir -p "$DISPATCH_DIR" 2>/dev/null || true
  local outfile="$DISPATCH_DIR/$fname"

  {
    printf -- '---\n'
    printf 'title: %s\n' "\"$(printf '%s' "$title" | sed 's/"/\\"/g')\""
    printf 'date: %s\n' "$today"
    printf 'collection: dispatches\n'
    printf 'author: claude\n'
    printf 'auto_generated: true\n'
    printf 'session: %s\n' "$sid8"
    printf 'reason: %s\n' "$reason"
    printf 'tags: [session-dispatch, automated, knowledge-sharing]\n'
    printf 'excerpt: %s\n' "\"Auto-written dispatch from a Claude Code session ($sid8).\""
    printf -- '---\n\n'
    printf '> **Auto-generated by the [Session Scribe](/docs/session-scribe/).** A robot wrote this from a Claude Code session transcript; a human reviewed the pull request before it shipped.\n\n'
    printf '%s\n' "$body"
  } >"$outfile"

  log "wrote $outfile"

  if [[ "$SCRIBE_DRY_RUN" == "1" ]]; then
    printf '%s\n' "$outfile"   # dry-run: report the path for tests
    return 0
  fi

  open_pr "$fname" "$title" "$sid8"
}

# open_pr <relative_fname> <title> <sid8> — branch + commit + draft PR (best effort)
open_pr() {
  local fname="$1" title="$2" sid8="$3"
  command -v git >/dev/null 2>&1 || { log "git missing; dispatch left uncommitted"; return 0; }
  ( cd "$REPO_DIR" || exit 0
    local branch="dispatch/$sid8"
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { log "not a git repo"; exit 0; }
    git fetch origin "$SCRIBE_PR_BASE" >/dev/null 2>&1 || true
    git switch -c "$branch" "origin/$SCRIBE_PR_BASE" >/dev/null 2>&1 \
      || git switch -c "$branch" >/dev/null 2>&1 || { log "branch $branch exists"; exit 0; }
    git add "pages/_dispatches/$fname" >/dev/null 2>&1
    git commit -q -m "docs(dispatch): $title" \
      -m "Auto-written session dispatch ($sid8). Review before publishing." \
      -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>" >/dev/null 2>&1 || { log "nothing to commit"; exit 0; }
    git push -u origin "$branch" >/dev/null 2>&1 || { log "push failed for $branch"; exit 0; }
    if command -v gh >/dev/null 2>&1; then
      gh pr create --draft --base "$SCRIBE_PR_BASE" --head "$branch" \
        --title "Session dispatch: $title" \
        --body "Auto-generated by the Session Scribe from session \`$sid8\`. **Review for accuracy and secrets before merging.** Merging publishes it to /dispatches/." \
        >>"$LOG" 2>&1 && log "opened draft PR for $sid8" || log "gh pr create failed for $sid8"
    fi
  )
}

# ── Subcommand dispatch ──────────────────────────────────────────────────────
CMD="${1:-hook}"; shift || true

case "$CMD" in
  hook)
    # Read the SessionEnd JSON from stdin.
    INPUT="$(cat)"
    if command -v jq >/dev/null 2>&1; then
      SID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)"
      TPATH="$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
      REASON="$(printf '%s' "$INPUT" | jq -r '.reason // "other"' 2>/dev/null)"
    else
      SID="$(printf '%s' "$INPUT" | sed -nE 's/.*"session_id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')"
      TPATH="$(printf '%s' "$INPUT" | sed -nE 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')"
      REASON="$(printf '%s' "$INPUT" | sed -nE 's/.*"reason"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')"
      [[ -z "$REASON" ]] && REASON="other"
    fi
    [[ -z "$SID" ]] && { log "no session_id in hook input; nothing to do"; exit 0; }

    # Durable capture (audit log + drain fallback) — DFF.
    printf '{"session":"%s","transcript":"%s","reason":"%s","ts":"%s"}\n' \
      "$SID" "$TPATH" "$REASON" "$(date -u +%FT%TZ)" >>"$QUEUE" 2>/dev/null || true

    if [[ "$SCRIBE_DISABLED" == "1" || "$SCRIBE_MODE" == "queue" ]]; then
      log "captured $SID (mode=$SCRIBE_MODE disabled=$SCRIBE_DISABLED); not writing now"
      exit 0
    fi

    # Auto mode: write in the background so SessionEnd never waits.
    nohup "${BASH_SOURCE[0]}" write --session "$SID" --transcript "$TPATH" --reason "$REASON" \
      >>"$LOG" 2>&1 &
    disown 2>/dev/null || true
    exit 0
    ;;

  write)
    SID=""; TPATH=""; REASON="other"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --session) SID="$2"; shift 2;;
        --transcript) TPATH="$2"; shift 2;;
        --reason) REASON="$2"; shift 2;;
        --dry-run) SCRIBE_DRY_RUN=1; shift;;
        *) shift;;
      esac
    done
    [[ -z "$SID" ]] && { log "write: missing --session"; exit 2; }
    write_dispatch "$SID" "$TPATH" "$REASON"
    ;;

  drain)
    [[ -f "$QUEUE" ]] || { echo "queue empty"; exit 0; }
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if command -v jq >/dev/null 2>&1; then
        s="$(printf '%s' "$line" | jq -r '.session // empty')"
        t="$(printf '%s' "$line" | jq -r '.transcript // empty')"
        r="$(printf '%s' "$line" | jq -r '.reason // "other"')"
      else
        s="$(printf '%s' "$line" | sed -nE 's/.*"session":"([^"]+)".*/\1/p')"
        t="$(printf '%s' "$line" | sed -nE 's/.*"transcript":"([^"]+)".*/\1/p')"
        r="other"
      fi
      [[ -n "$s" ]] && write_dispatch "$s" "$t" "$r"
    done <"$QUEUE"
    ;;

  down|clean) exit 0;;
  *) echo "usage: session-scribe.sh {hook|write|drain}" >&2; exit 2;;
esac
