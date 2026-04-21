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

check "canopy uses spore otel feature" \
  rg -q 'spore.+otel|features *=.*otel' "$ROOT/canopy/Cargo.toml"

check "canopy tracing instrumentation exists" \
  rg -q 'trace context|child span|tracing' "$ROOT/canopy/src"

check "canopy tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
