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
check "sweeper module exists" grep -rq "sweeper\|sweep" src/
check "SWEEP_INTERVAL constant" grep -rq "SWEEP_INTERVAL\|sweep_interval" src/
check "HEARTBEAT_TIMEOUT constant" grep -rq "HEARTBEAT_TIMEOUT\|heartbeat_timeout" src/
check "orphan failure logic" grep -rq "orphan\|offline" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
