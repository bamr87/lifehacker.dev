#!/usr/bin/env bash
# =============================================================================
# scripts/ci/build.sh — the one production-faithful build path
# -----------------------------------------------------------------------------
# A remote_theme site has no local layouts, so to build it anywhere we overlay
# this repo's content onto a clone of the bamr87/zer0-mistakes theme and STRIP
# _plugins (GitHub Pages runs in safe mode and never executes them). This is the
# single source of truth for that overlay: scripts/preview.sh SOURCES this file
# for its Docker workflow, and CI EXECUTES it for a headless `jekyll build
# --strict`. Local and CI therefore can never drift.
#
# Usage:
#   scripts/ci/build.sh            # overlay + jekyll build -> <repo>/_site
#   scripts/ci/build.sh overlay    # build the overlay only (no jekyll)
#   source scripts/ci/build.sh     # just define lh_overlay() (preview.sh does this)
#
# Env: THEME_REPO, THEME_CACHE, LH_BUILD_DIR, LH_SITE_OUT.
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
THEME_REPO="${THEME_REPO:-https://github.com/bamr87/zer0-mistakes.git}"
THEME_CACHE="${THEME_CACHE:-/tmp/zer0-theme}"
LH_BUILD_DIR="${LH_BUILD_DIR:-/tmp/lh-build}"
LH_SITE_OUT="${LH_SITE_OUT:-$REPO_DIR/_site}"

# Ensure a shallow theme clone exists at $THEME_CACHE.
lh_ensure_theme() {
  if [[ ! -d "$THEME_CACHE/_layouts" ]]; then
    echo "==> cloning theme into $THEME_CACHE"
    rm -rf "$THEME_CACHE"
    git clone --depth 1 "$THEME_REPO" "$THEME_CACHE"
  fi
}

# Build the overlay into $1: a fresh copy of the theme with this repo's content
# layered on top and _plugins removed. This is the EXACT file list preview.sh
# used to inline — keep them identical.
lh_overlay() {
  local dest="$1"
  lh_ensure_theme
  echo "==> building overlay at $dest"
  rm -rf "$dest"
  cp -R "$THEME_CACHE" "$dest"
  rm -rf "$dest/.git"

  # Strip the theme's OWN root-level pages (README/AGENTS/CLAUDE/CHANGELOG/
  # CONTRIBUTING/SECURITY/features/contributing/index…). They are theme-repo docs,
  # not lifehacker.dev pages, and would build as /AGENTS/, /CLAUDE/, … with broken
  # relative links to theme-repo files. We re-add only our own root pages below.
  find "$dest" -maxdepth 1 -type f \( -name '*.md' -o -name '*.html' \) -delete
  rm -f "$dest/search.json"
  cp "$REPO_DIR/_config.yml"     "$dest/_config.yml"
  cp "$REPO_DIR/_config_dev.yml" "$dest/_config_dev.yml"

  # Replace the theme's demo collections with ours.
  rm -rf "$dest/pages"
  cp -R "$REPO_DIR/pages" "$dest/pages"

  # Overlay ALL of our _data over the theme's. GitHub Pages reads the whole repo
  # _data/, so to stay production-faithful the build must too — including
  # _data/health (the /docs/health/ dashboard), _data/analytics, and _data/fleet,
  # which a hand-picked subset would silently drop. Theme-only _data not present
  # in our repo (if any) survives the merge.
  cp -R "$REPO_DIR/_data/." "$dest/_data/"

  # Overlay our own _includes (e.g. the homepage card partials in _includes/home/)
  # on top of the theme's. GitHub Pages reads the repo's _includes/ over the
  # remote theme's, so to stay production-faithful the overlay build must too.
  # Same merge semantics as _data above: ours win on name collisions, theme-only
  # includes survive. Skipped cleanly when the repo has no _includes/.
  if [[ -d "$REPO_DIR/_includes" ]]; then
    cp -R "$REPO_DIR/_includes/." "$dest/_includes/"
  fi

  # Top-level spine pages.
  local f
  for f in index.md 404.html search.json search.md sitemap.md blog.md hacks.md tools.md concepts.md categories.md tags.md contact.md; do
    [[ -f "$REPO_DIR/$f" ]] && cp "$REPO_DIR/$f" "$dest/$f"
  done

  # Our assets — the WHOLE tree (images/, svg/, img/, …). GitHub Pages serves
  # every path under assets/, so the overlay must too. Copying only assets/images
  # silently dropped assets/svg/* (e.g. the penrose drawings) and assets/img/*,
  # which html-proofer then flagged as missing images on pages that reference them.
  # Ours win on name collisions; theme-only assets survive the merge.
  mkdir -p "$dest/assets"
  cp -R "$REPO_DIR"/assets/. "$dest/assets/"

  # Match GitHub Pages safe mode: no custom plugins.
  rm -rf "$dest/_plugins"

  # Drop the theme's non-content scaffolding. The onboarding *.md.template files
  # under templates/ carry placeholder (non-YAML) front matter that a --strict
  # build rejects; frontend/ and node_modules/ are build tooling, not pages. The
  # theme's own dev config excludes these, but we build with OUR _config_dev, so
  # remove them here to keep the overlay to real content + delivered theme files.
  rm -rf "$dest/templates" "$dest/frontend" "$dest/node_modules"
  echo "==> overlay ready"
}

# Overlay + headless jekyll build with strict front matter. _site -> $LH_SITE_OUT.
lh_build() {
  lh_overlay "$LH_BUILD_DIR"
  echo "==> bundling theme dev env"
  # Pin BUNDLE_GEMFILE to the theme's own Gemfile: in CI, ruby/setup-ruby exports
  # BUNDLE_GEMFILE pointing at THIS repo's Gemfile, which would otherwise hijack
  # the theme build. The overlay is a copy of the theme, so its Gemfile is here.
  local theme_gemfile="$LH_BUILD_DIR/Gemfile"
  ( cd "$LH_BUILD_DIR" && BUNDLE_GEMFILE="$theme_gemfile" bundle install --quiet )
  echo "==> jekyll build (strict) -> $LH_SITE_OUT"
  rm -rf "$LH_SITE_OUT"
  # The overlay has no .git, so jekyll-github-metadata would shell out to git and
  # print "fatal: not a git repository". Hand it the repo name so it doesn't.
  export PAGES_REPO_NWO="${GITHUB_REPOSITORY:-bamr87/lifehacker.dev}"
  ( cd "$LH_BUILD_DIR" && BUNDLE_GEMFILE="$theme_gemfile" bundle exec jekyll build \
      --config _config.yml,_config_dev.yml \
      --strict_front_matter \
      --trace \
      -d "$LH_SITE_OUT" )
  echo "==> build OK: $(find "$LH_SITE_OUT" -name '*.html' | wc -l | tr -d ' ') html pages"
}

# Only run when EXECUTED, not when SOURCED (preview.sh sources us for lh_overlay).
if ! (return 0 2>/dev/null); then
  case "${1:-build}" in
    overlay) lh_overlay "${2:-$LH_BUILD_DIR}" ;;
    build)   lh_build ;;
    *)       echo "usage: build.sh [overlay|build]" >&2; exit 2 ;;
  esac
fi
