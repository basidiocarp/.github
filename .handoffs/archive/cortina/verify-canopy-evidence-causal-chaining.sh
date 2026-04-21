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

check "outcome event file exists" \
  test -f "$ROOT/cortina/src/events/outcome_events.rs"

check "cortina causal attribution seam exists" \
  rg -q 'caused_by|cause|causal' "$ROOT/cortina/src/events/outcome_events.rs" "$ROOT/cortina/src/outcomes.rs" "$ROOT/cortina/src/hooks"

check "cortina workspace tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test --workspace --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
