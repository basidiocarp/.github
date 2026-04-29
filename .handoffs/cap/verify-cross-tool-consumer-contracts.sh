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

check "evidence source kind exists in Septa" \
  rg -n '"script_verification"' "$ROOT/septa/evidence-ref-v1.schema.json"
check "Cap evidence validator knows script_verification" \
  rg -n "script_verification" "$ROOT/cap/server/lib/canopy-validators.ts" "$ROOT/cap/src/lib/types"
check "Cap Annulus adapter has server tests" \
  test -f "$ROOT/cap/server/__tests__/annulus.test.ts"
check "Cap Canopy validator tests exist" \
  test -f "$ROOT/cap/server/__tests__/canopy-validators.test.ts"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
