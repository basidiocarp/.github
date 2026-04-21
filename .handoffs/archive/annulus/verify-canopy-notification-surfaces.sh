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

check "notify command exists" \
  rg -q 'notify --poll|notify --system|unread' "$ROOT/annulus/src"

check "canopy statusline segment exists" \
  rg -q 'canopy.*unread|unread.*canopy' "$ROOT/annulus/src"

check "cargo notify tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test notify --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
