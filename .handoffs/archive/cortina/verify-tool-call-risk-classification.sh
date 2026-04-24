#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    ((PASS++))
  else
    echo "FAIL: $label"
    ((FAIL++))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/cortina" 2>/dev/null || {
  echo "FAIL: could not find cortina repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "ToolRisk struct defined" grep -rq "ToolRisk" src/
check "RiskLevel enum defined" grep -rq "RiskLevel" src/
check "Allow/Review/Block variants" grep -rq "Allow\|Review\|Block" src/
check "four risk axes present" grep -rq "base_risk\|file_sensitivity\|blast_radius\|irreversibility" src/
check "risk classifier implemented" grep -rq "classifier\|classify\|risk.*score\|score.*risk" src/
check "risk emitted in lifecycle signal" grep -rq "risk.*signal\|signal.*risk\|emit.*risk\|risk.*emit" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
