#!/bin/bash
# Verification script for scope-detection-protocol.md
# Run: bash .handoffs/canopy/verify-scope-detection-protocol.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Scope Detection Protocol Verification ==="
echo ""

echo "--- Step 1: Scope-Blocked Status ---"
check "TaskStatus::Blocked variant exists" \
  "grep -q 'Blocked' $ROOT/canopy/src/models.rs"
check "Blocked has reason field" \
  "grep -A5 'Blocked' $ROOT/canopy/src/models.rs | grep -q 'reason'"
check "parent_task_id field on Task" \
  "grep -q 'parent_task_id' $ROOT/canopy/src/models.rs"
check "parent_task_id in schema" \
  "grep -q 'parent_task_id' $ROOT/canopy/src/store/schema.rs"

echo ""
echo "--- Step 2: Scope Classification Logic ---"
check "ScopeGap enum exists" \
  "grep -q 'ScopeGap' $ROOT/canopy/src/scope.rs"
check "Blocking variant exists" \
  "grep -q 'Blocking' $ROOT/canopy/src/scope.rs"
check "NonBlocking variant exists" \
  "grep -q 'NonBlocking' $ROOT/canopy/src/scope.rs"
check "classify_scope_gap function exists" \
  "grep -q 'classify_scope_gap' $ROOT/canopy/src/scope.rs"

echo ""
echo "--- Step 3: State Machine Transitions ---"
check "handle_scope_gap function exists" \
  "grep -rq 'handle_scope_gap\|scope_gap' $ROOT/canopy/src/runtime.rs $ROOT/canopy/src/lib.rs 2>/dev/null"
check "child task creation for blocking gaps" \
  "grep -rq 'create_child_task\|child_task' $ROOT/canopy/src/ 2>/dev/null"

echo ""
echo "--- Step 4: MCP Tools ---"
check "report_scope_gap tool exists" \
  "grep -rq 'report_scope_gap\|scope_gap' $ROOT/canopy/src/mcp/ 2>/dev/null"
check "get_handoff_scope tool exists" \
  "grep -rq 'get_handoff_scope\|handoff_scope' $ROOT/canopy/src/mcp/ 2>/dev/null"

echo ""
echo "--- Build Verification ---"
check "canopy cargo test passes" \
  "cd $ROOT/canopy && cargo test --quiet 2>&1"
check "canopy cargo clippy clean" \
  "cd $ROOT/canopy && cargo clippy --all-targets --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
