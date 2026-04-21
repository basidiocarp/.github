#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

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

ROOT="/Users/williamnewton/projects/basidiocarp"
cd "$ROOT/cap"

check "Explicit unauthenticated override exists" \
  rg -q "CAP_ALLOW_UNAUTHENTICATED" "server/index.ts"
check "Health route stays special-cased" \
  rg -q "/api/health" "server/index.ts"
check "Auth tests cover missing API key behavior" \
  rg -q "API key required|CAP_ALLOW_UNAUTHENTICATED|/api/health" "server/__tests__/auth-hardening.test.ts"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
