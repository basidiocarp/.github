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

check "Cap source mentions status preview or resolved status" \
  rg -q 'status preview|resolved status|status customization' "$ROOT/cap/src"

check "Cap types or API mention customization capability state" \
  rg -q 'customization|capability|validation error' "$ROOT/cap/src/lib/types" "$ROOT/cap/src/lib/api" "$ROOT/cap/server/routes"

check "Cap docs or routes mention the portable contract boundary" \
  rg -q 'portable status|customization contract|resolved status|septa' "$ROOT/cap" 2>/dev/null

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
