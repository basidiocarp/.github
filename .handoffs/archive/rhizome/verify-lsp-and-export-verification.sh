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

check "Rhizome LSP tests run by default" \
  bash -lc "cd '$ROOT/rhizome' && cargo test -p rhizome-lsp"
check "Rhizome export tests run by default" \
  bash -lc "cd '$ROOT/rhizome' && cargo test -p rhizome-mcp export"
check "live ignored tests are documented" \
  bash -lc "rg -n 'live_lsp|--ignored|test_export_to_hyphae_e2e' '$ROOT/rhizome/AGENTS.md' '$ROOT/rhizome/README.md'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
