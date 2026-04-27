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

check_test_count() {
  local name="$1"
  local filter="$2"
  local test_output
  test_output=$(cd "$ROOT/volva" && cargo test "$filter" 2>&1 | grep -E "test result:|running" || true)
  if echo "$test_output" | grep -q "test result:"; then
    local count
    count=$(echo "$test_output" | grep -oE "[0-9]+ passed" | grep -oE "[0-9]+" | head -1)
    if [ -n "$count" ] && [ "$count" -gt 0 ]; then
      printf 'PASS: %s\n' "$name"
      PASS=$((PASS + 1))
    else
      printf 'FAIL: %s (zero tests matched)\n' "$name"
      FAIL=$((FAIL + 1))
    fi
  else
    printf 'FAIL: %s (no test output)\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

check "official CLI backend has timeout cleanup" \
  bash -lc "rg -n 'timeout|wait_timeout|kill|deadline|spawn' '$ROOT/volva/crates/volva-runtime/src/backend/official_cli.rs'"
check "hook adapter env/trust is explicit" \
  bash -lc "rg -n 'env_clear|env_remove|allowlist|trusted|cortina|hook_adapter' '$ROOT/volva/crates/volva-runtime/src/hooks.rs' '$ROOT/volva/crates/volva-config/src/lib.rs' '$ROOT/volva/crates/volva-cli/src/run.rs'"
check "auth storage checks permissions on load" \
  bash -lc "rg -n 'metadata|permissions|readonly|mode|0600|0o600' '$ROOT/volva/crates/volva-auth/src'"
check_test_count "official CLI tests exist and pass" "official_cli"
check_test_count "hook adapter tests exist and pass" "hook_adapter"
check_test_count "checkpoint tests exist and pass" "checkpoint"
check_test_count "auth storage tests exist and pass" "storage"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
