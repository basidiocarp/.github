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

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/canopy" 2>/dev/null || {
  echo "FAIL: could not find canopy repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "workflow linkage present" rg -q "workflow_id|phase_id|workflow_context" src/
check "dependency linkage present" rg -q "dependency|blocked_by|Relationship" src/
check "handoff context present" rg -q "handoff.*context|next_steps|stop_reason" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
