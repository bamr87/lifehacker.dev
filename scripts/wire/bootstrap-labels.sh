#!/usr/bin/env bash
# =============================================================================
# scripts/wire/bootstrap-labels.sh — wire-scout label namespace (idempotent)
# -----------------------------------------------------------------------------
# The wire-scout opens ONE PR per run carrying its backlog additions. It is
# labeled `auto:content` (so the auto-merge gate recognizes it, same as a
# factory PR) plus a source label so a human can tell at a glance the ideas
# came off the model beat. `gh label create --force` upserts, so re-running is
# safe.
#
#   scripts/wire/bootstrap-labels.sh [owner/repo]   (default: bamr87/lifehacker.dev)
# =============================================================================
set -euo pipefail
REPO="${1:-bamr87/lifehacker.dev}"

label() { gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null && echo "  $1"; }

echo "==> wire-scout labels on $REPO"
label "source/wire-scout" "d93f0b" "Backlog dispatch ideas crawled from the model-beat news sources (_data/wire/sources.yml)"
echo "==> done"
