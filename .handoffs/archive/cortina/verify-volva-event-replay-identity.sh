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

check "Cortina Volva adapter tests run" \
  bash -lc "cd '$ROOT/cortina' && cargo test volva"
check "Volva hook identity tests run" \
  bash -lc "cd '$ROOT/volva' && cargo test -p volva-runtime hooks"
check "Cortina preserves session/event identity fields" \
  bash -lc "rg -n 'execution_session|session_id|event_id|sequence|dedupe|duplicate' '$ROOT/cortina/src/adapters/volva.rs' '$ROOT/cortina/src/events'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
