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

check "ToolAdoptionScore type defined" \
  rg -q 'struct ToolAdoptionScore' "$ROOT/canopy/src"

check "store_tool_adoption_score exists" \
  rg -q 'store_tool_adoption_score|load_tool_adoption_score' "$ROOT/canopy/src"

check "task detail exposes adoption score" \
  rg -q 'tool_adoption_score' "$ROOT/canopy/src"

check "canopy tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test --workspace >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
