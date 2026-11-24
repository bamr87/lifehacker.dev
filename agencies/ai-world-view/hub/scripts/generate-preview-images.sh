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
#   - No SVG rasterizer needed: _config.yml pins
#     `preview_images.rasterizer: none`, so the local provider commits its
#     vector banner as .svg instead of converting it to PNG. Pass
#     --rasterizer auto to opt back into PNG for a one-off run (needs one of
#     rsvg-convert | inkscape | magick | Playwright on PATH).
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

# ── SVG-only output ──────────────────────────────────────────────────────────
# _config.yml sets `preview_images.rasterizer: none`, which makes the local
# renderer keep its vector banner instead of rasterizing it to PNG. Engines
# from the gem >= 0.8 read that key themselves; older ones only accept it as
# --rasterizer, so this wrapper reads the config and forwards it. Either way
# _config.yml stays the one place the policy is written down. A caller who
# passes --rasterizer explicitly always wins.
config_rasterizer() {  # prints the configured rasterizer, or nothing
    python3 - "$REPO_DIR/_config.yml" <<'PY' 2>/dev/null || true
import sys
try:
    import yaml
except ImportError:
    sys.exit(0)
try:
    with open(sys.argv[1]) as fh:
        cfg = yaml.safe_load(fh) or {}
except OSError:
    sys.exit(0)
value = (cfg.get("preview_images") or {}).get("rasterizer")
if value:
    print(value)
PY
}

# Scan args for the target file (-f/--file), our own --section flag, and whether
# the caller pinned --rasterizer or --provider themselves.
TARGET_FILE=""
SECTION=""
RASTERIZER_GIVEN=0
PROVIDER_GIVEN=""
LIST_GIVEN=0
DRYRUN_GIVEN=0
FORCE_GIVEN=0
VERBOSE_GIVEN=0
ENHANCE_GIVEN=0
BATCH_GIVEN=""
STYLE_GIVEN=""
STYLE_MODS_GIVEN=""
OUTPUT_DIR_GIVEN=""
FM_KEY_GIVEN=""
COLLECTION_GIVEN=""
COLLECTIONS_DIR_GIVEN=""
ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)   TARGET_FILE="${2:-}"; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --file=*)    TARGET_FILE="${1#*=}"; ARGS+=("$1"); shift ;;
        --section)   SECTION="${2:-}"; shift 2 ;;   # consumed here, not passed on
        --section=*) SECTION="${1#*=}"; shift ;;
        --rasterizer) RASTERIZER_GIVEN=1; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --rasterizer=*) RASTERIZER_GIVEN=1; ARGS+=("$1"); shift ;;
        -p|--provider) PROVIDER_GIVEN="${2:-}"; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --provider=*)  PROVIDER_GIVEN="${1#*=}"; ARGS+=("$1"); shift ;;
        --list-missing) LIST_GIVEN=1; ARGS+=("$1"); shift ;;
        -d|--dry-run)   DRYRUN_GIVEN=1; ARGS+=("$1"); shift ;;
        --force)        FORCE_GIVEN=1; ARGS+=("$1"); shift ;;
        -v|--verbose)   VERBOSE_GIVEN=1; ARGS+=("$1"); shift ;;
        -e|--enhance|--enhance-*) ENHANCE_GIVEN=1; ARGS+=("$1"); shift ;;
        --batch)        BATCH_GIVEN="${2:-}"; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --batch=*)      BATCH_GIVEN="${1#*=}"; ARGS+=("$1"); shift ;;
        # Captured so the claude rung receives them too (they stay in ARGS for
        # the engine path).
        --style)        STYLE_GIVEN="${2:-}"; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --style=*)      STYLE_GIVEN="${1#*=}"; ARGS+=("$1"); shift ;;
        # Wrapper/companion-only (the engine reads modifiers from env/config
        # and would reject the flag) — consumed here, not passed on. The engine
        # path still honours it via the IMAGE_STYLE_MODIFIERS export below.
        --style-modifiers)   STYLE_MODS_GIVEN="${2:-}"; shift 2 ;;
        --style-modifiers=*) STYLE_MODS_GIVEN="${1#*=}"; shift ;;
        --output-dir)   OUTPUT_DIR_GIVEN="${2:-}"; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --output-dir=*) OUTPUT_DIR_GIVEN="${1#*=}"; ARGS+=("$1"); shift ;;
        --front-matter-key)   FM_KEY_GIVEN="${2:-}"; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --front-matter-key=*) FM_KEY_GIVEN="${1#*=}"; ARGS+=("$1"); shift ;;
        -c|--collection)  COLLECTION_GIVEN="${2:-}"; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --collection=*)   COLLECTION_GIVEN="${1#*=}"; ARGS+=("$1"); shift ;;
        --collections-dir)   COLLECTIONS_DIR_GIVEN="${2:-}"; ARGS+=("$1" "${2:-}"); shift 2 ;;
        --collections-dir=*) COLLECTIONS_DIR_GIVEN="${1#*=}"; ARGS+=("$1"); shift ;;
        *)           ARGS+=("$1"); shift ;;
    esac
