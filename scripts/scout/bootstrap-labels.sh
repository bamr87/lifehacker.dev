#!/usr/bin/env bash
# =============================================================================
# scripts/scout/bootstrap-labels.sh — content-scout label namespace (idempotent)
# -----------------------------------------------------------------------------
# The content-scout opens ONE PR per run carrying its backlog additions. It is
# labeled `auto:content` (so the auto-merge gate recognizes it, same as a factory
# PR) plus a source label so a human can tell at a glance where the ideas came
# from. `gh label create --force` upserts, so re-running is safe.
#
#   scripts/scout/bootstrap-labels.sh [owner/repo]   (default: bamr87/lifehacker.dev)
# =============================================================================
set -euo pipefail
REPO="${1:-bamr87/lifehacker.dev}"

label() { gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null && echo "  $1"; }

echo "==> content-scout labels on $REPO"
label "source/content-scout" "0e8a16" "Backlog ideas scouted from a sister site (it-journey.dev)"
echo "==> done"
