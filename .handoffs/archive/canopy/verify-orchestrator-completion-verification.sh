#!/bin/bash
# Verification script for orchestrator-completion-verification.md
# Run: bash .handoffs/canopy/verify-orchestrator-completion-verification.sh

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

echo "=== Orchestrator Completion Verification ==="
echo ""

echo "--- Step 1: Handoff Completeness Checker ---"
check "handoff_check module exists" \
  "test -f $ROOT/canopy/src/handoff_check.rs"
check "CompletenessReport struct defined" \
  "grep -q 'CompletenessReport' $ROOT/canopy/src/handoff_check.rs"
check "checkbox parsing logic" \
  "grep -q 'checked_checkboxes\|checkbox\|check_box' $ROOT/canopy/src/handoff_check.rs"
check "paste marker detection" \
  "grep -q 'PASTE\|paste_marker\|empty_paste' $ROOT/canopy/src/handoff_check.rs"
check "verify script detection" \
  "grep -q 'verify_script\|has_verify' $ROOT/canopy/src/handoff_check.rs"

echo ""
echo "--- Step 2: Completion Transition Gate ---"
check "completion gate in state machine" \
  "grep -rq 'check_completeness\|completeness\|is_complete' $ROOT/canopy/src/runtime.rs $ROOT/canopy/src/lib.rs 2>/dev/null"
check "rejection on incomplete handoff" \
  "grep -rq 'Rejected\|rejected\|incomplete' $ROOT/canopy/src/runtime.rs $ROOT/canopy/src/models.rs 2>/dev/null"

echo ""
echo "--- Step 3: Verify Script Execution ---"
check "verify script runner exists" \
  "grep -q 'run_verify_script\|verify_script' $ROOT/canopy/src/handoff_check.rs"
check "timeout enforcement" \
  "grep -rq 'timeout\|Duration' $ROOT/canopy/src/handoff_check.rs 2>/dev/null"

echo ""
echo "--- Step 4: MCP Tool ---"
check "check_handoff_completeness MCP tool" \
  "grep -rq 'check_handoff_completeness\|completeness' $ROOT/canopy/src/mcp/ 2>/dev/null"

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
