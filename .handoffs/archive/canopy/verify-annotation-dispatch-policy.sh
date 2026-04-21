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

check "canopy dispatch policy references annotations" \
  rg -q 'readOnlyHint|destructiveHint|annotation|policy show|auto-approve-destructive' "$ROOT/canopy/src"

check "canopy dispatch policy tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test dispatch_policy --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
