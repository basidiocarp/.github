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

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/hymenium" 2>/dev/null || {
  echo "FAIL: could not find hymenium repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "dispatch command implemented" rg -q "Commands::Dispatch" src/main.rs
check "status command implemented" rg -q "Commands::Status" src/main.rs
check "cancel command implemented" rg -q "Commands::Cancel" src/main.rs
check "workflow store used" rg -q "WorkflowStore|workflow store|db_path" src/
check "task packet usage" rg -q "task.?packet|acceptance_criteria|context_budget|required_capabilities" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
