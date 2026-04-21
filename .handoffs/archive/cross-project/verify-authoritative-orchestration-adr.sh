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

check "research note names orchestration authority" \
  rg -q "single orchestration authority" "$ROOT/docs/research/orchestration" "$ROOT/hymenium/docs" "$ROOT/canopy/docs"

check "ledger language documented" \
  rg -q "coordination ledger|operator surface" "$ROOT/docs/research/orchestration" "$ROOT/hymenium/docs" "$ROOT/canopy/docs"

check "clean runtime role names documented" \
  rg -q "Spec Author|Workflow Planner|Packet Compiler|Output Verifier" "$ROOT/docs/research/orchestration" "$ROOT/.handoffs/campaigns/orchestration-reset" "$ROOT/.handoffs/cross-project/orchestration-reset.md"

echo ""
echo "Results: $PASS passed, $FAIL failed"
test "$FAIL" -eq 0
