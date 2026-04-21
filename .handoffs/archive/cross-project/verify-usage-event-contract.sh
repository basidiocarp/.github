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

check "Septa schema exists for usage events" \
  test -f "$ROOT/septa/usage-event-v1.schema.json"

check "Septa fixture exists for usage events" \
  test -f "$ROOT/septa/fixtures/usage-event-v1.example.json"

check "Septa docs mention the usage event contract" \
  rg -q 'usage-event-v1|usage event|normalized usage' "$ROOT/septa/README.md" "$ROOT/septa/integration-patterns.md"

check "Cortina or Mycelium mention normalized usage flow" \
  rg -q 'usage event|normalized usage|telemetry summary' "$ROOT/cortina" "$ROOT/mycelium"

check "Cap or Stipe mention usage or telemetry inputs" \
  rg -q 'usage|telemetry|cost' "$ROOT/cap" "$ROOT/stipe"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
