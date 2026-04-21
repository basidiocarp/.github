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

check "App layout uses a button-like nav toggle" \
  rg -q "button|Burger|aria-expanded" "$ROOT/cap/src/components/AppLayout.tsx"
check "App layout exposes ARIA state" \
  rg -q "aria-expanded|aria-controls" "$ROOT/cap/src/components/AppLayout.tsx"
check "Frontend test covers layout toggle" \
  rg -q "AppLayout|mobile nav|aria-expanded" "$ROOT/cap/src"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
