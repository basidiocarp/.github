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

check "canopy preflight calls cortina audit-handoff" \
  rg -q 'audit-handoff|run_cortina_audit' "$ROOT/canopy/src"

check "canopy stale handoff decision exists" \
  rg -q 'FlagForReview|stale handoff|likely_implemented' "$ROOT/canopy/src"

check "canopy pre-dispatch tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test pre_dispatch --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
