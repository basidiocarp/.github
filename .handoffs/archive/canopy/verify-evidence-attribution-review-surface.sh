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

check "canopy evidence files exist" \
  test -f "$ROOT/canopy/src/tools/evidence.rs"

check "review surface references evidence attribution" \
  rg -q 'evidence|caused_by|source_ref|source_kind' "$ROOT/canopy/src/app.rs" "$ROOT/canopy/src/app/commands.rs" "$ROOT/canopy/src/tools/evidence.rs"

check "canopy workspace tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test --workspace --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
