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

check "Package repair mentions rollback handling" \
  rg -q 'rollback|restore|backup' "$ROOT/stipe/src/commands/package_repair.rs"

check "Package repair has safety-focused tests" \
  rg -q 'test_.*backup|test_.*rollback|test_.*audit' "$ROOT/stipe/src/commands/package_repair.rs"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
