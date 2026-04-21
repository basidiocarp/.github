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

check "canopy bridge file exists" \
  test -f "$ROOT/cortina/src/utils/canopy_client.rs"

check "bridge references evidence payload metadata" \
  rg -q 'evidence|caused_by|signal_type|schema_version' "$ROOT/cortina/src/utils/canopy_client.rs" "$ROOT/cortina/src/outcomes.rs"

check "cortina workspace tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test --workspace --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
