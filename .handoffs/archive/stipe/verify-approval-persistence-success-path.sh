#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
HANDOFF="$ROOT/.handoffs/stipe/approval-persistence-success-path.md"

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

check "Handoff names approval persistence scope" \
  rg -q 'approval persistence|successful profile install|runtime policy' "$HANDOFF"

check "Handoff points at install test files" \
  rg -q 'install/tests.rs|install/runner.rs' "$HANDOFF"

check "Handoff includes final verification script" \
  rg -q 'verify-approval-persistence-success-path.sh' "$HANDOFF"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
