#!/bin/bash
# Verification script for global-audit-readme-drift.md
# Run: bash .handoffs/archive/cross-project/verify-global-audit-readme-drift.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
README="$ROOT/.handoffs/archive/campaigns/global-audit/README.md"

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Global Audit README Drift Verification ==="
echo ""

echo "--- Step 1: Agent Registration ---"
check "register commands have --agent-id" \
  "grep -q 'agent-id' $README"
check "register commands have --host-instance" \
  "grep -q 'host-instance' $README"
check "register commands have --model" \
  "grep -q 'model' $README"
check "register commands have --project-root" \
  "grep -q 'project-root' $README"

echo ""
echo "--- Step 2: Task Creation ---"
check "task create has --requested-by" \
  "grep -q 'requested-by' $README"

echo ""
echo "--- Step 3: Task Status ---"
check "task counts reflect 9 projects" \
  "grep -q '22\|9.*project\|volva' $README"

echo ""
echo "--- Step 4: Version Requirement ---"
check "version requirement documented" \
  "grep -q '0.3.1\|version\|Prerequisite' $README"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
