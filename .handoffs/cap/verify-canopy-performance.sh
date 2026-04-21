#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

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

ROOT="/Users/williamnewton/projects/basidiocarp"

check "Canopy page state no longer fans out every preset query eagerly" \
  bash -lc "! rg -c 'useCanopySnapshot\\(' '$ROOT/cap/src/pages/canopy/useCanopyPageState.ts' | awk '{ exit !($1 < 20) }'"
check "Task operator section was decomposed" \
  bash -lc "test \$(wc -l < '$ROOT/cap/src/pages/canopy/TaskOperatorActionsSection.tsx') -lt 500"
check "Canopy route tests still exist" \
  test -f "$ROOT/cap/src/pages/Canopy.test.tsx"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
