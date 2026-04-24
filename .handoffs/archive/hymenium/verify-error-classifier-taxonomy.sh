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

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/hymenium" 2>/dev/null || {
  echo "FAIL: could not find hymenium repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "FailoverReason enum exists" grep -rq "FailoverReason" src/
check "RecoveryHint struct exists" grep -rq "RecoveryHint" src/
check "classify function exists" grep -rq "classify_error\|classify" src/
check "non_exhaustive annotation" grep -rq "non_exhaustive" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
