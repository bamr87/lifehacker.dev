#!/usr/bin/env bash
# =============================================================================
# scripts/explorer/bootstrap-labels.sh — explorer label namespaces (idempotent)
# -----------------------------------------------------------------------------
# Adds the labels the site-explorer applies ON TOP of the triage taxonomy
# (scripts/triage/bootstrap-labels.sh creates type/* area/* severity/* source/*).
# These are the live-UX-specific kinds, the explorer source, and the persona
# namespace. `gh label create --force` upserts, so re-running is safe.
#
#   scripts/explorer/bootstrap-labels.sh [owner/repo]   (default: bamr87/lifehacker.dev)
# =============================================================================
set -euo pipefail
REPO="${1:-bamr87/lifehacker.dev}"

label() { gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null && echo "  $1"; }

echo "==> explorer labels on $REPO"
# type/* (live-UX kinds not produced by the build-time harness)
label "type/ux-bug"           "d93f0b" "Broken/dead interaction on the live site"
label "type/a11y"             "d93f0b" "Accessibility issue (contrast, alt text, labels)"
label "type/persona-mismatch" "fbca04" "Content pitched at the wrong reader (too advanced / too shallow)"
# (type/content-polish, type/link-rot, type/content-gap already exist from triage)
# source/*
label "source/site-explorer"  "1d76db" "Filed by the live-site explorer / persona agent"
# persona/* — which reader's lens flagged it
label "persona/beginner"      "bfdadc" "Flagged from the beginner persona"
label "persona/intermediate"  "bfdadc" "Flagged from the intermediate persona"
label "persona/expert"        "bfdadc" "Flagged from the expert persona"
echo "==> done"
