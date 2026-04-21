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

check "import command is wired" \
  rg -q 'on_conflict|dry_run|ConflictStrategy' "$ROOT/hyphae/crates"

check "import tests exist" \
  rg -q 'overwrite|dry_run|merge|skip' "$ROOT/hyphae/crates"

check "cargo import tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test import --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
