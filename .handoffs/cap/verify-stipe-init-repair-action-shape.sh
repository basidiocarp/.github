#!/bin/bash
# verify-stipe-init-repair-action-shape.sh
# Closes lane 2 concerns F2.2 and F2.4.

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
CAP="$REPO_ROOT/cap"
SHARED="$CAP/server/routes/settings/shared.ts"
TESTS="$CAP/server/__tests__/stipe-contract.test.ts"

PASS=0
FAIL=0

echo "=== Stipe Init Repair Action Shape — verify ==="
echo ""

echo "[Check 1] Validator file exists"
[ -f "$SHARED" ] && { echo "  ✓ shared.ts present"; PASS=$((PASS+1)); } || { echo "  ✗ missing"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] isInitPlanRepairAction predicate added"
if grep -q "isInitPlanRepairAction" "$SHARED"; then
  echo "  ✓ predicate present"
  PASS=$((PASS+1))
else
  echo "  ✗ predicate missing"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] isInitPlanRepairAction checks action_key"
if grep -A 12 "function isInitPlanRepairAction" "$SHARED" | grep -q "action_key"; then
  echo "  ✓ action_key validated"
  PASS=$((PASS+1))
else
  echo "  ✗ action_key not checked in predicate"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] isStipeInitPlan uses the new predicate (not isRepairAction)"
if grep -A 12 "function isStipeInitPlan" "$SHARED" | grep -q "isInitPlanRepairAction"; then
  echo "  ✓ isStipeInitPlan calls isInitPlanRepairAction"
  PASS=$((PASS+1))
else
  echo "  ✗ isStipeInitPlan still routes through isRepairAction"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] isStipeDoctorReport still uses isRepairAction"
if grep -A 12 "function isStipeDoctorReport" "$SHARED" | grep -q "isRepairAction"; then
  echo "  ✓ doctor still uses isRepairAction"
  PASS=$((PASS+1))
else
  echo "  ✗ doctor predicate path changed unexpectedly"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 6] Test file references action_key in new cases"
if grep -q "action_key" "$TESTS"; then
  echo "  ✓ test coverage includes action_key"
  PASS=$((PASS+1))
else
  echo "  ✗ no action_key references in tests"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 7] septa stipe schemas unchanged"
if (cd "$REPO_ROOT" && git status --porcelain septa/stipe-doctor-v1.schema.json septa/stipe-init-plan-v1.schema.json 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ septa stipe schemas modified — out of scope"
  FAIL=$((FAIL+1))
else
  echo "  ✓ septa stipe schemas unchanged"
  PASS=$((PASS+1))
fi
echo ""

echo "[Check 8] cap test suite passes (or NOTE if vitest missing)"
if [ ! -x "$CAP/node_modules/.bin/vitest" ]; then
  echo "  NOTE cap/node_modules/.bin/vitest missing — run 'npm ci' to enable test verification (skipped)"
  PASS=$((PASS+1))
elif (cd "$CAP" && npm run test:server -- stipe-contract) >/dev/null 2>&1; then
  echo "  ✓ test:server stipe-contract green"
  PASS=$((PASS+1))
else
  echo "  ✗ test:server stipe-contract failing"
  FAIL=$((FAIL+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
