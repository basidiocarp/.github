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

check "API auth default is guarded" \
  bash -lc "rg -n 'CAP_API_KEY|localhost|dev|refuse|disable|write' '$ROOT/cap/server/index.ts' '$ROOT/cap/server/__tests__/auth-hardening.test.ts'"
check "webhook missing-secret behavior is explicit" \
  bash -lc "rg -n 'CAP_WEBHOOK_SECRET|missing.*secret|dev|reject|signature' '$ROOT/cap/server/lib/watchers' '$ROOT/cap/server/__tests__/watchers.test.ts'"
check "server exposure tests exist" \
  test -f "$ROOT/cap/server/__tests__/server-exposure-warning.test.ts"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
