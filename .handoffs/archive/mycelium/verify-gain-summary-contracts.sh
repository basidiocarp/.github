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

check "gain fixture validates" \
  bash -lc "cd '$ROOT/septa' && check-jsonschema --schemafile mycelium-gain-v1.schema.json fixtures/mycelium-gain-v1.example.json"
check "summary fixture validates" \
  bash -lc "cd '$ROOT/septa' && check-jsonschema --schemafile mycelium-summary-v1.schema.json fixtures/mycelium-summary-v1.example.json"
check "gain producer has telemetry/schema decision point" \
  rg -n "telemetry_summary|schema_version|Gain" "$ROOT/mycelium/src/gain"
check "summary producer has contract decision point" \
  rg -n "OutputSummary|schema_version|summary" "$ROOT/mycelium/src/summary_cmd.rs" "$ROOT/mycelium/src/summarizer.rs" "$ROOT/mycelium/src/tracking"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
