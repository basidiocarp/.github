#!/bin/bash
# Verification script for subagent-mcp-context.md
# Run: bash .handoffs/cross-project/verify-subagent-mcp-context.sh

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

echo "=== Subagent MCP Context Verification ==="
echo ""

echo "--- Step 1: Audit Subagent Patterns ---"
check "audit findings documented (fragment or agents reference MCP)" \
  "grep -rl 'ToolSearch\|rhizome\|mcp-context' $ROOT/lamella/resources/ 2>/dev/null | head -1"

echo ""
echo "--- Step 2: MCP Context Skill ---"
check "mcp-ecosystem-context skill exists" \
  "test -f $ROOT/lamella/resources/skills/tools/mcp-ecosystem-context/SKILL.md"
check "skill mentions ToolSearch" \
  "grep -q 'ToolSearch' $ROOT/lamella/resources/skills/tools/mcp-ecosystem-context/SKILL.md"
check "skill mentions rhizome tools" \
  "grep -q 'rhizome' $ROOT/lamella/resources/skills/tools/mcp-ecosystem-context/SKILL.md"
check "skill mentions hyphae tools" \
  "grep -q 'hyphae' $ROOT/lamella/resources/skills/tools/mcp-ecosystem-context/SKILL.md"
check "skill includes fallback guidance" \
  "grep -qi 'fall.back\|native\|Read.*Grep' $ROOT/lamella/resources/skills/tools/mcp-ecosystem-context/SKILL.md"

echo ""
echo "--- Step 3: Subagent Integration ---"
check "at least one subagent references mcp-ecosystem-context skill" \
  "grep -rl 'mcp-ecosystem-context' $ROOT/lamella/resources/subagents/ 2>/dev/null | head -1"
check "at least 10 subagents reference the skill" \
  "test $(grep -rl 'mcp-ecosystem-context' $ROOT/lamella/resources/subagents/ 2>/dev/null | wc -l) -ge 10"

echo ""
echo "--- Step 4: Cortina Spawn Investigation ---"
check "spawn investigation documented or hook implemented" \
  "grep -rq 'spawn\|subagent\|agent.*hook\|pre_agent' $ROOT/cortina/src/ 2>/dev/null || test -f $ROOT/cortina/docs/spawn-investigation.md"

echo ""
echo "--- Prior Art Verification ---"
check "main conversation has rhizome nudging (cortina pre_tool_use.rs or tool-preferences rule)" \
  "grep -q 'rhizome suggestion' $ROOT/cortina/src/hooks/pre_tool_use.rs 2>/dev/null || test -f $HOME/.claude/rules/common/tool-preferences.md"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