done

# --style-modifiers has no engine flag; surface it to the engine as the env
# var it does read (an env already set by the caller wins).
if [[ -n "$STYLE_MODS_GIVEN" && -z "${IMAGE_STYLE_MODIFIERS:-}" ]]; then
    export IMAGE_STYLE_MODIFIERS="$STYLE_MODS_GIVEN"
fi

# ── Provider capability ladder ───────────────────────────────────────────────
# _config.yml may set `preview_images.provider` to a value the published engine
# does not know (`auto` — and the explicit rungs `claude` / `default`). The
# engine (<= 0.6.x) error-exits on those, so THIS wrapper resolves the ladder
# (best renderer the environment can actually reach) and dispatches:
#   raster API key present  → that engine provider (Claude still writes the
#                             art brief / reviews via the engine's own
#                             orchestration);
#   Claude credential only  → scripts/claude_svg_banner.py — Claude AUTHORS
#                             the banner as SVG (the companion reuses the
#                             engine's sanitizer + front-matter writers);
#   nothing wired           → the engine's deterministic `local` SVG (the
#                             shared per-section banner defaults in
#                             _config.yml remain the floor beneath that).
# An explicit -p/--provider or AI_PROVIDER always wins (no ladder). --enhance
# is OpenAI-only and list runs are provider-neutral, so both skip the claude
# rung. Remove this ladder once the engine grows native `auto` support
# (github.com/bamr87/zer0-image-generator).
config_provider() {  # prints preview_images.provider from _config.yml, if any
    python3 - "$REPO_DIR/_config.yml" <<'PY' 2>/dev/null || true
import sys
try:
    import yaml
except ImportError:
    sys.exit(0)
try:
    with open(sys.argv[1]) as fh:
        cfg = yaml.safe_load(fh) or {}
except OSError:
    sys.exit(0)
value = (cfg.get("preview_images") or {}).get("provider")
if value:
    print(value)
PY
}

has_claude_credential() {
    [[ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" || -n "${ANTHROPIC_AUTH_TOKEN:-}" \
       || -n "${ANTHROPIC_API_KEY:-}" ]] && return 0
    command -v claude &>/dev/null
}

USE_CLAUDE_SVG=0
if [[ -z "$PROVIDER_GIVEN" && -z "${AI_PROVIDER:-}" ]]; then
    CFG_PROVIDER="$(config_provider)"
    case "$CFG_PROVIDER" in
        gemini|local|openai|stability|xai|"") : ;;  # engine-legal / engine default
        auto|default|claude)
            if [[ "$ENHANCE_GIVEN" -eq 1 ]]; then
                # --enhance is OpenAI images/edits only. The local provider's
                # edit() is a no-op that still reports success, so routing
                # enhance to `-p local` would silently do nothing.
                if [[ -n "${OPENAI_API_KEY:-}" ]]; then
                    ARGS+=(-p openai)
                else
                    echo "[ERROR] --enhance needs OPENAI_API_KEY (OpenAI images/edits); the auto ladder has no keyless enhance rung." >&2
                    exit 1
                fi
            elif [[ "$LIST_GIVEN" -eq 1 ]]; then
                ARGS+=(-p local)   # listing is provider-neutral; keep it keyless
            elif [[ "$CFG_PROVIDER" != "claude" && -n "${OPENAI_API_KEY:-}" ]]; then
                ARGS+=(-p openai)
            elif [[ "$CFG_PROVIDER" != "claude" && -n "${XAI_API_KEY:-}" ]]; then
                ARGS+=(-p xai)
            elif [[ "$CFG_PROVIDER" != "claude" && -n "${STABILITY_API_KEY:-}" ]]; then
                ARGS+=(-p stability)
            elif [[ "$CFG_PROVIDER" != "claude" && -n "${GEMINI_API_KEY:-}" ]]; then
                ARGS+=(-p gemini)
            elif has_claude_credential; then
                USE_CLAUDE_SVG=1
                echo "[INFO] Ladder: Claude authors the banner as SVG (claude_svg_banner.py)"
            else
                ARGS+=(-p local)
                echo "[INFO] Ladder: no credential wired — deterministic local SVG"
            fi
            ;;
        *)  # unknown value: let the engine produce its own actionable error
            : ;;
    esac
