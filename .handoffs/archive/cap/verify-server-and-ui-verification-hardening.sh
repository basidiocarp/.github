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

check "Cap validator and API tests run" \
  bash -lc "cd '$ROOT/cap' && npx vitest run server/__tests__/canopy-validators.test.ts server/__tests__/api.test.ts"
check "Cap contract consumer tests run" \
  bash -lc "cd '$ROOT/cap' && npx vitest run server/__tests__/canopy-client.test.ts server/__tests__/annulus.test.ts"
check "Canopy UI behavior tests run" \
  bash -lc "cd '$ROOT/cap' && npx vitest run --config vitest.frontend.config.ts src/pages/Canopy.test.tsx"
check "tests mention malformed/blank payload coverage" \
  bash -lc "rg -n 'null|array|blank|whitespace|malformed|400|not.*called|toHaveBeenCalledTimes\\(0\\)' '$ROOT/cap/server/__tests__' '$ROOT/cap/src/pages/Canopy.test.tsx'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
