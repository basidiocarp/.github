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

check "cortina source mentions cache-friendly ordering" \
  rg -q 'cache|stable|dynamic|context assembly|L0|L1|L2|L3' "$ROOT/cortina/src" "$ROOT/cortina"

check "cortina tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test --workspace --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
