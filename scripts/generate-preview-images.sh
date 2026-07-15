#!/usr/bin/env bash
# Features: ZER0-004, ZER0-028
#
# Script Name: generate-preview-images
# Description: AI-powered preview image generator for Jekyll posts/articles.
#              Thin wrapper — ALL logic lives in the single-file Python engine
#              shipped by the zer0-image-generator gem (Gemfile). Claude
#              ORCHESTRATES (analyzes the article into an art brief, reviews
#              the render); a raster model RENDERS (openai [default], xai,
#              stability, gemini, or the offline local template).
#
#              `bundle exec jekyll preview-images` is the same engine with the
#              long-form flag surface; this wrapper keeps the full short-flag
#              CLI and works without invoking Jekyll.
#
# Usage: ./scripts/generate-preview-images.sh [options]
#        Run with --help for the full option list (rendered by the engine).
#
# Common examples:
#   ./scripts/generate-preview-images.sh --list-missing
#   ./scripts/generate-preview-images.sh --dry-run --verbose
#   ./scripts/generate-preview-images.sh --collection posts
#   ./scripts/generate-preview-images.sh -f pages/_posts/my-post.md --force
#   ./scripts/generate-preview-images.sh --provider openai --enhance -f <file>
#
# Dependencies:
#   - bundler with the project bundle installed (provides the engine gem)
#   - python3 (3.9+) with PyYAML
#   - Optional SVG rasterizers for the local template provider:
#     rsvg-convert | inkscape | magick | Playwright (scripts/dev/rasterize-svg.js)
#
# Environment — renderer key (default openai): OPENAI_API_KEY (or XAI_API_KEY /
# STABILITY_API_KEY / GEMINI_API_KEY for the matching --provider). Claude
# orchestration additionally uses any ONE of (optional; degrades to template):
#   CLAUDE_CODE_OAUTH_TOKEN   `claude setup-token` (Claude Pro/Max)
#   ANTHROPIC_AUTH_TOKEN      short-lived Bearer token
#   ANTHROPIC_API_KEY         console.anthropic.com API key
#   (or a logged-in `claude` CLI — used automatically)
# .env in the project root is loaded by the engine (exported vars win).

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Engine location — the zer0-image-generator gem first; legacy vendored
# layouts (scripts/lib/) as a fallback for checkouts without the bundle.
ENGINE=""
if command -v bundle &>/dev/null; then
    GEM_DIR="$(cd "$SCRIPT_DIR/.." && bundle info zer0-image-generator --path 2>/dev/null || true)"
    if [[ -n "$GEM_DIR" && -f "$GEM_DIR/lib/zer0_image_generator/preview_generator.py" ]]; then
        ENGINE="$GEM_DIR/lib/zer0_image_generator/preview_generator.py"
    fi
fi
if [[ -z "$ENGINE" ]]; then
    for candidate in "$SCRIPT_DIR/../lib/preview_generator.py" "$SCRIPT_DIR/lib/preview_generator.py"; do
        if [[ -f "$candidate" ]]; then
            ENGINE="$candidate"
            break
        fi
    done
fi
if [[ -z "$ENGINE" ]]; then
    echo "[ERROR] preview engine not found. Install the bundle first:" >&2
    echo "        bundle install   (provides the zer0-image-generator gem)" >&2
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "[ERROR] python3 is required. Install it (macOS: brew install python3; Debian/Ubuntu: apt-get install python3)." >&2
    exit 1
fi

# PyYAML availability is checked by the engine itself (ensure_yaml) with an
# actionable message — no duplicate probe here.
exec python3 "$ENGINE" "$@"
