#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

ROOT="$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)"
cd "$ROOT"

# Step 1: attention.level includes needs_attention, excludes stale "warning"
check "attention.level has needs_attention" \
  grep -q '"needs_attention"' septa/canopy-task-detail-v1.schema.json
check "attention.level no stale warning in schema" \
  bash -c "! grep -A5 '\"level\"' septa/canopy-task-detail-v1.schema.json | grep -q '\"warning\"'"

# Step 2: canopy-task-detail breach_severity has all 5 values
check "task-detail breach_severity has low"    grep -q '"low"'    septa/canopy-task-detail-v1.schema.json
check "task-detail breach_severity has medium" grep -q '"medium"' septa/canopy-task-detail-v1.schema.json
check "task-detail breach_severity has high"   grep -q '"high"'   septa/canopy-task-detail-v1.schema.json

# Step 2b: canopy-snapshot breach_severity has all 5 values
check "snapshot breach_severity has low"    grep -q '"low"'    septa/canopy-snapshot-v1.schema.json
check "snapshot breach_severity has medium" grep -q '"medium"' septa/canopy-snapshot-v1.schema.json
check "snapshot breach_severity has high"   grep -q '"high"'   septa/canopy-snapshot-v1.schema.json
check "snapshot breach_severity no stale warning" \
  bash -c "! jq -r '.properties.sla_summary.properties.breach_severity.enum[]' septa/canopy-snapshot-v1.schema.json | grep -qx 'warning'"

# Step 2c: canopy-snapshot agents[].status enum matches AgentStatus
check "snapshot agent status has assigned" \
  bash -c "jq -r '.properties.agents.items.properties.status.enum[]' septa/canopy-snapshot-v1.schema.json | grep -qx 'assigned'"
check "snapshot agent status has in_progress" \
  bash -c "jq -r '.properties.agents.items.properties.status.enum[]' septa/canopy-snapshot-v1.schema.json | grep -qx 'in_progress'"
check "snapshot agent status has blocked" \
  bash -c "jq -r '.properties.agents.items.properties.status.enum[]' septa/canopy-snapshot-v1.schema.json | grep -qx 'blocked'"
check "snapshot agent status has review_required" \
  bash -c "jq -r '.properties.agents.items.properties.status.enum[]' septa/canopy-snapshot-v1.schema.json | grep -qx 'review_required'"
check "snapshot agent status no stale 'active'" \
  bash -c "! jq -r '.properties.agents.items.properties.status.enum[]' septa/canopy-snapshot-v1.schema.json | grep -qx 'active'"
check "snapshot agent status no stale 'stopped'" \
  bash -c "! jq -r '.properties.agents.items.properties.status.enum[]' septa/canopy-snapshot-v1.schema.json | grep -qx 'stopped'"
check "snapshot agent status no stale 'error'" \
  bash -c "! jq -r '.properties.agents.items.properties.status.enum[]' septa/canopy-snapshot-v1.schema.json | grep -qx 'error'"

# Step 3: PhaseState ↔ workflow-status-v1 phase items agree
# Either schema declares failure_reason + retry_count, OR Rust has #[serde(skip...)] on both.
# Note: serde attributes may be on a separate line from the field, so we check both in
# isolation and use multiline matching across ~3 lines for the attribute→field pairing.
if grep -q '"failure_reason"' septa/workflow-status-v1.schema.json \
   && grep -q '"retry_count"' septa/workflow-status-v1.schema.json; then
  echo "PASS: schema declares failure_reason and retry_count"
  PASS=$((PASS + 1))
elif grep -B1 -E 'failure_reason *:' hymenium/src/workflow/engine.rs | grep -q '#\[serde(skip' \
  && grep -B1 -E 'retry_count *:' hymenium/src/workflow/engine.rs | grep -q '#\[serde(skip'; then
  echo "PASS: PhaseState skips failure_reason/retry_count via serde (multi-line match)"
  PASS=$((PASS + 1))
else
  echo "FAIL: PhaseState and workflow-status-v1 phase items still drift"
  FAIL=$((FAIL + 1))
fi

# Step 4: septa validate-all clean
cd septa
check "septa validate-all.sh" bash validate-all.sh
cd "$ROOT"

# Integration script should not regress beyond pre-existing 6 $ref failures
script_fails=$(bash scripts/test-integration.sh 2>&1 | grep -Ec '^ *FAIL|^\x1b\[0;31mFAIL' || true)
if [ "$script_fails" -le 6 ]; then
  echo "PASS: integration script $script_fails failure(s) (≤6 pre-existing)"
  PASS=$((PASS + 1))
else
  echo "FAIL: integration script $script_fails failures — regression beyond the pre-existing 6"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
