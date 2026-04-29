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

check "stipe references capability registry contract" \
  /bin/zsh -lc "rg -q 'capability-registry-v1|CapabilityRegistry|capability_registry' '$ROOT/stipe/src' '$ROOT/stipe/tests'"

check "tool specs include capability metadata" \
  /bin/zsh -lc "rg -q 'capabilities|contract_ids|contracts' '$ROOT/stipe/src/commands/tool_registry' '$ROOT/stipe/src/ecosystem'"

check "doctor checks capability registry health" \
  /bin/zsh -lc "rg -q 'capability.*registry|registry.*stale|stale.*registry' '$ROOT/stipe/src/commands/doctor' '$ROOT/stipe/tests'"

check "stipe tool registry tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test tool_registry >/dev/null"

check "stipe install tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test install >/dev/null"

check "stipe doctor tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test doctor >/dev/null"

check "stipe clippy passes" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo clippy -- -D warnings >/dev/null"

check "stipe fmt passes" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo fmt --check >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
