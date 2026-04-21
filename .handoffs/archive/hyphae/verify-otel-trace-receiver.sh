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

check "hyphae uses spore otel feature" \
  rg -q 'spore.+otel|features *=.*otel' "$ROOT/hyphae/Cargo.toml"

check "hyphae tracing instrumentation exists" \
  rg -q 'info_span|tracing::info_span|init_tracer' "$ROOT/hyphae/crates"

check "hyphae tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test --workspace >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
