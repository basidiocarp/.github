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

check "validation code exists" \
  rg -q 'schema_version|json schema|validation error|version mismatch' "$ROOT/hyphae/crates"

check "import validation tests exist" \
  rg -q 'import_validation|schema_version|version mismatch' "$ROOT/hyphae/crates"

check "cargo import validation tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test import_validation --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
