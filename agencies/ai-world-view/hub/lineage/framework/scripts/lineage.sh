#!/usr/bin/env bash
# lineage.sh — deterministic lineage maintenance, run BEFORE the agent tick.
#
# Telemetry from the 2005 lineage showed ~73% of turns / 62% of cost went to the
# shepherd path, where the agent re-improvised git plumbing every run (run 23:
# 78 turns = 14 `diff` + 10 `cd` + 5 `cp` + …). That work is mechanical and
# concept-agnostic: diff fixed framework paths between repos, copy the canonical
# ones, reconcile the registry. This script does it deterministically so the
# expensive model is reserved for the actual content tick.
#
# Two jobs, both idempotent and concept-agnostic (they read only lifecycle.yml +
# fixed framework paths — never the concept/content):
#   1. Forward-pollinate this repo's canonical framework into drifted members
#      (auto-merged PR per drifted member; never touches content/seed/state).
#   2. Reconcile the registry — append successors that members registered but
#      this repo's lifecycle.yml lacks, and sync member statuses.
#
# Safe by construction: no LIFECYCLE_PAT or ≤1 active member → clean no-op.
# Workflows are excluded (LIFECYCLE_PAT lacks `workflow` scope — learning L002).
# Per-member failures are isolated and logged; they never abort the run or the
# downstream agent tick.
set -uo pipefail

PAT="${LIFECYCLE_PAT:-}"
SELF="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"
WS="${GITHUB_WORKSPACE:-$PWD}"
DATE_TAG="$(date -u +%Y%m%d)"
warn() { echo "::warning::lineage.sh: $*"; }
note() { echo "lineage.sh: $*"; }

if [ -z "$PAT" ]; then
  note "No LIFECYCLE_PAT — cross-repo lineage maintenance skipped (plain growth ticks need no PAT)."
  exit 0
fi
export GH_TOKEN="$PAT"
command -v yq >/dev/null 2>&1 || {
  note "installing yq (YAML editor)…"
  curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /tmp/yq \
    && chmod +x /tmp/yq && export PATH="/tmp:$PATH"
}

LC="$WS/lifecycle.yml"
[ -f "$LC" ] || { warn "no lifecycle.yml in checkout — nothing to do."; exit 0; }

