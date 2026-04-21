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

check "lamella docs mention tool annotations" \
  rg -q 'annotation|readOnlyHint|destructiveHint|idempotentHint' "$ROOT/lamella/docs" "$ROOT/lamella"

check "lamella validate passes" \
  /bin/zsh -lc "cd '$ROOT/lamella' && make validate >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
