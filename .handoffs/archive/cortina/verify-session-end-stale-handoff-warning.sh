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

check "stale handoff warning logic exists" \
  rg -q 'StaleHandoffWarning|check_handoff_staleness' "$ROOT/cortina/src"

check "policy flag exists" \
  rg -q 'stale_handoff_detection_enabled' "$ROOT/cortina/src/policy.rs"

check "cargo staleness tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test staleness --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
