#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0

check_rg() {
  local pattern="$1"
  local path="$2"
  local label="$3"
  if rg -q "$pattern" "$path"; then
    echo "PASS: $label"
    ((PASS++))
  else
    echo "FAIL: $label"
    ((FAIL++))
  fi
}

check_rg "build.*title|title.*handoff|phase.*title" "hymenium/src/dispatch hymenium/tests" "task title generation is explicit"
check_rg "non-goal|Non-goal|non_goals" "hymenium/src/dispatch hymenium/src/parser hymenium/tests" "non-goal handling is represented"
check_rg "read-only|write scope|artifact|Allowed write scope" "hymenium/src/dispatch hymenium/src/parser hymenium/tests" "read-only and artifact write semantics are represented"
check_rg "capability_requirements|tools|read|write" "hymenium/src/dispatch hymenium/tests" "tool capability requirements are tested"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

