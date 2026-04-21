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

check "backup module exists" \
  test -f "$ROOT/stipe/src/backup.rs"

check "lockfile module exists" \
  test -f "$ROOT/stipe/src/lockfile.rs"

check "rollback command exists" \
  rg -q 'RollbackArgs|fn run.*RollbackArgs' "$ROOT/stipe/src"

check "backup wired into install or update" \
  rg -q 'create_backup|backup::create' "$ROOT/stipe/src"

check "lockfile wired into install or update" \
  rg -q 'acquire_lock|lockfile::acquire' "$ROOT/stipe/src"

check "stipe tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
