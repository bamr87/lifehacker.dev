#!/usr/bin/env bash
# =============================================================================
# check-mermaid.sh — validate every Mermaid diagram in the content.
# -----------------------------------------------------------------------------
# Two checks per file that contains a ```mermaid block:
#   1. RENDER  — each block is rendered with mermaid-cli (mmdc); a syntax error
#                makes mmdc exit non-zero, which fails the check.
#   2. FLAG    — the page declares `mermaid: true` in its front matter, or the
#                theme won't initialise Mermaid and the diagram shows as raw code
#                on the live site.
#
# Requires @mermaid-js/mermaid-cli (`npm install -g @mermaid-js/mermaid-cli`).
# If mmdc isn't installed, the render check is skipped (exit 0) but the
# front-matter check still runs — so it's useful locally without Node too.
#
# Usage:  scripts/check-mermaid.sh     (exit 1 if any diagram is invalid/unflagged)
# =============================================================================
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail=0; total=0; rendered=0

# Files with a real ```mermaid fence at line start (anchored, so an inline
# mention like `` `\`\`\`mermaid` `` in prose isn't counted).
grep -rlE '^[[:space:]]*```mermaid' "$ROOT" \
  --include='*.md' --include='*.markdown' --include='*.html' 2>/dev/null \
  | grep -vE '/(_site|vendor|node_modules|\.git|\.jekyll-cache|\.bundle)/' \
  | sort > "$TMP/files.txt" || true

if [ ! -s "$TMP/files.txt" ]; then echo "no mermaid diagrams found"; exit 0; fi

# 1. Front-matter flag check (cheap, no Node needed).
while IFS= read -r f; do
  [ -e "$f" ] || continue
  if ! grep -qE '^[[:space:]]*mermaid:[[:space:]]*true' "$f"; then
    echo "  ✗ ${f#"$ROOT"/}: has a mermaid block but no 'mermaid: true' front matter (won't render live)"
    fail=$((fail+1))
  fi
done < "$TMP/files.txt"

# 2. Render check (needs mmdc).
HAVE_MMDC=0
command -v mmdc >/dev/null 2>&1 && HAVE_MMDC=1
if [ "$HAVE_MMDC" -eq 1 ]; then
  printf '{"args":["--no-sandbox","--disable-setuid-sandbox"]}\n' > "$TMP/pp.json"
  while IFS= read -r f; do
    [ -e "$f" ] || continue
    tag="$(printf '%s' "$f" | sed 's#[^A-Za-z0-9]#_#g')"
    awk -v dir="$TMP" -v tag="$tag" '
      /^[[:space:]]*```mermaid[[:space:]]*$/ { inb=1; n++; out=dir "/" tag "." n ".mmd"; next }
      /^[[:space:]]*```/ { inb=0; next }
      inb { print > out }
    ' "$f"
  done < "$TMP/files.txt"

  for m in "$TMP"/*.mmd; do
    [ -e "$m" ] || continue
    total=$((total+1))
    if mmdc -q -p "$TMP/pp.json" -i "$m" -o "$TMP/out.svg" >/dev/null 2>"$TMP/err"; then
      rendered=$((rendered+1))
    else
      echo "  ✗ invalid mermaid syntax (${m##*/}):"
      sed -E 's/^/        /' "$TMP/err" | grep -vE '^[[:space:]]*$' | head -6
      fail=$((fail+1))
    fi
  done
else
  echo "  (mmdc not installed — skipping render check; run: npm i -g @mermaid-js/mermaid-cli)"
fi

echo "---"
echo "files with diagrams: $(wc -l < "$TMP/files.txt" | tr -d ' ')  rendered ok: $rendered/$total  problems: $fail"
[ "$fail" -eq 0 ]
