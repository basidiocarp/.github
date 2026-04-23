#!/usr/bin/env bash
# Verify: ecosystem-smoke-test handoff
# Checks that scripts/smoke-test.sh exists, is executable, and runs without syntax errors.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1: $2"; FAIL=$((FAIL+1)); }

echo "=== Verify: ecosystem-smoke-test ==="

# Check script exists
SCRIPT="$(git rev-parse --show-toplevel)/scripts/smoke-test.sh"
if [ -f "$SCRIPT" ]; then
  pass "scripts/smoke-test.sh exists"
else
  fail "scripts/smoke-test.sh" "file not found at $SCRIPT"
fi

# Check executable
if [ -x "$SCRIPT" ]; then
  pass "smoke-test.sh is executable"
else
  fail "smoke-test.sh" "not executable (run: chmod +x $SCRIPT)"
fi

# Check syntax
if bash -n "$SCRIPT" 2>/dev/null; then
  pass "smoke-test.sh syntax valid"
else
  fail "smoke-test.sh" "bash syntax check failed"
fi

# Run the script (output goes to stdout; we check exit code)
echo ""
echo "--- Running smoke-test.sh ---"
if bash "$SCRIPT"; then
  pass "smoke-test.sh exited 0"
else
  EXIT=$?
  if [ "$EXIT" -eq 1 ]; then
    fail "smoke-test.sh" "one or more seams FAILED (exit $EXIT)"
  else
    fail "smoke-test.sh" "unexpected exit code $EXIT"
  fi
fi

echo ""
echo "Results: ${PASS} pass / ${FAIL} fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
