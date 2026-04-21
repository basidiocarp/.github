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

check "annulus statusline json wiring exists" \
  rg -q 'statusline.*json|--json|available.*reason' "$ROOT/annulus/src"

check "statusline schema exists" \
  test -f "$ROOT/septa/annulus-statusline-v1.schema.json"

check "cargo statusline tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test statusline --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
