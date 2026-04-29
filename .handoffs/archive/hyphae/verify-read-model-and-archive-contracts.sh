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

check "Hyphae archive fixture validates" \
  bash -lc "cd '$ROOT/septa' && check-jsonschema --schemafile hyphae-archive-v1.schema.json fixtures/hyphae-archive-v1.example.json"
check "Hyphae archive producer has filter fields under review" \
  rg -n "until|schema_version|Archive" "$ROOT/hyphae/crates/hyphae-store/src/store/export.rs" "$ROOT/hyphae/crates/hyphae-cli/src/commands/export.rs"
check "Hyphae context/search read producers exist" \
  rg -n "scoped_identity|MemoryPayload|schema_version|Search" "$ROOT/hyphae/crates/hyphae-cli/src/commands"
check "Cap Hyphae read consumers exist" \
  rg -n "MemoryPayload|scoped_identity|memoir|sources" "$ROOT/cap/server/hyphae"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
