#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/lamella" 2>/dev/null || {
  echo "FAIL: could not find lamella repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "evals directory exists" test -d evals
check "three-arm structure defined" grep -rq "baseline\|terse.*control\|control.*arm" evals/
check "delta calculation" grep -rq "delta\|skill.*control\|control.*skill" evals/
check "snapshot support" test -d evals/snapshots -o -f evals/README.md

echo ""
echo "Results: $PASS passed, $FAIL failed"
