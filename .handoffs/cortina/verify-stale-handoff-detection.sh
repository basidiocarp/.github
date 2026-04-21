#!/bin/bash
# Verification script for stale-handoff-detection.md
# Run: bash .handoffs/cortina/verify-stale-handoff-detection.sh

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

echo "=== Stale Handoff Detection Verification ==="
echo ""

echo "--- Step 1: Handoff Path Extraction ---"
check "handoff_paths module exists" \
  "test -f $ROOT/cortina/src/handoff_paths.rs"
check "HandoffPaths struct defined" \
  "grep -q 'HandoffPaths' $ROOT/cortina/src/handoff_paths.rs"
check "ChecklistItem struct defined" \
  "grep -q 'ChecklistItem' $ROOT/cortina/src/handoff_paths.rs"
check "extract_paths function exists" \
  "grep -q 'extract_paths' $ROOT/cortina/src/handoff_paths.rs"

echo ""
echo "--- Step 2: Session-End Staleness Check ---"
check "staleness check in stop hook" \
  "grep -q 'staleness\|stale_handoff\|handoff_staleness' $ROOT/cortina/src/hooks/stop.rs"
check "StaleHandoffWarning struct" \
  "grep -rq 'StaleHandoffWarning\|stale.*warning' $ROOT/cortina/src/ 2>/dev/null"
check "stale_handoff_detection_enabled policy flag" \
  "grep -q 'stale_handoff_detection_enabled' $ROOT/cortina/src/policy.rs"

echo ""
echo "--- Step 3: Pre-Dispatch Audit Command ---"
check "audit-handoff CLI command exists" \
  "grep -q 'audit.handoff\|audit_handoff' $ROOT/cortina/src/cli.rs"
check "AuditResult struct defined" \
  "grep -rq 'AuditResult' $ROOT/cortina/src/handoff_audit.rs 2>/dev/null || grep -rq 'AuditResult' $ROOT/cortina/src/ 2>/dev/null"
check "AuditEvidence struct defined" \
  "grep -rq 'AuditEvidence' $ROOT/cortina/src/ 2>/dev/null"

echo ""
echo "--- Step 4: Canopy Pre-Flight Integration ---"
check "pre-dispatch audit in canopy" \
  "grep -rq 'pre_dispatch\|audit_handoff\|cortina.*audit' $ROOT/canopy/src/runtime.rs $ROOT/canopy/src/ 2>/dev/null"
check "graceful degradation when cortina unavailable" \
  "grep -rq 'graceful\|fallback\|unavailable\|Err.*proceed' $ROOT/canopy/src/ 2>/dev/null"

echo ""
echo "--- Build Verification ---"
check "cortina cargo test passes" \
  "cd $ROOT/cortina && cargo test --quiet 2>&1"
check "cortina cargo clippy clean" \
  "cd $ROOT/cortina && cargo clippy --all-targets --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
