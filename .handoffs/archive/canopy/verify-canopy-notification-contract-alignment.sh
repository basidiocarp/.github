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

check "notification schema exists" \
  test -f "$ROOT/septa/canopy-notification-v1.schema.json"
check "notification fixture validates" \
  bash -lc "cd '$ROOT/septa' && check-jsonschema --schemafile canopy-notification-v1.schema.json fixtures/canopy-notification-v1.example.json"
check "Canopy notification model references schema-relevant fields" \
  rg -n "notification_id|event_type|seen|read_at|created_at" "$ROOT/canopy/src"
check "notification contract has repo-local tests or model coverage" \
  bash -lc "rg -n 'notification' '$ROOT/canopy/tests' '$ROOT/canopy/src' >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
