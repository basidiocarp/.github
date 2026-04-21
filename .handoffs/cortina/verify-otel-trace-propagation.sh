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

check "cortina uses spore otel feature" \
  rg -q 'spore.+otel|features *=.*otel' "$ROOT/cortina/Cargo.toml"

check "cortina tracing instrumentation exists" \
  rg -q 'trace context|span|tracing' "$ROOT/cortina/src"

check "cortina tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
