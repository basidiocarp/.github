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

check "handoff_paths module exists" \
  test -f "$ROOT/cortina/src/handoff_paths.rs"

check "handoff path tests exist" \
  rg -q 'extracts_paths|checklist_items|handoff_paths' "$ROOT/cortina/src"

check "cargo handoff_paths tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test handoff_paths --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