# --- Canonical framework paths to converge (everything framework EXCEPT workflows) ---
FW_PATHS=()
for p in "$WS"/.github/*; do
  b="$(basename "$p")"
  [ "$b" = "workflows" ] && continue           # L002: PAT can't push workflows
  [ -e "$p" ] && FW_PATHS+=(".github/$b")
done
[ -d "$WS/.claude" ] && FW_PATHS+=(".claude")
[ -f "$WS/CLAUDE.md" ] && FW_PATHS+=("CLAUDE.md")
[ -f "$WS/LIFECYCLE.md" ] && FW_PATHS+=("LIFECYCLE.md")

# --- Read this repo's registry, in order (oldest→newest, as stored) ---
# `while read` (not mapfile) so this runs identically on bash 3.2 and 5.x.
REPOS=(); STATUSES=()
while IFS=$'\t' read -r repo status; do
  [ -n "$repo" ] || continue
  REPOS+=("$repo"); STATUSES+=("${status:-growing}")
done < <(yq -r '.lifecycle.state.lineage[] | .repo + "\t" + (.status // "growing")' "$LC" 2>/dev/null)
member_count="${#REPOS[@]}"

# Forward pollination only flows to SUCCESSORS — members listed after self — so
# the direction is correct no matter which repo runs this. A growing/newest member
# has no successors and cleanly no-ops; backward flow (member→driver) is the agent's
# job (it needs the member-novel-vs-driver-newer judgement), not this mirror.
self_idx=-1
for (( i=0; i<member_count; i++ )); do
  [ "${REPOS[$i]}" = "$SELF" ] && { self_idx=$i; break; }
done
active_targets=()
if [ "$self_idx" -ge 0 ]; then
  for (( i=self_idx+1; i<member_count; i++ )); do
    case "${STATUSES[$i]}" in consolidated|archived) continue;; esac
    active_targets+=("${REPOS[$i]}")
  done
fi

if [ "${#active_targets[@]}" -eq 0 ]; then
  note "no active sibling members to shepherd (registry lists ${member_count} member(s)) — no-op."
  exit 0
fi
note "active members to maintain: ${active_targets[*]}"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
discovered_repos=()   # repos found in members' registries but missing from ours
our_repos="$(yq -r '.lifecycle.state.lineage[].repo' "$LC" 2>/dev/null | tr '\n' ' ')"

pollinate_member() { # $1=owner/repo
  local repo="$1" dir="$TMP/${1//\//_}"
  git clone --quiet --depth 1 "https://x-access-token:${PAT}@github.com/${repo}.git" "$dir" 2>/dev/null || {
    warn "clone failed: $repo (skipping)"; return 1; }

  # --- registry discovery: collect successors this member knows that we don't ---
  if [ -f "$dir/lifecycle.yml" ]; then
    while IFS= read -r r; do
      [ -z "$r" ] && continue
      case " $our_repos ${discovered_repos[*]:-} " in *" $r "*) : ;; *) discovered_repos+=("$r");; esac
    done < <(yq -r '.lifecycle.state.lineage[].repo' "$dir/lifecycle.yml" 2>/dev/null)
  fi

  # --- forward pollinate: mirror canonical framework paths into the member ---
  local changed=0 pth
  for pth in "${FW_PATHS[@]}"; do
    [ -e "$WS/$pth" ] || continue
    mkdir -p "$dir/$(dirname "$pth")"
    rsync -a --delete "$WS/$pth" "$dir/$(dirname "$pth")/" 2>/dev/null
  done
  ( cd "$dir" && git add -A "${FW_PATHS[@]}" 2>/dev/null && ! git diff --cached --quiet ) && changed=1
  if [ "$changed" -eq 0 ]; then note "  $repo: framework in sync — no PR."; return 0; fi

  local br="pollinate/from-${SELF##*/}-${DATE_TAG}"
  ( cd "$dir" || exit 0
    git checkout -q -B "$br"
    git -c user.name="claude-grow" -c user.email="noreply@anthropic.com" \
      commit -q -m "chore: pollinate framework from ${SELF} (deterministic shepherd)"
    if git push -q -u origin "$br" 2>/dev/null; then
      url="$(gh pr create --title "chore: pollinate framework from ${SELF}" \
               --body "Deterministic forward pollination of canonical framework (.github except workflows, .claude, CLAUDE.md, LIFECYCLE.md) from ${SELF}. Content/seed/state untouched." \
               --head "$br" 2>/dev/null)" || { warn "  $repo: PR create failed"; exit 0; }
      gh pr merge --squash --delete-branch "$url" 2>/dev/null \
        && note "  $repo: pollinated → ${url} (merged)" \
        || warn "  $repo: PR opened but auto-merge blocked → ${url} (left for review)"
    else
      warn "  $repo: push rejected (branch protection or workflow scope) — skipped."
    fi )
}

for repo in "${active_targets[@]}"; do pollinate_member "$repo" || true; done

# --- reconcile the registry: append discovered successors, sync statuses ---
reg_changed=0
for r in "${discovered_repos[@]:-}"; do
  [ -z "$r" ] && continue
  # pull the discovered member's own entry (subject/status/spawned_from) from whichever clone has it
  for d in "$TMP"/*/; do
    [ -f "${d}lifecycle.yml" ] || continue
    entry="$(yq -o=json -I=0 ".lifecycle.state.lineage[] | select(.repo == \"$r\")" "${d}lifecycle.yml" 2>/dev/null | head -1)"
    [ -n "$entry" ] && [ "$entry" != "null" ] || continue
    note "registry: appending discovered member $r"
    yq -i ".lifecycle.state.lineage += [${entry}]" "$LC" && reg_changed=1
    our_repos="$our_repos $r"
    break
  done
done

if [ "$reg_changed" -eq 1 ]; then
  ( cd "$WS" || exit 0
    git add lifecycle.yml
    if ! git diff --cached --quiet; then
      git -c user.name="claude-grow" -c user.email="noreply@anthropic.com" \
        commit -q -m "chore: reconcile lineage registry (deterministic shepherd)"
      git remote set-url origin "https://x-access-token:${PAT}@github.com/${SELF}.git"
      for _ in 1 2 3; do git push -q origin HEAD:main && break; git pull -q --rebase origin main || true; done
      note "registry reconciled and pushed."
    fi )
else
  note "registry already accurate — no update."
fi
note "deterministic lineage maintenance complete."
