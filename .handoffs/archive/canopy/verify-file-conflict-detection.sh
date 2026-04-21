#!/bin/bash
# Verification script for HANDOFF-CANOPY-FILE-CONFLICT-DETECTION.md
# Run: bash .handoffs/canopy/verify-file-conflict-detection.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CANOPY="$ROOT/canopy"

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    ((FAIL++))
  fi
}

echo "=== HANDOFF-CANOPY-FILE-CONFLICT-DETECTION Verification ==="
echo ""

echo "--- Step 1: Scope Field on Tasks ---"
check "scope field in Task struct" \
  "grep -q 'scope' $CANOPY/src/models.rs"
check "scope column in SQLite schema" \
  "grep -q 'scope' $CANOPY/src/store.rs"
check "--scope CLI flag exists" \
  "grep -q 'scope' $CANOPY/src/cli.rs"

echo ""
echo "--- Step 2: Overlap Detection ---"
check "scope_overlaps function exists" \
  "grep -rq 'scope_overlaps\\|paths_overlap' $CANOPY/src/"
check "glob dependency in Cargo.toml" \
  "grep -q 'glob' $CANOPY/Cargo.toml"
check "exact path match handled" \
  "grep -rq 'a == b\\|exact.*match\\|paths_overlap' $CANOPY/src/"

echo ""
echo "--- Step 3: Conflict Check on Claim ---"
check "find_scope_conflicts function exists" \
  "grep -rq 'find_scope_conflicts\\|scope_conflict\\|ScopeConflict' $CANOPY/src/"
check "claim_task checks scope" \
  "grep -rq 'scope.*conflict\\|conflict.*scope' $CANOPY/src/store.rs"

echo ""
echo "--- Step 4: Resolution Strategy Flags ---"
check "--force flag on claim" \
  "grep -q 'force' $CANOPY/src/cli.rs && grep -q 'Claim' $CANOPY/src/cli.rs"
check "--after flag on claim" \
  "grep -q 'after' $CANOPY/src/cli.rs"
check "--worktree flag on claim" \
  "grep -q 'worktree' $CANOPY/src/cli.rs"

echo ""
echo "--- Step 5: Auto-Scope from Handoff ---"
check "extract_step_scope function exists" \
  "grep -rq 'extract_step_scope\\|extract_backtick_path\\|step.*scope' $CANOPY/src/"

echo ""
echo "--- Step 6: Snapshot View ---"
check "FileConflicts preset exists" \
  "grep -rq 'FileConflict' $CANOPY/src/models.rs || grep -rq 'FileConflict' $CANOPY/src/api.rs"

echo ""
echo "--- Build Verification ---"
check "cargo test passes" \
  "cd $CANOPY && cargo test --quiet 2>&1"
check "cargo clippy clean" \
  "cd $CANOPY && cargo clippy --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
