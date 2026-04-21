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

check "mycelium segment uses shared path discovery" \
  rg -q 'spore::paths|history\.db' "$ROOT/annulus/src"

check "hyphae degradation path exists" \
  rg -q 'hyphae.*available|reason.*hyphae|degrade' "$ROOT/annulus/src"

check "cortina segment or stub exists" \
  rg -q 'cortina' "$ROOT/annulus/src"

check "cargo segment tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test segments --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
