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

check "annulus status command exists" \
  rg -q 'annulus status|status --json|degraded' "$ROOT/annulus/src"

check "spore availability is consumed" \
  rg -q 'AvailabilityReport|probe_tool|DegradationTier' "$ROOT/annulus/src"

check "cargo status tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test status --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
