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

check "degradation doc exists" \
  test -f "$ROOT/docs/foundations/graceful-degradation.md"

check "degradation schema exists" \
  test -f "$ROOT/septa/degradation-tier-v1.schema.json"

check "tiers are described" \
  rg -q 'Critical|Optional|Enhancement' "$ROOT/docs/foundations/graceful-degradation.md"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
