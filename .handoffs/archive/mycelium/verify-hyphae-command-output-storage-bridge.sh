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

check "mycelium source mentions hyphae command-output storage" \
  rg -q 'store_command_output|get_command_chunks|hyphae' "$ROOT/mycelium/src"

check "mycelium tests pass" \
  /bin/zsh -lc "cd '$ROOT/mycelium' && cargo test --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
