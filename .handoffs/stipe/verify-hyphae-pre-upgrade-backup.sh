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

check "backup command is wired" \
  rg -q 'backup hyphae|pre_upgrade_backup|hyphae-backup' "$ROOT/stipe/src"

check "backup tests exist" \
  rg -q 'backup.*hyphae|pre_upgrade_backup|warning' "$ROOT/stipe/src"

check "cargo backup tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test backup --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
