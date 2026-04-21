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
check "cargo clippy" cargo clippy -- -D warnings
check "council_sessions table" grep -rq "council_sessions" src/
check "session lifecycle states" grep -rq "deliberating\|Deliberating" src/
check "decided state present" grep -rq "decided\|Decided" src/
check "closed state present" grep -rq "closed\|Closed" src/
check "participant roster" grep -rq "join.*session\|join_session\|participants" src/
check "close session logic" grep -rq "close.*session\|close_session\|CloseSession" src/
check "task snapshot integration" grep -rq "council" src/api.rs

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
