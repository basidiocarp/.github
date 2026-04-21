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

check "notification API route exists" \
  rg -q 'canopy/notifications|api/canopy/notifications' "$ROOT/cap/src"

check "notification UI exists" \
  rg -q 'notification.*badge|clear all|mark read|severity' "$ROOT/cap/src"

check "cap build passes" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
