#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
PASS_COUNT=0
FAIL_COUNT=0

check() {
  local description="$1"
  shift
  if "$@"; then
    echo "PASS: $description"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo "FAIL: $description"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

check "Cap source references realtime invalidation or websocket handling" \
  rg -q 'invalidateQueries|setQueryData|WebSocket|realtime|queryClient' \
    "$ROOT/cap/src" "$ROOT/cap/server"

check "Cap build passes" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null"

check "Cap tests pass" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm test >/dev/null"

echo
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ "$FAIL_COUNT" -ne 0 ]]; then
  exit 1
fi
