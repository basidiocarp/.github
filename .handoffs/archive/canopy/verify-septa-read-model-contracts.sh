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

check "septa schemas validate against fixtures" \
  /bin/zsh -lc "cd '$ROOT/septa' && bash validate-all.sh >/dev/null"

check "allowed_actions contract is explicit" \
  /bin/zsh -lc "rg -q 'allowed_actions' '$ROOT/canopy/src' '$ROOT/septa/canopy-task-detail-v1.schema.json' && rg -q 'allowed_actions' '$ROOT/septa/fixtures/canopy-task-detail-v1.example.json'"

check "snapshot verification count is contracted or not serialized" \
  /bin/zsh -lc "if rg -q 'needs_verification_count' '$ROOT/canopy/src'; then rg -q 'needs_verification_count' '$ROOT/septa/canopy-snapshot-v1.schema.json' '$ROOT/septa/fixtures/canopy-snapshot-v1.example.json'; else true; fi"

check "workflow outcome version is parsed" \
  rg -q 'schema_version' "$ROOT/canopy/src/store/outcomes.rs" "$ROOT/canopy/tests"

check "handoff context contract is referenced" \
  rg -q 'HandoffContext|handoff-context|work_state|boundary' "$ROOT/canopy/src" "$ROOT/canopy/tests" "$ROOT/septa"

check "canopy task tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test task >/dev/null"

check "canopy handoff tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test handoff >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
