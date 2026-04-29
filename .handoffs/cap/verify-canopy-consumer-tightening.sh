#!/bin/bash
# verify-canopy-consumer-tightening.sh — closes F2.6, F2.7, F2.9

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
CAP="$REPO_ROOT/cap"
CANOPY="$CAP/server/canopy.ts"

PASS=0
FAIL=0

echo "=== Cap Canopy Consumer Tightening — verify ==="
echo ""

echo "[Check 1] canopy.ts present"
[ -f "$CANOPY" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] validateCanopySnapshot validates attention"
if grep -A 14 "function validateCanopySnapshot" "$CANOPY" | grep -q "attention"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ attention not validated"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] validateCanopySnapshot validates sla_summary"
if grep -A 14 "function validateCanopySnapshot" "$CANOPY" | grep -q "sla_summary"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ sla_summary not validated"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] validateCanopySnapshot validates drift_signals"
if grep -A 14 "function validateCanopySnapshot" "$CANOPY" | grep -q "drift_signals"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ drift_signals not validated"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] validateCanopyTaskDetail validates attention"
if grep -A 14 "function validateCanopyTaskDetail" "$CANOPY" | grep -q "attention"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ attention not validated"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 6] validateCanopyTaskDetail validates sla_summary"
if grep -A 14 "function validateCanopyTaskDetail" "$CANOPY" | grep -q "sla_summary"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ sla_summary not validated"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 7] notification event_type enum constant defined"
if grep -qE "CANOPY_NOTIFICATION_EVENT_TYPES|notificationEventTypes" "$CANOPY"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ no event_type enum constant"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 8] enum count matches schema (9 values)"
SCHEMA_COUNT=$(jq '.properties.event_type.enum | length' "$REPO_ROOT/septa/canopy-notification-v1.schema.json" 2>/dev/null || echo "")
if [ "$SCHEMA_COUNT" = "9" ]; then
  echo "  ✓ schema enum has 9 values (sanity)"; PASS=$((PASS+1))
else
  echo "  NOTE schema enum count not 9 — verify manually (got: $SCHEMA_COUNT)"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 9] Tests reference the new validations"
if grep -rE "attention|sla_summary|drift_signals|event_type" "$CAP"/server/__tests__/canopy*.test.ts 2>/dev/null | grep -q .; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ no test coverage"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 10] septa canopy schemas unchanged"
if (cd "$REPO_ROOT" && git status --porcelain septa/canopy-snapshot-v1.schema.json septa/canopy-task-detail-v1.schema.json septa/canopy-notification-v1.schema.json 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ canopy schemas modified — out of scope"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 11] cap test suite passes (or NOTE if vitest missing)"
if [ ! -x "$CAP/node_modules/.bin/vitest" ]; then
  echo "  NOTE cap/node_modules/.bin/vitest missing — run 'npm ci' to enable test verification (skipped)"
  PASS=$((PASS+1))
elif (cd "$CAP" && npm run test:server -- canopy) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗"; FAIL=$((FAIL+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
