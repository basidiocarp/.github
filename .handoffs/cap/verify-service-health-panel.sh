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

check "service health UI exists" \
  rg -q 'service health|green|amber|red|dismiss' "$ROOT/cap/src"

check "availability source is consumed" \
  rg -q 'annulus status|AvailabilityReport|service health' "$ROOT/cap/src"

check "cap build passes" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
