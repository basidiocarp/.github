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

check "session fixture validates" \
  bash -lc "cd '$ROOT/septa' && check-jsonschema --schemafile session-event-v1.schema.json fixtures/session-event-v1.example.json"
check "usage fixture validates" \
  bash -lc "cd '$ROOT/septa' && check-jsonschema --schemafile usage-event-v1.schema.json fixtures/usage-event-v1.example.json"
check "Cortina session scope code has schema/type decision points" \
  rg -n "SessionState|schema_version|session-event|session_id" "$ROOT/cortina/src/utils/session_scope.rs"
check "Cortina usage emission code has contract decision points" \
  rg -n "usage-event|tool-usage-event|schema_version|tools_called" "$ROOT/cortina/src/hooks/stop/tool_usage_emit.rs"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
