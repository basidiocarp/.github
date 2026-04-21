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

check "status report file exists" \
  test -f "$ROOT/cortina/src/status.rs"

check "status advisory counters seam exists" \
  rg -q 'advis|rhizome_suggest|read.*advis|grep.*advis' \
    "$ROOT/cortina/src/status.rs" "$ROOT/cortina/src/hooks/pre_tool_use.rs"

check "status tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test status --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
