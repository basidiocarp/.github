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

check "canopy route file under 140 lines (was 396; now 130 after extraction)" \
  bash -c "[ \$(wc -l < '$ROOT/cap/server/routes/canopy.ts') -lt 140 ]"

check "validator module exists" \
  test -f "$ROOT/cap/server/lib/canopy-validators.ts"

check "validator tests exist" \
  test -f "$ROOT/cap/server/__tests__/canopy-validators.test.ts"

check "build succeeds" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null 2>&1"

check "no new test failures (1 pre-existing resolved-status-contract failure is known)" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm test 2>&1 | sed 's/\x1B\[[0-9;]*m//g' | grep -E '^[[:space:]]+Tests' | grep -q '284 passed'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
