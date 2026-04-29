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

check "hyphae fallback avoids direct eprintln" \
  /bin/zsh -lc "! rg -q 'eprintln!' '$ROOT/mycelium/src/hyphae.rs'"

check "diagnostics use tracing or verbosity" \
  rg -q 'tracing::|debug!|warn!|verbose' "$ROOT/mycelium/src/hyphae.rs" "$ROOT/mycelium/src"

check "hyphae tests pass" \
  /bin/zsh -lc "cd '$ROOT/mycelium' && cargo test hyphae >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
