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

check "spore references capability registry contract" \
  /bin/zsh -lc "rg -q 'capability-registry-v1|CapabilityRegistry|capability_registry' '$ROOT/spore/src' '$ROOT/spore/tests'"

check "spore references runtime lease contract" \
  /bin/zsh -lc "rg -q 'capability-runtime-lease-v1|RuntimeLease|runtime_lease' '$ROOT/spore/src' '$ROOT/spore/tests'"

check "spore exposes capability resolution surface" \
  /bin/zsh -lc "rg -q 'resolve_capability|CapabilityResolver|capability.*resolve' '$ROOT/spore/src' '$ROOT/spore/tests'"

check "spore capability tests pass" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo test capability >/dev/null"

check "spore discovery tests pass" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo test discovery >/dev/null"

check "spore clippy passes" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo clippy -- -D warnings >/dev/null"

check "spore fmt passes" \
  /bin/zsh -lc "cd '$ROOT/spore' && cargo fmt --check >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
