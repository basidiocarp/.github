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

check "audit handoff command exists" \
  rg -q 'audit-handoff|AuditHandoff' "$ROOT/cortina/src"

check "handoff audit logic exists" \
  test -f "$ROOT/cortina/src/handoff_audit.rs"

check "cargo audit tests pass" \
  /bin/zsh -lc "cd '$ROOT/cortina' && cargo test audit --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
