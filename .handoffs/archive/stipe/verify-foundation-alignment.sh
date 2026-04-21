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

check "Stipe docs mention doctor/install/init boundaries" \
  rg -q 'doctor|install|init|repair|registration' "$ROOT/stipe/README.md" "$ROOT/stipe/CLAUDE.md" "$ROOT/stipe/AGENTS.md"

check "Stipe docs mention host policy or primitives" \
  rg -q 'policy|primitive|host' "$ROOT/stipe/README.md" "$ROOT/stipe/CLAUDE.md" "$ROOT/stipe/AGENTS.md"

check "Stipe has separate tests or test modules" \
  bash -lc "test -d '$ROOT/stipe/tests' || rg -q '#\\[cfg\\(test\\)\\]|mod tests' '$ROOT/stipe/src'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
