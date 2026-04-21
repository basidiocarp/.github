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

check "architecture doc exists" \
  test -f "$ROOT/docs/architecture/unified-output-aggregation.md"

check "principles are named" \
  rg -q 'One aggregation path|Late rendering|Graceful degradation|Multiple rendering surfaces' \
    "$ROOT/docs/architecture/unified-output-aggregation.md"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
