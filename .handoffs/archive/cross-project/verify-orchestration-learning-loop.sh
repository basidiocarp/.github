#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)"

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

check "outcome schema present" \
  test -f "$ROOT/septa/workflow-outcome-v1.schema.json"

check "outcome fixture present" \
  test -f "$ROOT/septa/fixtures/workflow-outcome-v1.example.json"

check "outcome fields implemented" \
  rg -q "failure_type|attempt_count|route_taken|confidence|root_cause_layer" "$ROOT/septa" "$ROOT/hymenium" "$ROOT/canopy"

check "runtime or session route metadata implemented" \
  rg -q "runtime_id|session_id|workspace_id|prior_session|resume" "$ROOT/septa" "$ROOT/hymenium" "$ROOT/canopy"

check "hymenium tests pass" \
  sh -c "cd '$ROOT/hymenium' && cargo test >/dev/null 2>&1"

check "canopy tests pass" \
  sh -c "cd '$ROOT/canopy' && cargo test >/dev/null 2>&1"

echo ""
echo "Results: $PASS passed, $FAIL failed"
test "$FAIL" -eq 0
