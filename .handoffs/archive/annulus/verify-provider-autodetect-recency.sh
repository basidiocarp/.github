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

check "TokenProvider has last_session_at" \
  rg -q 'fn last_session_at' "$ROOT/annulus/src/providers/mod.rs"

check "ClaudeProvider implements last_session_at" \
  rg -q 'fn last_session_at' "$ROOT/annulus/src/providers/claude.rs"

check "detect_provider does recency comparison" \
  rg -q 'last_session_at' "$ROOT/annulus/src/providers/mod.rs"

check "annulus tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test --quiet >/dev/null"

check "annulus clippy clean" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo clippy --all-targets --quiet -- -D warnings >/dev/null 2>&1"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
