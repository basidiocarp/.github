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
check "failure taxonomy exists" rg -q "SpecAmbiguity|TaskTooLarge|MissingDependency|ExecutionIncomplete|ScopeViolation|ContractMismatch|MinorDefect" src/
check "retry routes typed failures" rg -q "failure.*type|FailureKind|SpecAmbiguity|ContractMismatch" src/retry.rs src/
check "outcome records exist" rg -q "attempt_count|root_cause_layer|confidence|route_taken" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
