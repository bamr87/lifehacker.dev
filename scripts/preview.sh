#!/usr/bin/env bash
# =============================================================================
# preview.sh — local preview of lifehacker.dev (a remote_theme site)
# -----------------------------------------------------------------------------
# A remote_theme site has no local layouts to build against. This script
# overlays this repo's content onto a cached clone of the zer0-mistakes theme
# (which ships a working Docker dev env), strips _plugins so the local build
# matches what GitHub Pages actually runs, and serves on http://localhost:4000.
#
# The overlay itself lives in scripts/ci/build.sh (lh_overlay) so local preview
# and CI build from the IDENTICAL file list. This script just adds Docker serve.
#
# Usage:
#   scripts/preview.sh            # build overlay + docker compose up
#   scripts/preview.sh build      # build overlay only (no serve)
#   PREVIEW_DIR=/tmp/x scripts/preview.sh
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREVIEW_DIR="${PREVIEW_DIR:-/tmp/lh-preview}"
MODE="${1:-serve}"

# Pull in lh_overlay() (and the theme-cache helpers) — the shared build path.
# shellcheck source=scripts/ci/build.sh
source "$REPO_DIR/scripts/ci/build.sh"

echo "==> repo:    $REPO_DIR"
echo "==> preview: $PREVIEW_DIR"

# Build the overlay (clone theme if needed, layer our content, strip _plugins).
lh_overlay "$PREVIEW_DIR"

if [[ "$MODE" == "build" ]]; then
  echo "==> build-only mode; not serving"
  exit 0
fi

# Serve via the theme's Docker dev env.
cd "$PREVIEW_DIR"
echo "==> starting docker compose (first run builds the image; be patient)"
exec docker compose up
