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

check "foundation communication standard exists" \
  test -f "$ROOT/docs/foundations/inter-app-communication.md"

check "endpoint descriptor contract exists" \
  /bin/zsh -lc "ls '$ROOT'/septa/*endpoint*.schema.json >/dev/null 2>&1"

check "endpoint fixtures exist" \
  /bin/zsh -lc "ls '$ROOT'/septa/fixtures/*endpoint*.json >/dev/null 2>&1"

check "integration docs mention CLI exceptions or compatibility debt" \
  /bin/zsh -lc "rg -q 'CLI.*exception|compatibility debt|operator surface|system-to-system' '$ROOT/septa/integration-patterns.md' '$ROOT/docs/foundations/inter-app-communication.md'"

check "capability and endpoint docs mention transport kinds" \
  /bin/zsh -lc "rg -q 'unix-socket|loopback|named pipe|transport' '$ROOT/septa' '$ROOT/docs/foundations/inter-app-communication.md'"

check "canonical Septa validation passes" \
  /bin/zsh -lc "cd '$ROOT/septa' && bash validate-all.sh"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0

