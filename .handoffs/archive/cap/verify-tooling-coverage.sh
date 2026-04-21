#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

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

ROOT="/Users/williamnewton/projects/basidiocarp"

check "Biome no longer excludes config files" \
  bash -lc "! rg -q '!\\*\\*/\\*\\.config\\.ts' '$ROOT/cap/biome.json'"
check "Node TS config includes vitest.frontend.config.ts" \
  rg -q "vitest\\.frontend\\.config\\.ts" "$ROOT/cap/tsconfig.node.json"
check "Package scripts expose a non-mutating lint check" \
  rg -q "\"lint:check\"" "$ROOT/cap/package.json"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
