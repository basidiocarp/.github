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

check "Canopy store schema mentions queue/worktree/review orchestration" \
  rg -q 'queue|worktree|workspace|review' "$ROOT/canopy/src/store/schema.rs"

check "Canopy store task or helper code mentions execution-session or review linkage" \
  rg -q 'session|review|worktree|workspace' "$ROOT/canopy/src/store/tasks.rs" "$ROOT/canopy/src/store/helpers/review.rs"

check "Canopy queue or identity tools mention richer orchestration state" \
  rg -q 'queue|worktree|workspace|review|session' "$ROOT/canopy/src/tools/queue.rs" "$ROOT/canopy/src/tools/identity.rs"

check "Canopy API views or operator actions mention orchestration records" \
  rg -q 'queue|worktree|workspace|review|session' "$ROOT/canopy/src/api/views.rs" "$ROOT/canopy/src/api/operator_actions.rs"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
