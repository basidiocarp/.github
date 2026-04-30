#!/bin/bash
# verify-lane1-end-to-end-smoke.sh

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." && pwd )"
FINDINGS="$REPO_ROOT/.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/findings/lane1-end-to-end-smoke.md"

PASS=0; FAIL=0
echo "=== Lane 1: End-to-End Smoke — verify ==="
echo ""

echo "[Check 1] Findings file exists"
if [ -f "$FINDINGS" ]; then echo "  ✓"; PASS=$((PASS+1)); else echo "  ✗ MISSING"; FAIL=$((FAIL+1)); fi
echo ""

echo "[Check 2] Required sections present"
for s in "^## Summary" "^## Environment" "^## Per-flow Results" "^## Findings" "^## Clean Areas"; do
  if [ -f "$FINDINGS" ] && grep -qE "$s" "$FINDINGS"; then PASS=$((PASS+1)); else echo "  ✗ missing '$s'"; FAIL=$((FAIL+1)); fi
done
echo "  (per-section check complete)"
echo ""

echo "[Check 3] At least one flow recorded"
if [ -f "$FINDINGS" ] && grep -qE "PASS|DEGRADED|FAIL|UNRUNNABLE" "$FINDINGS"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ no flow verdicts recorded"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] septa/validate-all.sh remains green (sanity)"
if (cd "$REPO_ROOT/septa" && bash validate-all.sh) >/dev/null 2>&1; then echo "  ✓"; PASS=$((PASS+1)); else echo "  ✗"; FAIL=$((FAIL+1)); fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
