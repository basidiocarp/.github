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

check "spore telemetry module exists" \
  test -f "$ROOT/spore/src/telemetry.rs"

check "spore otel feature exists" \
  rg -q 'otel' "$ROOT/spore/Cargo.toml"

check "spore otel build passes" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo build --features otel >/dev/null"

check "spore otel tests pass" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo test --features otel >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
