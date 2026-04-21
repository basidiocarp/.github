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

check "lamella SessionEnd hook points at cortina" \
  rg -q 'cortina adapter claude-code session-end' "$ROOT/lamella/resources/hooks/hooks.json"

check "session-end shim removed" \
  /bin/zsh -lc "! test -f '$ROOT/lamella/scripts/hooks/session-end.js'"

check "lamella validate passes" \
  /bin/zsh -lc "cd '$ROOT/lamella' && make validate >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
