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

check "ecosystem status route exists" \
  rg -q 'ecosystem/status|Ecosystem Status' "$ROOT/cap/src"

check "ecosystem status UI exists" \
  rg -q 'segment|context usage|annulus not available|auto-refresh' "$ROOT/cap/src"

check "cap build passes" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
