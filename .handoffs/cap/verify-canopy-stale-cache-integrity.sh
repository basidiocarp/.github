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

check "Canopy stale cache tests run" \
  bash -lc "cd '$ROOT/cap' && npx vitest run server/__tests__/canopy*.test.ts"
check "stale cache is request-keyed" \
  bash -lc "rg -n 'cacheKey|requestKey|project|preset|sort|priority|severity|view|lastSnapshot' '$ROOT/cap/server/routes/canopy.ts' '$ROOT/cap/server/__tests__'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
