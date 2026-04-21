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

check "Septa schema exists for workflow participant runtime identity" \
  test -f "$ROOT/septa/workflow-participant-runtime-identity-v1.schema.json"

check "Septa fixture exists for workflow participant runtime identity" \
  test -f "$ROOT/septa/fixtures/workflow-participant-runtime-identity-v1.example.json"

check "Septa docs mention the new identity contract" \
  rg -q 'workflow-participant-runtime-identity-v1|workflow participant runtime identity' "$ROOT/septa/README.md" "$ROOT/septa/integration-patterns.md"

check "Volva or Canopy or Cortina mentions the new identity contract" \
  rg -q 'workflow-participant-runtime-identity|runtime identity|participant identity' "$ROOT/volva" "$ROOT/canopy" "$ROOT/cortina"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
