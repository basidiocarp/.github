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

check "Package repair mentions profile-aware Lamella invocation" \
  rg -q 'profile|lamella.*install|install.*profile' "$ROOT/stipe/src/commands/package_repair.rs"

check "Package repair keeps backup handling" \
  rg -q 'backup|rollback' "$ROOT/stipe/src/commands/package_repair.rs"

check "Package repair has tests for profile-aware behavior" \
  rg -q 'profile|dry-run|lamella_root_candidates' "$ROOT/stipe/src/commands/package_repair.rs"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
