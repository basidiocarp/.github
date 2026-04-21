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

check "Rhizome docs mention backend selection or boundaries" \
  rg -q 'backend|tree-sitter|lsp|core|mcp|cli' "$ROOT/rhizome/README.md" "$ROOT/rhizome/CLAUDE.md" "$ROOT/rhizome/docs"

check "Rhizome docs mention export or graph boundaries" \
  rg -q 'export|graph|core' "$ROOT/rhizome/README.md" "$ROOT/rhizome/CLAUDE.md" "$ROOT/rhizome/docs"

check "Rhizome has separate tests or test modules" \
  bash -lc "find '$ROOT/rhizome' -path '*/tests/*' | grep -q . || rg -q '#\\[cfg\\(test\\)\\]|mod tests' '$ROOT/rhizome/crates'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
