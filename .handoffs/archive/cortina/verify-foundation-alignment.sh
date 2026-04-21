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

check "Cortina docs mention adapters and lifecycle" \
  rg -q 'adapter|lifecycle|hook' "$ROOT/cortina/README.md" "$ROOT/cortina/CLAUDE.md" "$ROOT/cortina/docs"

check "Cortina docs mention fail-open or best-effort behavior" \
  rg -q 'fail-open|best-effort|degradation|blocking' "$ROOT/cortina/README.md" "$ROOT/cortina/CLAUDE.md" "$ROOT/cortina/docs" "$ROOT/cortina/src/policy.rs"

check "Cortina has separate tests or test modules" \
  bash -lc "test -d '$ROOT/cortina/tests' || rg -q '#\\[cfg\\(test\\)\\]|mod tests' '$ROOT/cortina/src'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
