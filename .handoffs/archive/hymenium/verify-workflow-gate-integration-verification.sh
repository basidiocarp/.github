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

check "workflow gate integration test runs" \
  bash -lc "cd '$ROOT/hymenium' && cargo test workflow_gate_blocks_audit_without_real_diff_and_verification"
check "workflow gate tests mention diff and verification evidence" \
  bash -lc "rg -n 'diff.*verification|verification.*diff|real.*diff|evidence' '$ROOT/hymenium/src' '$ROOT/hymenium/tests'"
check "gate test is not ignored" \
  bash -lc "! rg -n '#\\[ignore\\].*workflow_gate|workflow_gate.*#\\[ignore\\]' '$ROOT/hymenium/src' '$ROOT/hymenium/tests'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
