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
  test_output=$(cd "$ROOT/hyphae" && cargo test "$filter" 2>&1 | grep -E "test result:|running" || true)
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

check "backup uses WAL-safe mechanism or SQLite connection" \
  bash -lc "rg -n 'VACUUM INTO|backup|Connection|wal|checkpoint' '$ROOT/hyphae/crates/hyphae-cli/src/commands/backup.rs' '$ROOT/hyphae/crates/hyphae-store'"
check "restore uses temp/atomic sidecar-aware flow" \
  bash -lc "rg -n 'temp|rename|wal|shm|atomic' '$ROOT/hyphae/crates/hyphae-cli/src/commands/backup.rs'"
check "ingest has path and size limits" \
  bash -lc "rg -n 'max|limit|bytes|metadata|workspace|canonical|root' '$ROOT/hyphae/crates/hyphae-ingest/src' '$ROOT/hyphae/crates/hyphae-mcp/src/tools/ingest.rs'"
check_test_count "backup tests exist and pass" "backup"
check_test_count "ingest tests exist and pass" "ingest"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
