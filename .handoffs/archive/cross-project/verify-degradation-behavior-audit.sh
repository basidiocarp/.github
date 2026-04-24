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

check "current behavior section exists" \
  rg -q 'Current Behavior' "$ROOT/docs/foundations/graceful-degradation.md"

check "tool coverage is broad" \
  rg -q 'mycelium|hyphae|rhizome|canopy|cortina|stipe|lamella|annulus|volva|cap' \
    "$ROOT/docs/foundations/graceful-degradation.md"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
