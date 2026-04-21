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

check "availability report exists" \
  rg -q 'AvailabilityReport|DegradationTier|probe_tool' "$ROOT/spore/src"

check "availability tests exist" \
  rg -q 'availability|timeout|degraded' "$ROOT/spore/src"

check "cargo availability tests pass" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo test availability --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
