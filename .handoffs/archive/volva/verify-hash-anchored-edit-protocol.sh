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

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/volva" 2>/dev/null || {
  echo "FAIL: could not find volva repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "TaggedLine type exists" grep -rq "TaggedLine" src/
check "hash function exists" grep -rq "hash\|xxhash\|xxHash" src/
check "staleness check exists" grep -rq "StalenessError\|staleness\|stale" src/
check "chunked read exists" grep -rq "chunk\|Chunk" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
