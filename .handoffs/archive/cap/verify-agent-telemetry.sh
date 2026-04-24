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

check "telemetry lib exists" \
  test -f "$ROOT/cap/server/lib/telemetry.ts"

check "telemetry route exists" \
  bash -c "grep -q 'aggregateTelemetry' '$ROOT/cap/server/routes/telemetry.ts'"

check "TelemetryTab exists with KPI and chart" \
  bash -c "grep -q 'KpiCard\|BarChart\|LineChart' '$ROOT/cap/src/pages/analytics/TelemetryTab.tsx'"

check "TelemetryTab wired into AnalyticsTabs" \
  bash -c "grep -q 'TelemetryTab' '$ROOT/cap/src/pages/analytics/AnalyticsTabs.tsx'"

check "telemetry query hook exists" \
  bash -c "grep -rq 'useTelemetry' '$ROOT/cap/src/'"

check "build succeeds" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null 2>&1"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
