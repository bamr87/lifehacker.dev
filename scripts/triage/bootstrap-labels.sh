#!/usr/bin/env bash
# =============================================================================
# bootstrap-labels.sh — create the triage label taxonomy (idempotent)
# -----------------------------------------------------------------------------
# Four namespaces the triage bot applies: type/* (what kind of problem),
# area/* (where), severity/* (how bad), source/* (who found it). `gh label
# create --force` upserts, so this is safe to re-run. Run once per repo.
#
#   scripts/triage/bootstrap-labels.sh [owner/repo]   (default: bamr87/lifehacker.dev)
# =============================================================================
set -euo pipefail
REPO="${1:-bamr87/lifehacker.dev}"

label() { gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null && echo "  $1"; }

echo "==> labels on $REPO"
# type/*
label "type/build-break"          "b60205" "The site does not build in safe mode"
label "type/link-rot"             "d93f0b" "Broken internal link, image, or anchor"
label "type/content-bug"          "d93f0b" "Invalid front matter or content schema"
label "type/content-polish"       "fbca04" "Non-blocking content nit (e.g. long SEO description)"
label "type/drift"                "d93f0b" "Hand-authored sitemap/search/backlog out of sync"
label "type/brand-lint"           "fbca04" "Voice/glossary issue (sincere banned word, weasel phrase)"
label "type/field-note-candidate" "0e8a16" "A hack command failed — Field Note material"
label "type/troll-spam"           "5319e7" "Inbound issue classified as troll/spam/duplicate"
label "type/content-gap"          "0e8a16" "A topic worth adding to the backlog"
# area/*
label "area/build"   "c5def5" "Build / CI"
label "area/content" "c5def5" "Pages and posts"
label "area/voice"   "c5def5" "Brand voice"
label "area/site"    "c5def5" "Site-wide / structural"
# severity/*
label "severity/sev1" "b60205" "Critical — blocks the build or the site"
label "severity/sev2" "d93f0b" "High — broken behavior on real pages"
label "severity/sev3" "fbca04" "Medium"
label "severity/sev4" "ededed" "Low / cosmetic"
# source/*
label "source/ci-test"     "1d76db" "Filed by the test harness"
label "source/human-report" "1d76db" "Reported by a human"
label "source/dep-scan"     "1d76db" "Dependency / theme drift"
label "source/analytics"    "1d76db" "Surfaced by traffic data"
label "source/triage-bot"   "1d76db" "Filed by the triage bot"
echo "==> done"
