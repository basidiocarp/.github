#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)"

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

check "canopy uses required capabilities" \
  rg -q "required_capabilities|capabilities_match" "$ROOT/canopy/src"

check "hymenium dispatch uses capabilities" \
  rg -q "required_capabilities|capability" "$ROOT/hymenium/src/dispatch" "$ROOT/hymenium/src"

check "canopy tests pass" \
  sh -c "cd '$ROOT/canopy' && cargo test >/dev/null 2>&1"

check "hymenium tests pass" \
  sh -c "cd '$ROOT/hymenium' && cargo test >/dev/null 2>&1"

echo ""
echo "Results: $PASS passed, $FAIL failed"
test "$FAIL" -eq 0
