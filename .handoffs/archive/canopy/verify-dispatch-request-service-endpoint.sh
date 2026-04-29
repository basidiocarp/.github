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

check "canopy references dispatch request contract" \
  /bin/zsh -lc "rg -q 'dispatch-request-v1|DispatchRequest|dispatch_request' '$ROOT/canopy/src' '$ROOT/canopy/tests'"

check "canopy validates schema version" \
  /bin/zsh -lc "rg -q 'schema_version' '$ROOT/canopy/src' '$ROOT/canopy/tests'"

check "canopy exposes workflow dispatch capability or endpoint" \
  /bin/zsh -lc "rg -q 'workflow.dispatch.v1|dispatch endpoint|dispatch_endpoint|dispatch service|dispatch_service' '$ROOT/canopy/src' '$ROOT/canopy/tests' '$ROOT/canopy/README.md'"

check "handoff documents CLI as operator surface" \
  /bin/zsh -lc "rg -q 'human/operator|operator surface|service endpoint as orchestration|CLI.*operator' '$ROOT/.handoffs/canopy/dispatch-request-service-endpoint.md' '$ROOT/canopy/README.md'"

check "canopy dispatch tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test dispatch >/dev/null"

check "canopy task tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test task >/dev/null"

check "canopy clippy passes" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo clippy -- -D warnings >/dev/null"

check "canopy fmt passes" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo fmt --check >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
