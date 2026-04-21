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

cd "$ROOT/septa" 2>/dev/null || {
  echo "FAIL: could not find septa repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "validate-all" bash validate-all.sh
check "task packet schema exists" test -f task-packet-v1.schema.json
check "workflow outcome schema exists" test -f workflow-outcome-v1.schema.json
check "task packet fixture exists" test -f fixtures/task-packet-v1.example.json
check "workflow outcome fixture exists" test -f fixtures/workflow-outcome-v1.example.json
check "README mentions task packet" rg -q "task-packet-v1" README.md
check "README mentions workflow outcome" rg -q "workflow-outcome-v1" README.md

echo ""
echo "Results: $PASS passed, $FAIL failed"
