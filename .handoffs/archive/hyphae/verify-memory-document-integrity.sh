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

check "memory store integrity tests run" \
  bash -lc "cd '$ROOT/hyphae' && cargo test -p hyphae-store store_with_embedding"
check "document project identity tests run" \
  bash -lc "cd '$ROOT/hyphae' && cargo test -p hyphae-store document"
check "memory store uses transaction for vector writes" \
  bash -lc "rg -n 'transaction|unchecked_transaction|vec_memories' '$ROOT/hyphae/crates/hyphae-store/src/store/memory_store.rs'"
check "document schema accounts for project-scoped source path" \
  bash -lc "rg -n 'UNIQUE.*project.*source_path|project.*source_path.*UNIQUE|source_identity' '$ROOT/hyphae/crates/hyphae-store/src/schema.rs' '$ROOT/hyphae/crates/hyphae-store/migrations' 2>/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
