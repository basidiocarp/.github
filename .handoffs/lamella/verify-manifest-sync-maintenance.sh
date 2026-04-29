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

check "Lamella manifest validator passes" \
  bash -lc "cd '$ROOT/lamella' && node scripts/ci/validate-manifests.js"
check "Lamella full validation passes" \
  bash -lc "cd '$ROOT/lamella' && make validate"
check "maintenance docs avoid obsolete manifest paths" \
  bash -lc "! rg -n 'scripts/skills|scripts/plugin-manifests' '$ROOT/lamella/scripts/maintenance/README.md' '$ROOT/lamella/scripts/maintenance/sync-manifests-with-folders.py'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
