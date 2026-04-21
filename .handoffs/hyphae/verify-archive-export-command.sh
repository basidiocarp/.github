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

check "export command is wired" \
  rg -q 'hyphae export|ExportArgs|export.*output' "$ROOT/hyphae/src"

check "export tests exist" \
  rg -q 'include_memoirs|include_sessions|overwrite|topic' "$ROOT/hyphae/src"

check "cargo export tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test export --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
