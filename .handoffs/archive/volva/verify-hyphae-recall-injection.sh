#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
CONTEXT_RS="$ROOT/volva/crates/volva-runtime/src/context.rs"

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

check "context.rs references hyphae session context subcommand" \
  grep -q 'load_session_recall\|hyphae-session-recall\|SESSION_RECALL' "$CONTEXT_RS"

check "volva-runtime tests pass" \
  /bin/zsh -lc "cd '$ROOT/volva' && cargo test -p volva-runtime --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
