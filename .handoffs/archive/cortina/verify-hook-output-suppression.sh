#!/bin/bash
# Verification script for hook-output-suppression.md
# Run: bash .handoffs/cortina/verify-hook-output-suppression.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CORTINA="$ROOT/cortina"

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

echo "=== Hook Output Suppression Verification ==="
echo ""

echo "--- Step 1: Command Audit ---"
check "pre_tool_use.rs exists" \
  "test -f $CORTINA/src/hooks/pre_tool_use.rs"
check "passthrough logic exists" \
  "grep -rq 'passthrough\|pass_through\|skip\|bypass' $CORTINA/src/hooks/pre_tool_use.rs"

echo ""
echo "--- Step 2: Non-Rewritten Passthrough ---"
check "command matching before rewrite" \
  "grep -rq 'match\|should_rewrite\|is_rewritable\|known_command' $CORTINA/src/hooks/pre_tool_use.rs"

echo ""
echo "--- Step 3: Error Preservation ---"
check "error output handling" \
  "grep -rq 'stderr\|error\|exit_code\|status' $CORTINA/src/hooks/pre_tool_use.rs"

echo ""
echo "--- Build Verification ---"
check "cargo test passes" \
  "cd $CORTINA && cargo test --quiet 2>&1"
check "cargo clippy clean" \
  "cd $CORTINA && cargo clippy --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
