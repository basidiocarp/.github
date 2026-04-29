#!/usr/bin/env bash

set -euo pipefail

# Change to the workspace root so relative paths (hymenium/src, hymenium/tests)
# resolve correctly regardless of where this script is called from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$WORKSPACE_ROOT"

PASS=0
FAIL=0

check_rg() {
  local pattern="$1"
  shift
  local label="${@: -1}"  # last arg is label
  local paths=("${@:1:$#-1}")  # all but last are paths
  if rg -q "$pattern" "${paths[@]}"; then
    echo "PASS: $label"
    PASS=$((PASS+1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL+1))
  fi
}

check_rg "reconcile|refresh.*phase|sync.*canopy|Canopy.*status" hymenium/src hymenium/tests "phase reconciliation path exists"
check_rg "verification_state|completed|closed_at|completed_at" hymenium/src hymenium/tests "Canopy terminal task state is considered"
check_rg "current_phase|advance|next.*phase" hymenium/src/workflow hymenium/tests "workflow can advance after reconciliation"
check_rg "idempotent|already.*completed|repeat|repeated" hymenium/tests hymenium/src "reconciliation idempotency is tested or handled"
check_rg "task show|show_task|get_task|canopy_task_id" hymenium/src/dispatch hymenium/src/workflow hymenium/tests "reconciliation reads task status by Canopy task id"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
