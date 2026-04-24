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

check "cortina status surface exists" \
  test -f "$ROOT/cortina/src/status.rs"

check "session-end path is referenced in cortina" \
  rg -q 'SessionEnd|Stop|session end|session_end' "$ROOT/cortina/src"

check "cortina workspace tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test --workspace --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
