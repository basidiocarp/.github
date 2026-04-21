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

check "annulus statusline module exists" rg -q 'statusline' "$ROOT/annulus/src"
check "cortina deprecation note exists" rg -q 'DEPRECATED:.*annulus statusline' "$ROOT/cortina/src/statusline.rs"
check "annulus tests pass" /bin/zsh -lc "cd '$ROOT/annulus' && cargo test >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