fi

# Build the companion's argument list from the flags the caller gave us —
# forward every captured engine-shared flag so the claude rung honours the
# same request the engine would have received.
run_claude_svg() {  # $@ = extra target args (--file/--scan/--collection…)
    local status=0
    local cmd=(python3 "$SCRIPT_DIR/claude_svg_banner.py" --engine "$ENGINE")
    [[ "$DRYRUN_GIVEN"  -eq 1 ]] && cmd+=(--dry-run)
    [[ "$FORCE_GIVEN"   -eq 1 ]] && cmd+=(--force)
    [[ "$VERBOSE_GIVEN" -eq 1 ]] && cmd+=(--verbose)
    [[ -n "$BATCH_GIVEN" ]] && cmd+=(--batch "$BATCH_GIVEN")
    [[ -n "$STYLE_GIVEN" ]] && cmd+=(--style "$STYLE_GIVEN")
    [[ -n "$STYLE_MODS_GIVEN" ]] && cmd+=(--style-modifiers "$STYLE_MODS_GIVEN")
    [[ -n "$OUTPUT_DIR_GIVEN" ]] && cmd+=(--output-dir "$OUTPUT_DIR_GIVEN")
    [[ -n "$FM_KEY_GIVEN" ]] && cmd+=(--front-matter-key "$FM_KEY_GIVEN")
    "${cmd[@]}" "$@" || status=$?
    if [[ $status -eq 3 ]]; then
        echo "[INFO] Claude rung unavailable after all — deterministic local SVG"
        return 200   # sentinel: caller re-dispatches to the engine with -p local
    fi
    return $status
}

if [[ "$RASTERIZER_GIVEN" -eq 0 ]]; then
    CFG_RASTERIZER="$(config_rasterizer)"
    if [[ -n "$CFG_RASTERIZER" ]]; then
        ARGS+=(--rasterizer "$CFG_RASTERIZER")
        [[ "$CFG_RASTERIZER" == "none" ]] && echo "[INFO] SVG-only output (_config.yml preview_images.rasterizer: none)"
    fi
fi

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
    if [[ "$USE_CLAUDE_SVG" -eq 1 ]]; then
        run_claude_svg --scan -c posts --collections-dir "$(basename "$TMP_ROOT")"
        status=$?
        if [[ $status -eq 200 ]]; then
            python3 "$ENGINE" -c posts --collections-dir "$(basename "$TMP_ROOT")" -p local "${ARGS[@]}"
            status=$?
        fi
    else
        python3 "$ENGINE" -c posts --collections-dir "$(basename "$TMP_ROOT")" "${ARGS[@]}"
        status=$?
    fi
    set -e
    rm -rf "$TMP_ROOT"
    trap - EXIT INT TERM
    exit "$status"
fi

# The claude rung authors banners itself; everything else goes to the engine.
if [[ "$USE_CLAUDE_SVG" -eq 1 ]]; then
    status=0
    if [[ -n "$TARGET_FILE" ]]; then
        run_claude_svg --file "$TARGET_FILE" || status=$?
    else
        scan_args=(--scan)
        [[ -n "$COLLECTION_GIVEN" ]] && scan_args+=(-c "$COLLECTION_GIVEN")
        [[ -n "$COLLECTIONS_DIR_GIVEN" ]] && scan_args+=(--collections-dir "$COLLECTIONS_DIR_GIVEN")
        run_claude_svg "${scan_args[@]}" || status=$?
    fi
    if [[ $status -eq 200 ]]; then
        exec python3 "$ENGINE" -p local ${ARGS[@]+"${ARGS[@]}"}
    fi
    exit "$status"
fi

# PyYAML availability is checked by the engine itself (ensure_yaml) with an
# actionable message — no duplicate probe here.
exec python3 "$ENGINE" ${ARGS[@]+"${ARGS[@]}"}
