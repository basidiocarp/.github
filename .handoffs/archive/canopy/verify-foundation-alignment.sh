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

check "Canopy docs mention coordination and evidence boundaries" \
  rg -q 'coordination|evidence|task|memory' "$ROOT/canopy/README.md" "$ROOT/canopy/CLAUDE.md" "$ROOT/canopy/docs"

check "Canopy has contract or schema references" \
  rg -q 'contract|schema|version' "$ROOT/canopy/README.md" "$ROOT/canopy/CLAUDE.md" "$ROOT/canopy/docs" "$ROOT/canopy/tests"

check "Canopy has separate tests or test modules" \
  bash -lc "test -d '$ROOT/canopy/tests' || rg -q '#\\[cfg\\(test\\)\\]|mod tests' '$ROOT/canopy/src'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
