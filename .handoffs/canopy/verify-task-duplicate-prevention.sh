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

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/canopy" 2>/dev/null || {
  echo "FAIL: could not find canopy repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "unique index or constraint" grep -rq "unique\|UNIQUE\|duplicate\|dedup" src/
check "atomic claim" grep -rq "claim\|atomic\|concurrency" src/
check "concurrency cap" grep -rq "concurrency.*cap\|max.*claimed\|claim.*limit" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
