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

check "no Record<string, unknown> cast in DashboardPage" \
  bash -c "! grep -q 'as Record<string, unknown>' '$ROOT/cap/src/pages/dashboard/DashboardPage.tsx'"

check "DashboardKpis uses GainResult type" \
  grep -q 'GainResult' "$ROOT/cap/src/pages/dashboard/DashboardKpis.tsx"

check "build succeeds" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null 2>&1"

check "no new test failures" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm test 2>&1 | sed 's/\x1B\[[0-9;]*m//g' | grep -E '^[[:space:]]+Tests' | grep -qv 'failed'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
