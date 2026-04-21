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

check "Lamella docs mention packaging or authoring ownership" \
  rg -q 'packag|authoring|manifest|source of truth' "$ROOT/lamella/README.md" "$ROOT/lamella/CLAUDE.md" "$ROOT/lamella/AGENTS.md" "$ROOT/lamella/docs"

check "Lamella docs mention runtime or install boundary" \
  rg -q 'install|runtime|host mutation|stipe' "$ROOT/lamella/README.md" "$ROOT/lamella/CLAUDE.md" "$ROOT/lamella/AGENTS.md" "$ROOT/lamella/docs"

check "Lamella has validation or test surface" \
  bash -lc "test -d '$ROOT/lamella/tests' || rg -q 'validate|test' '$ROOT/lamella'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
