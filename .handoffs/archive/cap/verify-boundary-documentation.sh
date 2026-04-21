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

check_not() {
  local name="$1"
  shift
  if "$@"; then
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  else
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  fi
}

ROOT="/Users/williamnewton/projects/basidiocarp"
cd "$ROOT/cap"

check "CLAUDE.md describes write-through boundaries" \
  rg -q "write-through actions|boundary broker|read-heavy" CLAUDE.md
check_not "CLAUDE.md no longer claims the backend is fully read-only" \
  rg -q "backend is read-only by default|Cap is effectively read-only from the ecosystem's perspective" CLAUDE.md
check "README.md describes the boundary accurately" \
  rg -q "write-through actions|boundary broker|read-heavy" README.md
check_not "README.md no longer calls the backend read-only overall" \
  rg -q "Read-only backend|read-only backend" README.md
check "API reference covers the missing route groups" \
  rg -q "Canopy|Rhizome|Settings|Telemetry|Usage|LSP" docs/API.md
check "API reference includes Hyphae write endpoints" \
  rg -q "POST /hyphae/store|DELETE /hyphae/memories/:id|PUT /hyphae/memories/:id/importance|POST /hyphae/memories/:id/invalidate|POST /hyphae/consolidate" docs/API.md
check "Internal notes include the canopy namespace and current route count" \
  rg -q "app.route\\('/api/canopy'|9 API namespaces|9 namespaces" docs/INTERNALS.md

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
