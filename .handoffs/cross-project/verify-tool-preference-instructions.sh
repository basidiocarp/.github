#!/usr/bin/env bash
# Verify: tool-preference-instructions handoff
# Checks that CLAUDE.md contains the Tool Selection Guide section.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1: $2"; FAIL=$((FAIL+1)); }

echo "=== Verify: tool-preference-instructions ==="

CLAUDE_MD="$(git rev-parse --show-toplevel)/CLAUDE.md"

if [ ! -f "$CLAUDE_MD" ]; then
  echo "FATAL: CLAUDE.md not found at $CLAUDE_MD"
  exit 1
fi

# Check for section header
if grep -q "Tool Selection Guide" "$CLAUDE_MD"; then
  pass "Tool Selection Guide section present"
else
  fail "CLAUDE.md" "missing 'Tool Selection Guide' section"
fi

# Check for rhizome guidance
if grep -q "mcp__rhizome__search_symbols" "$CLAUDE_MD"; then
  pass "rhizome tool name present (mcp__rhizome__search_symbols)"
else
  fail "CLAUDE.md" "missing mcp__rhizome__search_symbols"
fi

# Check for hyphae guidance
if grep -q "hyphae_memory_recall" "$CLAUDE_MD"; then
  pass "hyphae tool name present (hyphae_memory_recall)"
else
  fail "CLAUDE.md" "missing hyphae_memory_recall"
fi

# Check for mycelium/cortina automatic behavior
if grep -q "cortina\|automatically" "$CLAUDE_MD"; then
  pass "mycelium/cortina automatic behavior documented"
else
  fail "CLAUDE.md" "missing cortina/automatic mycelium explanation"
fi

# Check for native tools section
if grep -q "When to use native tools\|native tools" "$CLAUDE_MD"; then
  pass "native tools guidance present"
else
  fail "CLAUDE.md" "missing native tools section"
fi

echo ""
echo "Results: ${PASS} pass / ${FAIL} fail"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
