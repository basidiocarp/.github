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

check "Stipe mentions approval memory or remembered approvals" \
  rg -q 'approval memory|remembered approval|remembered approvals' "$ROOT/stipe"

check "Stipe mentions runtime policy or policy scope" \
  rg -q 'runtime policy|policy scope|policy_rule|policy rule' "$ROOT/stipe"

check "Doctor or install surfaces mention policy state" \
  rg -q 'policy|approval|allow|deny' "$ROOT/stipe/src/commands/doctor" "$ROOT/stipe/src/commands/install"

check "Stipe docs mention the approval-memory boundary" \
  rg -q 'approval memory|runtime policy|remembered approval' "$ROOT/stipe/README.md" "$ROOT/stipe/docs" 2>/dev/null

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
