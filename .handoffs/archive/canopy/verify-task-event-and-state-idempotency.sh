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

check "task status idempotency tests run" \
  bash -lc "cd '$ROOT/canopy' && cargo test task notification"
check "evidence event ledger tests run" \
  bash -lc "cd '$ROOT/canopy' && cargo test evidence task_events store_roundtrip"
check "duplicate scope tests run" \
  bash -lc "cd '$ROOT/canopy' && cargo test duplicate"
check "workflow ledger triage tests run" \
  bash -lc "cd '$ROOT/canopy' && cargo test workflow_ledger_alignment"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
