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

check "spore transport module exists" \
  /bin/zsh -lc "test -d '$ROOT/spore/src/transport' || rg -q 'transport' '$ROOT/spore/src'"

check "endpoint descriptor or runtime lease parsing is represented" \
  /bin/zsh -lc "rg -q 'endpoint|runtime.*lease|capability.*candidate' '$ROOT/spore/src' '$ROOT/spore/tests' '$ROOT/spore/README.md'"

check "local service transport is represented" \
  /bin/zsh -lc "rg -q 'unix|socket|loopback|json.?rpc|local service' '$ROOT/spore/src' '$ROOT/spore/tests' '$ROOT/spore/README.md' '$ROOT/spore/docs' 2>/dev/null"

check "timeout or health probe behavior is represented" \
  /bin/zsh -lc "rg -q 'timeout|health|version.*probe|probe.*version' '$ROOT/spore/src' '$ROOT/spore/tests'"

check "spore transport/capability tests pass" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo test transport capability discovery >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0

