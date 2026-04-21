#!/bin/bash
# Verification script for HANDOFF-TOOL-NUDGING.md
# Run: bash .handoffs/cross-project/verify-tool-nudging.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

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

echo "=== HANDOFF-TOOL-NUDGING Verification ==="
echo ""

echo "--- Step 1: Global Rule File ---"
check "tool-preferences.md exists" \
  "test -f $HOME/.claude/rules/common/tool-preferences.md"
check "tool-preferences.md mentions rhizome" \
  "grep -q 'rhizome' $HOME/.claude/rules/common/tool-preferences.md"
check "tool-preferences.md has preference table" \
  "grep -q 'get_symbols' $HOME/.claude/rules/common/tool-preferences.md"

echo ""
echo "--- Step 2: Cortina Read Advisory ---"
check "read_suggestion_for_path function exists" \
  "grep -q 'read_suggestion' $ROOT/cortina/src/hooks/pre_tool_use.rs"
check "CODE_EXTENSIONS defined" \
  "grep -q 'CODE_EXTENSIONS\\|code_extensions' $ROOT/cortina/src/hooks/pre_tool_use.rs"
check "rhizome_suggest_threshold in policy" \
  "grep -q 'rhizome_suggest_threshold' $ROOT/cortina/src/policy.rs"
check "rhizome_suggest_enabled in policy" \
  "grep -q 'rhizome_suggest_enabled' $ROOT/cortina/src/policy.rs"

echo ""
echo "--- Step 3: Cortina Grep Advisory ---"
check "grep_suggestion function exists" \
  "grep -q 'grep_suggestion' $ROOT/cortina/src/hooks/pre_tool_use.rs"
check "looks_like_symbol function exists" \
  "grep -q 'looks_like_symbol' $ROOT/cortina/src/hooks/pre_tool_use.rs"

echo ""
echo "--- Step 4: Mycelium find→fd Rewrite ---"
check "find-to-fd rewrite exists in mycelium" \
  "grep -rq 'fd' $ROOT/mycelium/src/filters/find.rs 2>/dev/null || grep -rq 'find.*fd\\|fd.*find' $ROOT/mycelium/src/rewrite.rs 2>/dev/null || grep -rq 'find_to_fd\\|rewrite_find' $ROOT/mycelium/src/ 2>/dev/null"

echo ""
echo "--- Build Verification ---"
check "cortina cargo test passes" \
  "cd $ROOT/cortina && cargo test --quiet 2>&1"
check "cortina cargo clippy clean" \
  "cd $ROOT/cortina && cargo clippy --all-targets --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
