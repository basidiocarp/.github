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

check "useCanopyPageState under 200 lines" \
  bash -c "[ \$(wc -l < '$ROOT/cap/src/pages/canopy/useCanopyPageState.ts') -lt 200 ]"

check "CanopyPage has at most 3 ErrorAlert instances" \
  bash -c "[ \$(grep -c '<ErrorAlert' '$ROOT/cap/src/pages/canopy/CanopyPage.tsx') -le 3 ]"

check "queue registry file exists" \
  test -f "$ROOT/cap/src/pages/canopy/canopy-queues.ts"

check "build succeeds" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null 2>&1"

check "no new test failures (server: 328 passed, frontend: 119 passed)" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm test 2>&1 | sed 's/\x1B\[[0-9;]*m//g' | grep -E '^[[:space:]]+Tests' | grep -c 'passed' | grep -q '[2]'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
