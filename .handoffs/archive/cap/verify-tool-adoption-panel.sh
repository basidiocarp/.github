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

check "cap source mentions tool adoption panel" \
  rg -q 'Tool Usage|tool adoption|relevant-but-unused|adoption score' "$ROOT/cap/src"

check "cap tests pass" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm test >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
