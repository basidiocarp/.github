#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0

check_rg() {
  local pattern="$1"
  local label="${@: -1}"
  local paths=("${@:2:$#-2}")
  if rg -q "$pattern" "${paths[@]}"; then
    echo "PASS: $label"
    PASS=$((PASS+1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL+1))
  fi
}

check_rg "canopy_required_role|implementer|validator|orchestrator" "hymenium/src/dispatch" "hymenium/tests" "Canopy role mapping exists"
check_rg "parse_created_task_id|task_id" "hymenium/src/dispatch" "hymenium/tests" "Canopy JSON task id parsing exists"
check_rg "raw_id|fallback|preserves_raw" "hymenium/src/dispatch" "hymenium/tests" "raw task id fallback is tested"
check_rg "Worker|OutputVerifier|FinalVerifier|RepairWorker" "hymenium/src/dispatch" "hymenium/tests" "workflow role coverage includes dogfood roles"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

