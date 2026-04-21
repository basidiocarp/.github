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

check "pre tool use handler exists" \
  test -f "$ROOT/cortina/src/hooks/pre_tool_use.rs"

check "read advisory seam exists" \
  rg -q 'Read|read_advisory|get_symbols|get_structure|Large code file' \
    "$ROOT/cortina/src/hooks/pre_tool_use.rs"

check "grep advisory seam exists" \
  rg -q 'Grep|grep_advisory|search_symbols|find_references|Symbol search' \
    "$ROOT/cortina/src/hooks/pre_tool_use.rs"

check "pre tool use tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test pre_tool_use --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
