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

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/hyphae" 2>/dev/null || {
  echo "FAIL: could not find hyphae repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "queue_prefetch hook" grep -rq "queue_prefetch\|prefetch" hyphae-core/src/ src/ 2>/dev/null
check "on_pre_compress hook" grep -rq "on_pre_compress\|pre_compress" hyphae-core/src/ src/ 2>/dev/null
check "on_delegation hook" grep -rq "on_delegation\|delegation" hyphae-core/src/ src/ 2>/dev/null

echo ""
echo "Results: $PASS passed, $FAIL failed"
