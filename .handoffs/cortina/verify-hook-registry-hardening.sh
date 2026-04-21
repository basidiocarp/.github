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

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/cortina" 2>/dev/null || {
  echo "FAIL: could not find cortina repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "silent-fail enforcement" grep -rq "silent.fail\|catch\|swallow\|error.*hook\|hook.*error" src/
check "named hook identity" grep -rq "hook.*name\|name.*hook\|disabled_hooks" src/
check "guarded init" grep -rq "guard\|safe.*init\|init.*catch\|init.*error" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
