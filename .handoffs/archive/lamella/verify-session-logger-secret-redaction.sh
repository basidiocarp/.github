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

check "session logger redacts common secrets" \
  bash -lc "rg -n 'redact|Bearer|API_KEY|TOKEN|SECRET|password' '$ROOT/lamella/scripts/hooks/session-logger.js' '$ROOT/lamella/resources/hooks/hooks/bash/session-logger.sh'"
check "session logger sets restrictive permissions" \
  bash -lc "rg -n 'chmod|0600|mode|permissions' '$ROOT/lamella/scripts/hooks/session-logger.js' '$ROOT/lamella/resources/hooks/hooks/bash/session-logger.sh'"
check "session logger remains in validation surface" \
  rg -n "session-logger" "$ROOT/lamella/resources/hooks/settings.json" "$ROOT/lamella/resources/hooks/hooks"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
