#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    ((PASS++))
  else
    echo "FAIL: $label"
    ((FAIL++))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/annulus" 2>/dev/null || {
  echo "FAIL: could not find annulus repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "bridge module exists" grep -rq "bridge" src/
check "bridge reader" grep -rq "read.*bridge\|bridge.*read\|BridgeState\|bridge_state" src/
check "staleness check" grep -rq "stale\|mtime\|ttl\|TTL" src/
check "bridge documented" grep -q "bridge" README.md 2>/dev/null || grep -rq "bridge" docs/ 2>/dev/null

echo ""
echo "Results: $PASS passed, $FAIL failed"
