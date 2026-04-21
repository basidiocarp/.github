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

check "evaluate command file exists" \
  test -f "$ROOT/hyphae/crates/hyphae-cli/src/commands/evaluate.rs"

check "evaluate surface references recall effectiveness" \
  rg -q 'recall.*effectiveness|effectiveness.*recall|average learned effectiveness' "$ROOT/hyphae/crates/hyphae-cli/src/commands/evaluate.rs"

check "workspace evaluate tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test --workspace evaluate --quiet >/dev/null"

check "workspace recall effectiveness tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test --workspace recall_effectiveness --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
