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
check "ContextEngine trait exists" grep -rq "ContextEngine" src/
check "compress method exists" grep -rq "fn compress" src/
check "CompressionParams exists" grep -rq "CompressionParams" src/
check "focus_topic field exists" grep -rq "focus_topic" src/
check "tool-pair sanitization exists" grep -rq "sanitize\|tool_pair\|orphan" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
