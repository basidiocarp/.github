#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
DOC_PATHS=("$ROOT/cortina/README.md")
TEST_PATHS=("$ROOT/cortina/src")

if [[ -d "$ROOT/cortina/docs" ]]; then
  DOC_PATHS+=("$ROOT/cortina/docs")
fi

if [[ -d "$ROOT/cortina/tests" ]]; then
  TEST_PATHS+=("$ROOT/cortina/tests")
fi

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

check "Cortina docs mention usage-event-v1 producer boundary" \
  rg -q 'usage-event-v1|normalized usage|producer' "${DOC_PATHS[@]}"

check "Septa usage-event fixture exists" \
  test -f "$ROOT/septa/fixtures/usage-event-v1.example.json"

check "Cortina has a usage-event regression test" \
  rg -q 'usage_event|usage-event-v1|usage event' "${TEST_PATHS[@]}"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
