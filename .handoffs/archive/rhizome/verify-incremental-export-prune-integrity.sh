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

check "Rhizome export tests run" \
  bash -lc "cd '$ROOT/rhizome' && cargo test -p rhizome-mcp export"
check "export code handles prune with incremental/cached files" \
  bash -lc "rg -n 'prune|incremental|cached|partial' '$ROOT/rhizome/crates/rhizome-mcp/src/tools/export_tools.rs' '$ROOT/rhizome/crates/rhizome-mcp/tests'"
check "Hyphae code graph import tests run" \
  bash -lc "cd '$ROOT/hyphae' && cargo test -p hyphae-mcp import_code_graph"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
