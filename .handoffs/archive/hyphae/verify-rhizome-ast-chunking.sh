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

check "hyphae source mentions ByAst or rhizome chunking" \
  rg -q 'ByAst|RhizomeChunker|chunking: ast|rhizome' "$ROOT/hyphae"

check "hyphae workspace tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test --workspace --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
