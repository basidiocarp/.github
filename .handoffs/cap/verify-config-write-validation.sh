#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

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

ROOT="/Users/williamnewton/projects/basidiocarp"

check "Settings writes validate payload fields" \
  rg -q "isRecord|hyphae_enabled must be a boolean|rhizome_enabled must be a boolean|auto_export must be a boolean|languages must be an array of non-empty strings|embedding_model must be a non-empty string" "$ROOT/cap/server/routes/settings/writes.ts"
check "Settings writes use shared TOML helpers" \
  rg -q "serializeTomlScalar|serializeTomlStringArray|upsertTomlScalar" "$ROOT/cap/server/routes/settings/writes.ts"
check "Focused config-write validation tests exist" \
  rg -q "config-write-validation|rejects invalid payload shapes|writes escaped TOML strings and arrays safely" "$ROOT/cap/server/__tests__/config-write-validation.test.ts"
check "Focused server validation test passes" \
  bash -lc "cd \"$ROOT/cap\" && npm run test:server -- server/__tests__/config-write-validation.test.ts"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
