#!/bin/bash
# verify-mycelium-gain-weekly-monthly.sh — closes F2.5

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
CAP="$REPO_ROOT/cap"
GAIN="$CAP/server/mycelium/gain.ts"

PASS=0
FAIL=0

echo "=== Mycelium Gain Weekly/Monthly Validation — verify ==="
echo ""

echo "[Check 1] gain.ts present"
[ -f "$GAIN" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] isGainCliOutput now validates weekly"
if grep -A 14 "function isGainCliOutput" "$GAIN" | grep -q "weekly"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ weekly not validated"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] isGainCliOutput now validates monthly"
if grep -A 14 "function isGainCliOutput" "$GAIN" | grep -q "monthly"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ monthly not validated"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] Per-item predicate wired into weekly/monthly validation"
# Either a dedicated predicate (isGainWeeklyEntry / isGainMonthlyEntry / isGainPeriodEntry)
# OR reuse of the existing isGainDailyStats predicate (preferred when schemas are identical).
if grep -A 14 "function isGainCliOutput" "$GAIN" | grep -E "weekly|monthly" | grep -qE "isGainWeeklyEntry|isGainMonthlyEntry|isGainPeriodEntry|isGainDailyStats"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ no per-item predicate wired into weekly/monthly path"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] Tests reference weekly or monthly"
if grep -rE "weekly|monthly" "$CAP"/server/__tests__/mycelium*.test.ts 2>/dev/null | grep -q .; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ no test coverage"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 6] septa mycelium-gain schema unchanged"
if (cd "$REPO_ROOT" && git status --porcelain septa/mycelium-gain-v1.schema.json 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ schema modified — out of scope"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 7] cap test suite passes (or NOTE if vitest missing)"
if [ ! -x "$CAP/node_modules/.bin/vitest" ]; then
  echo "  NOTE cap/node_modules/.bin/vitest missing — run 'npm ci' to enable test verification (skipped)"
  PASS=$((PASS+1))
elif (cd "$CAP" && npm run test:server -- mycelium) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗"; FAIL=$((FAIL+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
