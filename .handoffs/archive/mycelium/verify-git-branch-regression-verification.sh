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

check "branch classification tests run by default" \
  bash -lc "cd '$ROOT/mycelium' && cargo test branch_creation"
check "ignored branch integration tests are documented" \
  bash -lc "rg -n 'branch_creation|--ignored|cargo test --ignored' '$ROOT/mycelium/src/vcs/git/status.rs' '$ROOT/mycelium/AGENTS.md' '$ROOT/mycelium/README.md'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
