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

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/stipe" 2>/dev/null || {
  echo "FAIL: could not find stipe repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "IntegrationPoint type exists" grep -rq "IntegrationPoint" src/
check "CompletenessReport exists" grep -rq "CompletenessReport" src/
check "check_completeness function exists" grep -rq "check_completeness" src/
check "non_exhaustive annotation" grep -rq "non_exhaustive" src/
check "ownership state tracking exists" grep -rq "ownership\|install_state\|managed" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
