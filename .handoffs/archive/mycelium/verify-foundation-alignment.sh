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

check "Mycelium docs mention dispatch or module boundaries" \
  rg -q 'dispatch|module|filter|integration' "$ROOT/mycelium/README.md" "$ROOT/mycelium/CLAUDE.md" "$ROOT/mycelium/docs"

check "Mycelium docs mention Hyphae or Rhizome isolation" \
  rg -q 'hyphae|rhizome' "$ROOT/mycelium/README.md" "$ROOT/mycelium/CLAUDE.md" "$ROOT/mycelium/docs"

check "Mycelium has separate tests or test modules" \
  bash -lc "test -d '$ROOT/mycelium/tests' || rg -q '#\\[cfg\\(test\\)\\]|mod tests' '$ROOT/mycelium/src'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
