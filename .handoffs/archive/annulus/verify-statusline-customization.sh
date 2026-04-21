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

check "config module exists" \
  test -f "$ROOT/annulus/src/config.rs"

check "config loads toml with defaults" \
  rg -q 'StatuslineConfig|load_config' "$ROOT/annulus/src/config.rs"

check "toml dependency in Cargo.toml" \
  rg -q '^toml' "$ROOT/annulus/Cargo.toml"

check "segment trait defined" \
  rg -q 'trait Segment|fn render' "$ROOT/annulus/src/statusline.rs"

check "context-bar segment exists" \
  rg -q 'context.bar|ContextBar' "$ROOT/annulus/src/statusline.rs"

check "tiered pricing fields exist" \
  rg -q 'above_threshold|tiered|cache_read_above' "$ROOT/annulus/src/statusline.rs"

check "cargo build succeeds" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo build --quiet 2>/dev/null"

check "cargo tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test --quiet 2>/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
