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
# Last resort: the gem installed outside the bundle. `bundle install` fails on
# Ruby newer than github-pages supports, so a laptop can have the engine gem
# without a working bundle — find it directly rather than dead-ending.
if [[ -z "$ENGINE" ]] && command -v gem &>/dev/null; then
    ENGINE="$(gem contents zer0-image-generator 2>/dev/null | grep -m1 'preview_generator\.py$' || true)"
fi
if [[ -z "$ENGINE" ]]; then
    echo "[ERROR] preview engine not found. Install it with either:" >&2
    echo "        bundle install                       (provides the gem via Gemfile)" >&2
    echo "        gem install zer0-image-generator     (standalone, no bundle needed)" >&2
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "[ERROR] python3 is required. Install it (macOS: brew install python3; Debian/Ubuntu: apt-get install python3)." >&2
    exit 1
fi

REPO_DIR="$(cd -- "$SCRIPT_DIR/.." &>/dev/null && pwd)"

# ── Per-section art direction ────────────────────────────────────────────────
# Issue #337 folded hacks/tools/field-notes into one `posts` collection under
# pages/_posts/<section>/. The gem resolves a file's collection from its nearest
# `_<name>` ancestor, so all three resolve to `posts` and `collection_styles:`
# cannot tell them apart. `section_styles:` in _config.yml carries the per-
# section look; this wrapper exports it as IMAGE_STYLE / IMAGE_STYLE_MODIFIERS,
# which the engine honours because collection_styles has no `posts:` key.
# An IMAGE_STYLE already set by the caller always wins — we never override it.
section_style_for() {  # $1 = section name; prints "style<TAB>modifiers"
    python3 - "$REPO_DIR/_config.yml" "$1" <<'PY' 2>/dev/null || true
import sys
try:
    import yaml
except ImportError:
    sys.exit(0)
cfg_path, section = sys.argv[1], sys.argv[2]
try:
    with open(cfg_path) as fh:
        cfg = yaml.safe_load(fh) or {}
except OSError:
    sys.exit(0)
block = ((cfg.get("preview_images") or {}).get("section_styles") or {}).get(section) or {}
if block:
    print(f"{block.get('style','')}\t{block.get('style_modifiers','')}")
PY
}

apply_section_style() {  # $1 = section name
    local section="$1" line style modifiers
    [[ -z "$section" ]] && return 0
    [[ -n "${IMAGE_STYLE:-}" ]] && return 0   # caller's explicit choice wins
    line="$(section_style_for "$section")"
    [[ -z "$line" ]] && return 0
    style="${line%%$'\t'*}"
    modifiers="${line#*$'\t'}"
    [[ -n "$style" ]] && export IMAGE_STYLE="$style"
    [[ -n "$modifiers" ]] && export IMAGE_STYLE_MODIFIERS="$modifiers"
    echo "[INFO] Section '$section' art direction applied"
}

# Scan args for the target file (-f/--file) and our own --section flag.
TARGET_FILE=""
SECTION=""
ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)   TARGET_FILE="${2:-}"; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --section)   SECTION="${2:-}"; shift 2 ;;   # consumed here, not passed on
        *)           ARGS+=("$1"); shift ;;
    esac
done

# A single -f run: infer the section from the file's own path.
if [[ -n "$TARGET_FILE" && -z "$SECTION" ]]; then
    if [[ "$TARGET_FILE" == *_posts/* ]]; then
        rest="${TARGET_FILE#*_posts/}"
        [[ "$rest" == */* ]] && SECTION="${rest%%/*}"
    fi
fi

if [[ -n "$SECTION" ]]; then
    apply_section_style "$SECTION"
fi

# A bulk --section run with no -f: point the engine at a throwaway collections
# dir whose `_<section>` is a symlink to the real section directory, so it scans
# ONLY that section while still writing front matter and images to the real
# files. Without this the engine would scan every post and paint one section's
# look onto all three.
if [[ -n "$SECTION" && -z "$TARGET_FILE" ]]; then
    SECTION_DIR="$REPO_DIR/pages/_posts/$SECTION"
    if [[ ! -d "$SECTION_DIR" ]]; then
        echo "[ERROR] no such section directory: $SECTION_DIR" >&2
        exit 1
    fi
    # The symlink is named `_posts` (not `_<section>`) because the engine
    # resolves -c to <root>/<collections_dir>/_<name> and errors if that is not
    # a directory; it knows `posts`, not the sections inside it. Pointing
    # `_posts` at one section dir scans only that section; front matter and
    # images still land on the real files the symlink resolves to.
    #
    # The temp dir must live INSIDE the repo and be passed as a RELATIVE path:
    # the engine strips leading slashes off collections_dir and joins it onto
    # the project root, so an absolute /tmp path would be rebased to
    # <repo>/tmp/... and silently not found.
    TMP_ROOT="$(mktemp -d "$REPO_DIR/.preview-section.XXXXXX")"
    trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM
    ln -s "$SECTION_DIR" "$TMP_ROOT/_posts"
    # Deliberately NOT exec: exec replaces this shell, so the cleanup trap would
    # never run and the temp dir would be left behind in the working tree.
    set +e
    python3 "$ENGINE" -c posts --collections-dir "$(basename "$TMP_ROOT")" "${ARGS[@]}"
    status=$?
    set -e
    rm -rf "$TMP_ROOT"
    trap - EXIT INT TERM
    exit "$status"
fi

# PyYAML availability is checked by the engine itself (ensure_yaml) with an
# actionable message — no duplicate probe here.
exec python3 "$ENGINE" ${ARGS[@]+"${ARGS[@]}"}
