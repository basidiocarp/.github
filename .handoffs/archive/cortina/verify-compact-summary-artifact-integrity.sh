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

check "Cortina compact/Hyphae client tests run" \
  bash -lc "cd '$ROOT/cortina' && cargo test pre_compact && cargo test hyphae_client"
check "Hyphae artifact tests run" \
  bash -lc "cd '$ROOT/hyphae' && cargo test -p hyphae-mcp artifact"
check "compact summary uses artifact identity" \
  bash -lc "rg -n 'artifact|compact_summary|source_id|session_id' '$ROOT/cortina/src/hooks/pre_compact.rs' '$ROOT/cortina/src/utils/hyphae_client.rs'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
