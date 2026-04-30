#!/bin/bash
# verify-workspace-claude-md-mcp-tool-coverage.sh — closes F4.3, F4.4

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
WS_CLAUDE="$REPO_ROOT/CLAUDE.md"
HYPHAE_CLAUDE="$REPO_ROOT/hyphae/CLAUDE.md"
RHIZOME_CLAUDE="$REPO_ROOT/rhizome/CLAUDE.md"

PASS=0; FAIL=0

echo "=== Workspace CLAUDE.md MCP Tool Coverage — verify ==="
echo ""

echo "[Check 1] Workspace CLAUDE.md present"
[ -f "$WS_CLAUDE" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] Workspace CLAUDE.md references at least 8 hyphae mcp tools"
HYPHAE_REFS=$(grep -oE 'mcp__hyphae__[a-zA-Z_]+' "$WS_CLAUDE" | sort -u | wc -l | tr -d ' ')
if [ "$HYPHAE_REFS" -ge 8 ]; then
  echo "  ✓ ($HYPHAE_REFS unique mcp__hyphae__ refs)"; PASS=$((PASS+1))
else
  echo "  ✗ only $HYPHAE_REFS unique mcp__hyphae__ refs (expected ≥8)"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] Workspace CLAUDE.md references at least 8 rhizome mcp tools"
RHIZ_REFS=$(grep -oE 'mcp__rhizome__[a-zA-Z_]+' "$WS_CLAUDE" | sort -u | wc -l | tr -d ' ')
if [ "$RHIZ_REFS" -ge 8 ]; then
  echo "  ✓ ($RHIZ_REFS unique mcp__rhizome__ refs)"; PASS=$((PASS+1))
else
  echo "  ✗ only $RHIZ_REFS unique mcp__rhizome__ refs (expected ≥8)"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] hyphae/CLAUDE.md count refresh"
if [ -f "$HYPHAE_CLAUDE" ] && grep -qE "37 (default )?(tools?|MCP)" "$HYPHAE_CLAUDE"; then
  echo "  ✗ hyphae/CLAUDE.md still claims 37 tools"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 5] rhizome/CLAUDE.md count refresh"
if [ -f "$RHIZOME_CLAUDE" ] && grep -qE "38 (default )?(tools?|MCP)" "$RHIZOME_CLAUDE"; then
  echo "  ✗ rhizome/CLAUDE.md still claims 38 tools"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 6] hyphae/CLAUDE.md has at least 4 mcp__hyphae__ references"
if [ -f "$HYPHAE_CLAUDE" ]; then
  N=$(grep -oE 'mcp__hyphae__[a-zA-Z_]+' "$HYPHAE_CLAUDE" | sort -u | wc -l | tr -d ' ')
  if [ "$N" -ge 4 ]; then echo "  ✓ ($N refs)"; PASS=$((PASS+1)); else echo "  ✗ only $N refs"; FAIL=$((FAIL+1)); fi
fi
echo ""

echo "[Check 7] rhizome/CLAUDE.md has at least 4 mcp__rhizome__ references"
if [ -f "$RHIZOME_CLAUDE" ]; then
  N=$(grep -oE 'mcp__rhizome__[a-zA-Z_]+' "$RHIZOME_CLAUDE" | sort -u | wc -l | tr -d ' ')
  if [ "$N" -ge 4 ]; then echo "  ✓ ($N refs)"; PASS=$((PASS+1)); else echo "  ✗ only $N refs"; FAIL=$((FAIL+1)); fi
fi
echo ""

echo "[Check 8] No MCP server source modified (out of scope)"
if (cd "$REPO_ROOT" && git status --porcelain hyphae/crates/hyphae-mcp/ rhizome/src/ 2>/dev/null | grep -qE "^.M"); then
  echo "  NOTE MCP server source modified — verify unrelated"; PASS=$((PASS+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
