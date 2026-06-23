#!/usr/bin/env bash
# =============================================================================
# check-links.sh — verify that internal links/images in a built _site resolve.
# -----------------------------------------------------------------------------
# Fast, dependency-free gate: parses every built .html for absolute internal
# href/src targets and confirms each one maps to a real file in the output.
# (External links and deep HTML validation are htmlproofer's job in CI; this is
# the quick, deterministic check that catches broken nav + cross-page links.)
#
# Usage:  scripts/check-links.sh [SITE_DIR]      # default: _site
# Exit:   0 = all internal targets resolve; 1 = broken links found; 2 = usage.
# =============================================================================
set -uo pipefail

SITE="${1:-_site}"
[[ -d "$SITE" ]] || { echo "check-links: site dir not found: $SITE" >&2; exit 2; }
SITE="${SITE%/}"

# Ignore non-navigational schemes + same-page anchors + known placeholders.
ignore() {
  case "$1" in
    ''|'#'*|'/#'|mailto:*|tel:*|javascript:*|data:*) return 0 ;;
    http://*|https://*|//*) return 0 ;;     # external
  esac
  return 1
}

pairs="$(mktemp)"; broken="$(mktemp)"
trap 'rm -f "$pairs" "$broken"' EXIT

# Collect (file<TAB>url) for every href/src in every built page.
while IFS= read -r -d '' f; do
  grep -oE '(href|src)="[^"]*"' "$f" 2>/dev/null \
    | sed -E 's/^(href|src)="//; s/"$//' \
    | while IFS= read -r url; do printf '%s\t%s\n' "$f" "$url"; done
done < <(find "$SITE" -name '*.html' -print0) >"$pairs"

checked=0
while IFS=$'\t' read -r f url; do
  ignore "$url" && continue
  [[ "$url" == /* ]] || continue            # only check absolute internal links
  path="${url%%#*}"; path="${path%%\?*}"    # strip fragment + query
  [[ -z "$path" ]] && continue
  checked=$((checked+1))

  if [[ "$path" == */ ]]; then
    target="$SITE${path}index.html"
  elif [[ "$(basename "$path")" == *.* ]]; then
    target="$SITE$path"                      # has an extension (.xml/.json/.png/...)
  elif [[ -f "$SITE$path/index.html" ]]; then
    target="$SITE$path/index.html"
  elif [[ -f "$SITE$path.html" ]]; then
    target="$SITE$path.html"
  else
    target="$SITE$path"                      # will fail below → reported
  fi

  [[ -e "$target" ]] || printf '%s\t%s\n' "$url" "${f#"$SITE"/}" >>"$broken"
done <"$pairs"

n="$(sort -u "$broken" | wc -l | tr -d ' ')"
if [[ "$n" -gt 0 ]]; then
  echo "✗ $n broken internal link(s) of $checked checked:"
  sort -u "$broken" | while IFS=$'\t' read -r url src; do
    printf '   %-40s ← %s\n' "$url" "$src"
  done
  exit 1
fi
echo "✓ all $checked internal links resolve"
