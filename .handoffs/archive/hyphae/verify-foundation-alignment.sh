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

check "Workspace foundation docs live under docs/foundations" \
  bash -lc "test -f '$ROOT/docs/foundations/rust-workspace-architecture-standards.md' && test -f '$ROOT/docs/foundations/rust-workspace-standards-applied.md'"

check "Hyphae docs mention core/store/mcp boundaries" \
  rg -q 'core|store|ingest|mcp|cli' "$ROOT/hyphae/README.md" "$ROOT/hyphae/CLAUDE.md" "$ROOT/hyphae/docs"

check "Hyphae docs mention contracts or versioning" \
  rg -q 'contract|schema|version' "$ROOT/hyphae/README.md" "$ROOT/hyphae/CLAUDE.md" "$ROOT/hyphae/docs"

check "Hyphae has separate tests or test modules" \
  bash -lc "find '$ROOT/hyphae' -path '*/tests/*' | grep -q . || rg -q '#\\[cfg\\(test\\)\\]|mod tests' '$ROOT/hyphae/crates'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
