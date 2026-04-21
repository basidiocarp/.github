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

check "feedback command file exists" \
  test -f "$ROOT/hyphae/crates/hyphae-cli/src/commands/feedback.rs"

check "recompute CLI surface exists" \
  rg -q 'feedback compute|FeedbackCommand::Compute|Compute \{' "$ROOT/hyphae/crates/hyphae-cli/src"

check "existing scoring seam is referenced" \
  rg -q 'score_recall_effectiveness|recall_effectiveness' "$ROOT/hyphae/crates/hyphae-cli/src" "$ROOT/hyphae/crates/hyphae-store/src"

check "workspace feedback tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test --workspace feedback --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
