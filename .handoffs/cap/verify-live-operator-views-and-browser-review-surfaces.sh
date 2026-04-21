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

check "Cap API or route layer mentions operator workflow surfaces" \
  rg -q 'queue|review|browser|preview|session|workflow' "$ROOT/cap/server/routes" "$ROOT/cap/src/lib/api"

check "Cap page layer mentions canopy or session operator views" \
  rg -q 'queue|review|browser|preview|session|workflow' "$ROOT/cap/src/pages/canopy" "$ROOT/cap/src/pages/sessions"

check "Cap query or type layer mentions typed operator models" \
  rg -q 'queue|review|browser|preview|session|workflow' "$ROOT/cap/src/lib/queries" "$ROOT/cap/src/lib/types" "$ROOT/cap/src/types"

check "Cap keeps backend ownership visible" \
  rg -q 'canopy|hyphae|volva' "$ROOT/cap/server" "$ROOT/cap/src"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
