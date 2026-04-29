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

check "hymenium references dispatch request contract" \
  /bin/zsh -lc "rg -q 'dispatch-request-v1|DispatchRequest|dispatch_request' '$ROOT/hymenium/src' '$ROOT/hymenium/tests'"

check "hymenium resolves workflow dispatch capability" \
  /bin/zsh -lc "rg -q 'workflow.dispatch.v1|resolve_capability|CapabilityResolver' '$ROOT/hymenium/src' '$ROOT/hymenium/tests'"

check "CLI fallback is explicit" \
  /bin/zsh -lc "rg -q 'fallback|compatibility|CliCanopyClient' '$ROOT/hymenium/src/dispatch' '$ROOT/hymenium/tests'"

check "handoff documents CLI fallback as compatibility-only" \
  /bin/zsh -lc "rg -q 'compatibility adapter|compatibility fallback|fallback only|typed endpoint.*preferred' '$ROOT/.handoffs/hymenium/capability-dispatch-client.md' '$ROOT/hymenium/README.md'"

check "hymenium dispatch tests pass" \
  /bin/zsh -lc "cd '$ROOT/hymenium' && cargo test dispatch >/dev/null"

check "hymenium workflow tests pass" \
  /bin/zsh -lc "cd '$ROOT/hymenium' && cargo test workflow >/dev/null"

check "hymenium clippy passes" \
  /bin/zsh -lc "cd '$ROOT/hymenium' && cargo clippy -- -D warnings >/dev/null"

check "hymenium fmt passes" \
  /bin/zsh -lc "cd '$ROOT/hymenium' && cargo fmt --check >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
