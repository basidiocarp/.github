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
  test_output=$(cd "$ROOT/mycelium" && cargo test "$filter" 2>&1 | grep -E "test result:|running" || true)
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

check "read command has input limits" \
  bash -lc "rg -n 'limit|max|bytes|metadata|take|oversized' '$ROOT/mycelium/src/fileops/read_cmd.rs'"
check "diff command has input limits" \
  bash -lc "rg -n 'limit|max|bytes|metadata|take|oversized' '$ROOT/mycelium/src/fileops/diff_cmd.rs'"
check "json command has input limits before parse" \
  bash -lc "rg -n 'limit|max|bytes|metadata|take|oversized' '$ROOT/mycelium/src/json_cmd.rs'"
check_test_count "read command size boundary tests exist and pass" "read_stdin_rejects_oversized_input"
check_test_count "diff command size boundary tests exist and pass" "diff_stdin_rejects_oversized_input"
check_test_count "json command size boundary tests exist and pass" "json_stdin_rejects_oversized_input"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
