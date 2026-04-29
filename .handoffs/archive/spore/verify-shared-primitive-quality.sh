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

check "subprocess cleanup waits after kill" \
  /bin/zsh -lc "rg -n 'kill\\(' '$ROOT/spore/src/subprocess.rs' >/tmp/spore-kills.txt && rg -q 'wait\\(' '$ROOT/spore/src/subprocess.rs'"

check "README does not mention stale v0.4.9" \
  /bin/zsh -lc "! rg -q 'v0\\.4\\.9' '$ROOT/spore/README.md'"

check "README mentions CI green commands" \
  /bin/zsh -lc "rg -q 'cargo fmt --check' '$ROOT/spore/README.md' && rg -q 'cargo clippy' '$ROOT/spore/README.md' && rg -q 'cargo test' '$ROOT/spore/README.md'"

check "spore tests pass" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo test >/dev/null"

check "spore clippy passes" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo clippy -- -D warnings >/dev/null"

check "spore fmt passes" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo fmt --check >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
