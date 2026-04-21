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

check "Septa schema exists for resolved status customization" \
  test -f "$ROOT/septa/resolved-status-customization-v1.schema.json"

check "Septa fixture exists for resolved status customization" \
  test -f "$ROOT/septa/fixtures/resolved-status-customization-v1.example.json"

check "Septa docs mention the new status customization contract" \
  rg -q 'resolved-status-customization-v1|resolved status|status customization' "$ROOT/septa/README.md" "$ROOT/septa/integration-patterns.md"

check "Supporting repos mention the portable status customization boundary" \
  rg -q 'resolved status|status customization|portable status|customization contract' "$ROOT/stipe" "$ROOT/cortina" "$ROOT/lamella" "$ROOT/cap"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
