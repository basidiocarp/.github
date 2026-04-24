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

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/volva" 2>/dev/null || {
  echo "FAIL: could not find volva repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "ExecEnv module exists" grep -rq "ExecEnv\|execenv\|exec_env" crates/
check "provider injection" grep -rq "inject\|provider.*config\|config.*inject" crates/
check "skill injection" grep -rq "skill.*inject\|inject.*skill" crates/
check "cleanup or teardown" grep -rq "cleanup\|teardown\|drop\|gc_metadata" crates/

echo ""
echo "Results: $PASS passed, $FAIL failed"
