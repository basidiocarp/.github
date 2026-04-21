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

check "recharts not imported in src/" \
  bash -c "! rg -q \"from 'recharts'\" '$ROOT/cap/src/'"

check "recharts not in package.json" \
  bash -c "! grep -q '\"recharts\"' '$ROOT/cap/package.json'"

check "@mantine/dates not in package.json" \
  bash -c "! grep -q '\"@mantine/dates\"' '$ROOT/cap/package.json'"

check "@mantine/nprogress not in package.json" \
  bash -c "! grep -q '\"@mantine/nprogress\"' '$ROOT/cap/package.json'"

check "@mantine/modals not in package.json" \
  bash -c "! grep -q '\"@mantine/modals\"' '$ROOT/cap/package.json'"

check "build succeeds" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null 2>&1"

check "no new test failures" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm test 2>&1 | sed 's/\x1B\[[0-9;]*m//g' | grep -E '^[[:space:]]+Tests' | grep -qv 'failed'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
