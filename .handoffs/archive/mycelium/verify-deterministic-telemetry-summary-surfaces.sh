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

check "Mycelium mentions deterministic telemetry summaries" \
  rg -q 'deterministic telemetry|telemetry summary|usage summary|summary surface' "$ROOT/mycelium"

check "Mycelium source mentions a stable summary output" \
  rg -q 'summary|json|resource|export' "$ROOT/mycelium/src"

check "Mycelium tests or docs mention deterministic aggregation" \
  rg -q 'deterministic|aggregation|telemetry summary|usage summary' "$ROOT/mycelium/tests" "$ROOT/mycelium/README.md" "$ROOT/mycelium/docs" 2>/dev/null

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
