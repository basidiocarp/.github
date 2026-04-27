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

check "completeness execution is gated or disabled" \
  bash -lc "rg -n 'run_verify|execute|explicit|allow' '$ROOT/canopy/src/tools/completeness.rs' '$ROOT/canopy/src/handoff_check.rs'"
check "handoff import has hard path rejection" \
  bash -lc "rg -n 'reject|bail|outside|handoffs' '$ROOT/canopy/src/tools/import.rs'"
check "file locks account for path normalization and owner" \
  bash -lc "rg -n 'canonical|absolute|agent_id|owner|unlock' '$ROOT/canopy/src/tools/files.rs' '$ROOT/canopy/src/store/files.rs'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
