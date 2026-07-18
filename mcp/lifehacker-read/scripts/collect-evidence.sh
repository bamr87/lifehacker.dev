#!/usr/bin/env bash
# =============================================================================
# collect-evidence.sh — reproducible test evidence for lifehacker-read.
# -----------------------------------------------------------------------------
# Runs typecheck + production build + the unit/integration suite + the stdio
# end-to-end smoke, then PROVES the server wrote nothing to the repo (git status
# before == after) and prints the on-disk numbers the tests cross-check against.
# Writes nothing into the repo itself (dist/ is gitignored). Exits non-zero if
# anything fails, so its output is honest.
#   bash scripts/collect-evidence.sh
# =============================================================================
set -uo pipefail
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "$PKG/../.." && pwd)"
cd "$PKG"
export LH_REPO_ROOT="$REPO"
FAIL=0

run() {
  local label="$1"; shift
  echo "----- $label -----"
  if "$@"; then echo "[$label] OK"; else local rc=$?; echo "[$label] FAILED (exit $rc)"; FAIL=1; fi
  echo
}

echo "============================================================"
echo " lifehacker-read — test evidence"
echo "============================================================"
echo "node:   $(node --version)"
echo "npm:    $(npm --version)"
echo "os:     $(uname -sr)"
echo "repo:   $REPO"
echo "commit: $(git -C "$REPO" rev-parse --short HEAD) on $(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
echo

echo "===== no-write proof: repo status BEFORE ====="
BEFORE="$(git -C "$REPO" status --porcelain)"
echo "${BEFORE:-<clean tree>}"
echo

run "typecheck (tsc, tests included)" npm run --silent typecheck
run "build (production tsc)"          npm run --silent build
run "unit + integration suite"        npm test
run "stdio end-to-end smoke"          npm run --silent smoke

echo "===== no-write proof: repo status AFTER ====="
AFTER="$(git -C "$REPO" status --porcelain)"
echo "${AFTER:-<clean tree>}"
if [ "$BEFORE" = "$AFTER" ]; then
  echo "[no-write] OK — exercising the server + tests modified nothing tracked in the repo"
else
  echo "[no-write] FAILED — the repo changed during the run"
  FAIL=1
fi
echo

echo "===== cross-check: on-disk numbers the suite asserts against ====="
# hacks/tools/field-notes are section subdirs of the posts collection; docs/about
# are standalone page collections. Public URLs are preserved across the reorg.
for entry in "hacks:pages/_posts/hacks" "tools:pages/_posts/tools" "field-notes:pages/_posts/field-notes" "docs:pages/_docs" "about:pages/_about"; do
  dir="${entry#*:}"
  n=$(ls "$REPO/$dir"/*.md 2>/dev/null | wc -l | tr -d ' ')
  printf "  %-26s %s markdown files\n" "$dir:" "$n"
done
# Backlog counts via a real YAML parse (NOT grep — grep over-counts the schema
# comment lines that contain 'status: todo'; the tools + tests parse YAML).
BL="$(node -e "const y=require('yaml'),fs=require('fs');const b=(y.parse(fs.readFileSync('$REPO/_data/backlog.yml','utf8')).backlog)||[];process.stdout.write(b.length+' '+b.filter(i=>i.status==='todo').length+' '+b.filter(i=>i.status==='done').length)")"
read -r BL_TOTAL BL_TODO BL_DONE <<<"$BL"
printf "  %-14s %s (yaml parse)\n" "backlog total:" "$BL_TOTAL"
printf "  %-14s %s (yaml parse)\n" "backlog todo:"  "$BL_TODO"
printf "  %-14s %s (yaml parse)\n" "backlog done:"  "$BL_DONE"
printf "  %-14s %s findings\n"     "health queue:"  "$(node -e "console.log(require('$REPO/_data/health/queue.json').length)")"
printf "  %-14s %s banned-when-sincere words\n" "glossary:"  "$(node -e "const y=require('yaml');const fs=require('fs');console.log((y.parse(fs.readFileSync('$REPO/_data/brand/glossary.yml','utf8')).banned_when_sincere||[]).length)")"
echo

echo "============================================================"
if [ "$FAIL" = 0 ]; then echo " RESULT: ALL EVIDENCE CHECKS PASSED"; else echo " RESULT: SOME CHECKS FAILED"; fi
echo "============================================================"
exit "$FAIL"
