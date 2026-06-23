#!/usr/bin/env bash
# =============================================================================
# preview.sh — local preview of lifehacker.dev (a remote_theme site)
# -----------------------------------------------------------------------------
# A remote_theme site has no local layouts to build against. This script
# overlays this repo's content onto a cached clone of the zer0-mistakes theme
# (which ships a working Docker dev env), strips _plugins so the local build
# matches what GitHub Pages actually runs, and serves on http://localhost:4000.
#
# Usage:
#   scripts/preview.sh            # build overlay + docker compose up
#   scripts/preview.sh build      # build overlay only (no serve)
#   PREVIEW_DIR=/tmp/x scripts/preview.sh
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_REPO="${THEME_REPO:-https://github.com/bamr87/zer0-mistakes.git}"
THEME_CACHE="${THEME_CACHE:-/tmp/zer0-theme}"
PREVIEW_DIR="${PREVIEW_DIR:-/tmp/lh-preview}"
MODE="${1:-serve}"

echo "==> repo:    $REPO_DIR"
echo "==> preview: $PREVIEW_DIR"

# 1. Ensure a theme clone exists (shallow).
if [[ ! -d "$THEME_CACHE/_layouts" ]]; then
  echo "==> cloning theme into $THEME_CACHE"
  rm -rf "$THEME_CACHE"
  git clone --depth 1 "$THEME_REPO" "$THEME_CACHE"
fi

# 2. Fresh copy of the theme (keeps its tested docker-compose + _config_dev excludes).
echo "==> building overlay"
rm -rf "$PREVIEW_DIR"
cp -R "$THEME_CACHE" "$PREVIEW_DIR"
rm -rf "$PREVIEW_DIR/.git"

# 3. Overlay this repo's content.
# Drop the theme's own root home/search so ours win the `/` and /search.json URLs.
rm -f "$PREVIEW_DIR/index.html" "$PREVIEW_DIR/index.md" "$PREVIEW_DIR/search.json"
cp "$REPO_DIR/_config.yml"      "$PREVIEW_DIR/_config.yml"
# Replace the theme's demo collection content with ours.
rm -rf "$PREVIEW_DIR/pages"
cp -R "$REPO_DIR/pages"         "$PREVIEW_DIR/pages"
# Overlay our data files (keep the theme's ui-text / skins / backgrounds).
cp -R "$REPO_DIR/_data/navigation" "$PREVIEW_DIR/_data/"
cp -R "$REPO_DIR/_data/brand"      "$PREVIEW_DIR/_data/"
cp "$REPO_DIR/_data/authors.yml"   "$PREVIEW_DIR/_data/authors.yml"
cp "$REPO_DIR/_data/landing.yml"   "$PREVIEW_DIR/_data/landing.yml"
cp "$REPO_DIR/_data/backlog.yml"   "$PREVIEW_DIR/_data/backlog.yml"
# Top-level pages.
for f in index.md 404.html search.json search.md sitemap.md blog.md hacks.md tools.md; do
  [[ -f "$REPO_DIR/$f" ]] && cp "$REPO_DIR/$f" "$PREVIEW_DIR/$f"
done
# Our images.
mkdir -p "$PREVIEW_DIR/assets/images"
cp "$REPO_DIR"/assets/images/*.svg "$PREVIEW_DIR/assets/images/" 2>/dev/null || true

# 4. Strip _plugins so the local build matches GitHub Pages (safe mode skips them).
rm -rf "$PREVIEW_DIR/_plugins"

# 5. Use our dev overlay but keep the theme's comprehensive exclude list by
#    appending ours is unnecessary — the theme's _config_dev already excludes
#    templates/, scripts/, node_modules/. We only need remote_theme disabled,
#    which the theme's _config_dev already does. So leave it as-is.

echo "==> overlay ready at $PREVIEW_DIR"

if [[ "$MODE" == "build" ]]; then
  echo "==> build-only mode; not serving"
  exit 0
fi

# 6. Serve via the theme's Docker dev env.
cd "$PREVIEW_DIR"
echo "==> starting docker compose (first run builds the image; be patient)"
exec docker compose up
