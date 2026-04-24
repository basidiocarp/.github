#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    # Use PASS=$((PASS + 1)) to avoid bash set -e + ((expr==0)) exit trap.
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
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
check "UsageRow struct defined" grep -rq "UsageRow" src/
check "UsageScanner trait defined" grep -rq "UsageScanner" src/
check "scan method present" grep -rq "fn scan" src/
check "runtime_id field present" grep -rq "runtime_id" src/
check "prompt_tokens and completion_tokens fields" grep -rq "prompt_tokens\|completion_tokens" src/
check "cost_usd field present" grep -rq "cost_usd" src/
check "Claude scanner implemented" grep -rq "claude.*scan\|scan.*claude\|ClaudeScanner\|impl.*UsageScanner.*Claude\|impl UsageScanner" src/
check "storage layer present" grep -rq "storage\|append\|sqlite\|store.*row\|row.*store" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
