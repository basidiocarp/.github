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

check "annulus Cargo.toml exists" test -f "$ROOT/annulus/Cargo.toml"
check "annulus main exists" test -f "$ROOT/annulus/src/main.rs"
check "annulus builds" /bin/zsh -lc "cd '$ROOT/annulus' && cargo build >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
