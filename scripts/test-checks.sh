#!/usr/bin/env bash
# =============================================================================
# test-checks.sh — tests for the QA checkers (check-links.sh, check-todos.sh).
# Offline, deterministic, fixture-based. Run: scripts/test-checks.sh
# =============================================================================
set -uo pipefail

SD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
P=0; F=0
ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; P=$((P+1)); }
no() { printf '  \033[31m✗\033[0m %s\n' "$1"; F=$((F+1)); }

echo "== check-links =="
S="$TMP/site"; mkdir -p "$S/foo"
printf '<a href="/foo/">ok</a><a href="https://example.com">ext</a><a href="#x">frag</a>\n' >"$S/index.html"
printf '<html>foo</html>\n' >"$S/foo/index.html"
bash "$SD/check-links.sh" "$S" >/dev/null 2>&1 && ok "clean site passes (ignores external + fragment)" || no "clean site wrongly flagged"

printf '<a href="/missing/">x</a><img src="/nope.png">\n' >>"$S/index.html"
bash "$SD/check-links.sh" "$S" >/dev/null 2>&1 && no "broken site NOT flagged" || ok "broken link + image flagged"
OUT="$(bash "$SD/check-links.sh" "$S" 2>&1)"
printf '%s' "$OUT" | grep -q '/missing/' && ok "names the broken page link" || no "broken page link not named"
printf '%s' "$OUT" | grep -q '/nope.png' && ok "names the broken image" || no "broken image not named"

echo "== check-todos =="
R="$TMP/repo"; mkdir -p "$R/scripts"
cp "$SD/check-todos.sh" "$R/scripts/check-todos.sh"
printf '# TODO: a real one\n'                 >"$R/a.md"
printf 'Example: run `rg TODO` to search.\nThe id HACK-001 is not a tag.\n' >"$R/b.md"
printf 'config: x  # FIX(upstream): a tagged fix\n' >"$R/c.yml"
REP="$(CLAUDE_PROJECT_DIR="$R" bash "$R/scripts/check-todos.sh" 2>/dev/null)"
printf '%s' "$REP" | grep -q 'a.md'  && ok "finds annotated TODO:"          || no "missed real TODO:"
printf '%s' "$REP" | grep -q 'c.yml' && ok "finds FIX(scope): form"         || no "missed FIX(upstream):"
printf '%s' "$REP" | grep -q 'b.md'  && no "false positive on rg TODO / HACK-001" || ok "ignores 'rg TODO' and 'HACK-001'"

echo "== $P passed, $F failed =="
[ "$F" -eq 0 ]
