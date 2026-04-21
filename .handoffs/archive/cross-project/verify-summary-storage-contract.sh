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

check "summary contract or note exists" \
  /bin/zsh -lc "test -f '$ROOT/septa/mycelium-summary-v1.schema.json' || rg -q 'mycelium-summary|summary storage' '$ROOT/septa' '$ROOT/ecosystem-versions.toml'"

check "workspace mentions summary storage contract" \
  rg -q 'mycelium-summary|summary storage|command output' "$ROOT/septa" "$ROOT/ecosystem-versions.toml"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
