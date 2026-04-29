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

check "workflow complete tests run" \
  bash -lc "cd '$ROOT/hymenium' && cargo test complete"
check "transition/outcome tests run" \
  bash -lc "cd '$ROOT/hymenium' && cargo test record_transition insert_outcome"
check "terminal idempotency cases are present" \
  bash -lc "rg -n 'already.*terminal|cancelled.*complete|complete.*cancelled|duplicate.*transition|idempotent' '$ROOT/hymenium/src' '$ROOT/hymenium/tests'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
