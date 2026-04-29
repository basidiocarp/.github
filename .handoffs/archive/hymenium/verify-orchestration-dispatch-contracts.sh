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

check "create args include requested-by" \
  rg -q -- '--requested-by' "$ROOT/hymenium/src/dispatch" "$ROOT/hymenium/tests"

check "create args do not use unsupported required-tier" \
  /bin/zsh -lc "! rg -q -- '--required-tier' '$ROOT/hymenium/src/dispatch' '$ROOT/hymenium/tests'"

check "assign args use canopy flag shape" \
  /bin/zsh -lc "rg -q -- '--task-id' '$ROOT/hymenium/src/dispatch' '$ROOT/hymenium/tests' && rg -q -- '--assigned-to' '$ROOT/hymenium/src/dispatch' '$ROOT/hymenium/tests' && rg -q -- '--assigned-by' '$ROOT/hymenium/src/dispatch' '$ROOT/hymenium/tests'"

check "dispatch starts first phase" \
  rg -q 'start_phase|PhaseStatus::Active|mark_.*active' "$ROOT/hymenium/src/dispatch" "$ROOT/hymenium/src/workflow" "$ROOT/hymenium/tests"

check "dispatch request contract is represented" \
  rg -q 'DispatchRequest|dispatch-request|dispatch_request' "$ROOT/hymenium/src" "$ROOT/hymenium/tests"

check "dispatch tests pass" \
  /bin/zsh -lc "cd '$ROOT/hymenium' && cargo test dispatch >/dev/null"

check "workflow tests pass" \
  /bin/zsh -lc "cd '$ROOT/hymenium' && cargo test workflow >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
