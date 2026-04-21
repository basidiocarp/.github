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

check "cortina session start persists memory protocol state" /bin/zsh -lc "cd '$ROOT/cortina' && cargo test ensure_hyphae_session_with_runner_passes_context_signals_to_start -- --exact >/dev/null"
check "cortina session start tolerates protocol lookup failure" /bin/zsh -lc "cd '$ROOT/cortina' && cargo test ensure_hyphae_session_with_runner_leaves_memory_protocol_empty_on_protocol_failure -- --exact >/dev/null"
check "cortina status exposes memory protocol lines" /bin/zsh -lc "cd '$ROOT/cortina' && cargo test render_status_includes_memory_protocol_lines -- --exact >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
