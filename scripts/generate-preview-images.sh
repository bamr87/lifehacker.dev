#!/usr/bin/env bash
# =============================================================================
# generate-preview-images.sh — DEPRECATED SHIM.
# -----------------------------------------------------------------------------
# The preview-banner framework was replaced (docs/PREVIEW-IMAGES.md). The old
# pipeline resolved a "capability ladder" across the zer0-image-generator gem,
# a raster API key, and a Claude SVG companion — and in practice every rung fell
# through to the gem's deterministic `local` template. That template renders and
# exits 0, so nothing ever noticed: 200 of 243 articles shipped wearing four
# pictures between them, not one of which contained a single word.
#
# The replacement computes the art FROM the article — no gem, no API key, no
# rasterizer, no network — so it cannot silently degrade to wallpaper:
#
#   node scripts/preview/generate.mjs -f <article.md>
#
# A Claude rung DOES exist again, but as an additive layer rather than a rung in
# a ladder: scripts/preview/illustrate.mjs has Claude draw the article's subject
# into a validated motif, and a failure there is loud and leaves the computed
# banner in place. It is never reached by this shim — call it directly.
#
# This shim stays because the workflow prompt, the grow-lifehacker skill, and a
# lot of muscle memory all call the old path. It forwards the flags that still
# mean something and drops the ones that described renderers that no longer
# exist. Call the generator directly in new code.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

echo "[deprecated] scripts/generate-preview-images.sh now forwards to scripts/preview/generate.mjs" >&2
echo "[deprecated] see docs/PREVIEW-IMAGES.md — call the generator directly in new code" >&2

if ! command -v node &>/dev/null; then
    echo "[ERROR] node is required (the renderer is dependency-free JavaScript)." >&2
    exit 1
fi

ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        # Still meaningful — forwarded as-is.
        -f|--file)          ARGS+=(--file "${2:-}"); shift 2 ;;
        --file=*)           ARGS+=(--file "${1#*=}"); shift ;;
        --section)          ARGS+=(--all --section "${2:-}"); shift 2 ;;
        --section=*)        ARGS+=(--all --section "${1#*=}"); shift ;;
        --force)            ARGS+=(--force); shift ;;
        -d|--dry-run)       ARGS+=(--dry-run); shift ;;
        -v|--verbose)       ARGS+=(--verbose); shift ;;
        --changed)          ARGS+=(--changed); shift ;;
        --all)              ARGS+=(--all); shift ;;
        -h|--help)          ARGS+=(--help); shift ;;
        # `posts`/`docs` were engine collections; the sections live under
        # pages/_posts/<section>/ now, so a collection sweep is just --all.
        -c|--collection)    ARGS+=(--all); shift 2 ;;
        --collection=*)     ARGS+=(--all); shift ;;
        --collections-dir)  shift 2 ;;
        --collections-dir=*) shift ;;
        # Gone with the old pipeline: there is no raster provider, no rasterizer,
        # and no OpenAI enhance pass to select any more.
        -p|--provider|--rasterizer|--model|--style|--style-modifiers|--output-dir|--front-matter-key|--batch)
            echo "[deprecated] ignoring '$1' — the renderer is deterministic and configured in _data/preview/design.json" >&2
            shift 2 ;;
        -p=*|--provider=*|--rasterizer=*|--model=*|--style=*|--style-modifiers=*|--output-dir=*|--front-matter-key=*|--batch=*)
            echo "[deprecated] ignoring '${1%%=*}' — configured in _data/preview/design.json" >&2
            shift ;;
        -e|--enhance|--enhance-*)
            echo "[deprecated] ignoring '$1' — there is no raster enhance pass any more" >&2
            shift ;;
        --list-missing)
            echo "[deprecated] '--list-missing' → running a dry run instead" >&2
            ARGS+=(--all --dry-run); shift ;;
        *)  ARGS+=("$1"); shift ;;
    esac
done

exec node "$SCRIPT_DIR/preview/generate.mjs" ${ARGS[@]+"${ARGS[@]}"}
