#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0

check_rg() {
  local pattern="$1"
  local path="$2"
  local label="$3"
  if rg -q -e "$pattern" $path; then
    echo "PASS: $label"
    PASS=$((PASS+1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL+1))
  fi
}

check_rg "--workflow-id|workflow_id" "hymenium/src/dispatch hymenium/tests" "dispatch passes workflow identity to Canopy"
check_rg "--phase-id|phase_id" "hymenium/src/dispatch hymenium/tests" "dispatch passes phase identity to Canopy"
check_rg "handoff_path|handoff path|canonicalize" "hymenium/src hymenium/tests" "actual handoff path is persisted or displayed"
check_rg "agent_id|canopy_task_id|task_id" "hymenium/src/workflow hymenium/src/commands hymenium/tests" "phase runtime ids are persisted or surfaced"
check_rg "project_root|canonicalize|absolute" "hymenium/src hymenium/tests" "project root is resolvable from workflow state"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

