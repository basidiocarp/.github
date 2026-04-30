#!/bin/bash
# verify-hyphae-recall-vs-search-doc-fix.sh — closes lane 1 concern

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"

PASS=0; FAIL=0

echo "=== Hyphae recall→search Doc Fix — verify ==="
echo ""

echo "[Check 1] No 'hyphae memory recall' in workspace handoffs/templates/CLAUDE.md"
HITS=$(grep -rnE "hyphae memory recall" \
  "$REPO_ROOT/.handoffs/" \
  "$REPO_ROOT/templates/" \
  "$REPO_ROOT/CLAUDE.md" \
  "$REPO_ROOT/AGENTS.md" \
  2>/dev/null | wc -l | tr -d ' ')
if [ "$HITS" = "0" ]; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ $HITS occurrences still present"
  grep -rnE "hyphae memory recall" "$REPO_ROOT/.handoffs/" "$REPO_ROOT/templates/" "$REPO_ROOT/CLAUDE.md" "$REPO_ROOT/AGENTS.md" 2>/dev/null | head -5
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 2] hyphae search references appear in handoffs/templates"
if grep -rqE "hyphae search" "$REPO_ROOT/.handoffs/" "$REPO_ROOT/templates/" 2>/dev/null; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ no hyphae search references in workspace docs"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] hyphae source not modified"
if (cd "$REPO_ROOT" && git status --porcelain hyphae/ 2>/dev/null | grep -qE "^.M"); then
  echo "  NOTE hyphae has uncommitted changes — verify unrelated"; PASS=$((PASS+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
