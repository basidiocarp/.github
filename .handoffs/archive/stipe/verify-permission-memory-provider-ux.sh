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
check "provider command registered" grep -rq "Provider\|provider" src/main.rs
check "provider list subcommand" grep -rq "list\|List" src/commands/provider.rs
check "provider setup subcommand" grep -rq "setup\|Setup" src/commands/provider.rs
check "no key value in output" bash -c "! grep -rq 'println!.*key.*value\|format!.*api_key\b.*[^_]' src/commands/provider.rs"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
