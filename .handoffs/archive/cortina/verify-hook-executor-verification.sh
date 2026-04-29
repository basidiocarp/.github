#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

check "hook executor tests run" \
  bash -lc "cd '$ROOT/cortina' && cargo test hooks::executor"
check "executor behavior is documented or tested beyond constructor" \
  bash -lc "rg -n 'timeout|nonzero|exit|stdout|stderr|diagnostic|stub|no-op|execute' '$ROOT/cortina/src/hooks/executor.rs' '$ROOT/cortina/README.md' '$ROOT/cortina/tests'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
