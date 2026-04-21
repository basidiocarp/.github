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

check "volva uses spore otel feature" \
  rg -q 'spore.+otel|features *=.*otel' "$ROOT/volva/Cargo.toml"

check "volva tracing instrumentation exists" \
  rg -q 'trace context|root_span|tracing' "$ROOT/volva/crates"

check "volva tests pass" \
  /bin/zsh -lc "cd '$ROOT/volva' && cargo test >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
