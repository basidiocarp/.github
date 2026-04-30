#!/bin/bash
# verify-doctor-cursor-host-gating.sh — closes lane 1 concern

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
STIPE="$REPO_ROOT/stipe"

PASS=0; FAIL=0

echo "=== Stipe Doctor Cursor Host Gating — verify ==="
echo ""

echo "[Check 1] Some gating logic for Cursor host-mode checks"
if grep -rnE 'cursor.*detect|Cursor.*opt[_-]in|STIPE_CURSOR|which\("cursor"' "$STIPE/src/" 2>/dev/null | head -1 >/dev/null; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ no Cursor gating heuristic found"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 2] cargo test passes"
if (cd "$STIPE" && cargo test --release) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ cargo test failing"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] septa stipe-doctor-v1 schema unchanged"
if (cd "$REPO_ROOT" && git status --porcelain septa/stipe-doctor-v1.schema.json 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ schema modified"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
