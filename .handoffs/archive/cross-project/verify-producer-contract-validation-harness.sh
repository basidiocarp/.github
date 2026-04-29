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

check "Septa canonical validation passes" \
  bash -lc "cd '$ROOT/septa' && bash validate-all.sh"
check "cross-tool payload registry passes" \
  bash -lc "cd '$ROOT/septa' && bash scripts/check-cross-tool-payloads.sh"
check "producer-output validation helper exists" \
  bash -lc "rg -n 'producer|captured|stdout|local registry|validate.*output' '$ROOT/septa/scripts' '$ROOT/septa/README.md'"
check "producer contract tests reference Septa schemas" \
  bash -lc "rg -n 'septa|schema|validate' '$ROOT/cap/server/__tests__' '$ROOT'/*/tests"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
