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

# Robustly remove the preview dir. Jekyll-in-Docker writes root-owned files
# (_site/, .jekyll-cache/) into the bind mount, which a plain host `rm` can't
# delete — so free the compose volumes first, then fall back to a root container.
clean_preview() {
  [[ -d "$PREVIEW_DIR" ]] || return 0
  ( cd "$PREVIEW_DIR" 2>/dev/null && docker compose down -v >/dev/null 2>&1 ) || true
  rm -rf "$PREVIEW_DIR" 2>/dev/null && return 0
  docker run --rm -v "$(dirname "$PREVIEW_DIR")":/parent alpine \
    rm -rf "/parent/$(basename "$PREVIEW_DIR")" >/dev/null 2>&1 || true
  rm -rf "$PREVIEW_DIR" 2>/dev/null || true
}

# `down` / `clean`: stop the server and remove the overlay, then exit.
if [[ "$MODE" == "down" || "$MODE" == "clean" ]]; then
  clean_preview
  echo "==> stopped and cleaned $PREVIEW_DIR"
  exit 0
fi

# 1. Ensure a theme clone exists (shallow).
if [[ ! -d "$THEME_CACHE/_layouts" ]]; then
  echo "==> cloning theme into $THEME_CACHE"
  rm -rf "$THEME_CACHE"
  git clone --depth 1 "$THEME_REPO" "$THEME_CACHE"
fi

# 2. Fresh copy of the theme, then PRUNE it down to what `remote_theme` actually
#    delivers to a consumer: _layouts / _includes / _sass / assets (+ the local
#    docker/gem build infra). It does NOT deliver the theme's _config.yml, _data/,
#    _plugins/, or its own root/demo pages — so neither does this overlay.
#    Keeping them would make the link check chase 404s that can't exist on the
#    real site (e.g. /CHANGELOG/, theme nav links to /contact/).
echo "==> building faithful overlay"
clean_preview
cp -R "$THEME_CACHE" "$PREVIEW_DIR"
rm -rf "$PREVIEW_DIR/.git"

# Prune theme content a remote_theme consumer never receives.
rm -rf "$PREVIEW_DIR/_data" "$PREVIEW_DIR/_plugins" \
       "$PREVIEW_DIR/pages" "$PREVIEW_DIR/features" "$PREVIEW_DIR/docs"
rm -f  "$PREVIEW_DIR/index.html" "$PREVIEW_DIR/index.md" \
       "$PREVIEW_DIR/search.json" "$PREVIEW_DIR/search.md" "$PREVIEW_DIR/sitemap.md" \
       "$PREVIEW_DIR/404.html" "$PREVIEW_DIR/CHANGELOG.md" "$PREVIEW_DIR/CLAUDE.md" \
       "$PREVIEW_DIR/CODE_OF_CONDUCT.md" "$PREVIEW_DIR/CONTRIBUTING.md" \
       "$PREVIEW_DIR/SECURITY.md" "$PREVIEW_DIR/README.md" "$PREVIEW_DIR/LICENSE" \
       "$PREVIEW_DIR/AGENTS.md" "$PREVIEW_DIR/frontmatter.json" 2>/dev/null || true

# 3. Overlay this repo's content (the consumer side: config, all data, pages).
cp    "$REPO_DIR/_config.yml" "$PREVIEW_DIR/_config.yml"
cp -R "$REPO_DIR/_data"       "$PREVIEW_DIR/_data"
cp -R "$REPO_DIR/pages"       "$PREVIEW_DIR/pages"
mkdir -p "$PREVIEW_DIR/assets/images"
cp -R "$REPO_DIR/assets/images/." "$PREVIEW_DIR/assets/images/" 2>/dev/null || true
for f in index.md 404.html search.json search.md sitemap.md blog.md hacks.md tools.md dispatches.md categories.md tags.md; do
  [[ -f "$REPO_DIR/$f" ]] && cp "$REPO_DIR/$f" "$PREVIEW_DIR/$f"
done

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
