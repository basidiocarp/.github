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

check "Volva source references execution-session instance records or restore state" \
  rg -q 'session instance|resumable|cleanup_pending|restore|paused|workspace_id|worktree' \
    "$ROOT/volva/src" "$ROOT/volva/tests" "$ROOT/volva/docs"

check "Volva session-focused tests pass" \
  /bin/zsh -lc "cd '$ROOT/volva' && cargo test session >/dev/null"

check "Volva full tests pass" \
  /bin/zsh -lc "cd '$ROOT/volva' && cargo test >/dev/null"

check "Volva clippy passes" \
  /bin/zsh -lc "cd '$ROOT/volva' && cargo clippy -- -D warnings >/dev/null"

echo
echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"

if [[ "$FAIL_COUNT" -ne 0 ]]; then
  exit 1
fi
