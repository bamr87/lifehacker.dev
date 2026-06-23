#!/usr/bin/env bash
# =============================================================================
# audit.sh — full local QA gate. Mirrors what CI does, on your machine.
# -----------------------------------------------------------------------------
# Builds the site (faithful remote-theme overlay, via Docker), then runs the
# same checks CI runs: internal link check, the session-scribe test suite, and
# the follow-up-tag scan (writing TODO.md).
#
# Requires Docker. Usage:  scripts/audit.sh    (exit non-zero if anything fails)
# =============================================================================
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="${AUDIT_DIR:-/tmp/lh-audit}"
fail=0

echo "==> building faithful overlay → $DIR (Docker)"
PREVIEW_DIR="$DIR" bash "$REPO/scripts/preview.sh" build >/dev/null 2>&1
( cd "$DIR" && docker compose run --rm --no-deps jekyll \
    sh -c "(bundle check || bundle install --jobs 4 --retry 3) && bundle exec jekyll build --config _config.yml,_config_dev.yml" \
) >"$DIR/build.log" 2>&1
SITE="$DIR/_site"
if [[ -d "$SITE" ]]; then
  echo "✓ build ok ($(find "$SITE" -name '*.html' | wc -l | tr -d ' ') pages)"
else
  echo "✗ build FAILED — see $DIR/build.log"; exit 1
fi

echo; echo "==> internal links"
bash "$REPO/scripts/check-links.sh" "$SITE" || fail=1

echo; echo "==> unit tests (scribe + checkers)"
bash "$REPO/scripts/test-session-scribe.sh" >/dev/null && echo "✓ scribe tests pass" || { echo "✗ scribe tests FAILED"; fail=1; }
bash "$REPO/scripts/test-checks.sh" >/dev/null && echo "✓ checker tests pass" || { echo "✗ checker tests FAILED"; fail=1; }

echo; echo "==> mermaid diagrams (front-matter flag; render needs mmdc)"
bash "$REPO/scripts/check-mermaid.sh" || fail=1

echo; echo "==> follow-up tags"
bash "$REPO/scripts/check-todos.sh" --write >/dev/null 2>&1
echo "✓ TODO.md refreshed"

echo
if [[ "$fail" -eq 0 ]]; then echo "===== AUDIT PASSED ====="; else echo "===== AUDIT FAILED ====="; fi
exit "$fail"
