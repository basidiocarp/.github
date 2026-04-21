#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

check "usage lib exists" \
  test -f "$ROOT/cap/server/lib/usage/types.ts"

check "usage route mounted" \
  bash -c "grep -q \"app\\.route('/api/usage'\" '$ROOT/cap/server/index.ts'"

check "UsageCostTab exists with KPI and chart" \
  bash -c "grep -q 'KpiCard\|BarChart\|LineChart' '$ROOT/cap/src/pages/analytics/UsageCostTab.tsx'"

check "UsageCostTab wired into AnalyticsTabs" \
  bash -c "grep -q 'UsageCostTab' '$ROOT/cap/src/pages/analytics/AnalyticsTabs.tsx'"

check "usage types exported from lib/api" \
  bash -c "grep -q 'UsageAggregate\|SessionUsage\|UsageTrend' '$ROOT/cap/src/lib/api.ts'"

check "usage query hooks exist" \
  bash -c "grep -q 'useUsageAggregate\|useUsageTrend\|useUsageSessions' '$ROOT/cap/src/lib/queries/usage.ts'"

check "build succeeds" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null 2>&1"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
