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

check "rewrite registry exists" \
  test -f "$ROOT/mycelium/src/discover/registry.rs"

check "find to fd rewrite seam exists" \
  rg -q 'rewrite_find_to_fd|find_fd_rewrite_active|fd ' \
    "$ROOT/mycelium/src/discover/registry.rs" "$ROOT/mycelium/src/rewrite_cmd.rs"

check "rewrite explain mentions find to fd" \
  rg -q 'find command to `fd`|rewrote safe find command to `fd`' \
    "$ROOT/mycelium/src/rewrite_cmd.rs"

check "workspace tests pass" \
  /bin/zsh -lc "cd '$ROOT/mycelium' && cargo test --workspace --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
