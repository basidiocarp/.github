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

check "archive schema exists" \
  test -f "$ROOT/septa/hyphae-archive-v1.schema.json"

check "archive fixture exists" \
  test -f "$ROOT/septa/fixtures/hyphae-archive-v1-example.json"

check "contract pin exists" \
  rg -q 'hyphae-archive\s*=\s*"1\.0"' "$ROOT/ecosystem-versions.toml"

check "septa README mentions archive contract" \
  rg -q 'hyphae-archive' "$ROOT/septa/README.md"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
