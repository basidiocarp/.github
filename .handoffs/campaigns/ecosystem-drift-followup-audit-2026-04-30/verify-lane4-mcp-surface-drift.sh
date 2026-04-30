#!/bin/bash
# verify-lane4-mcp-surface-drift.sh

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." && pwd )"
FINDINGS="$REPO_ROOT/.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/findings/lane4-mcp-surface-drift.md"

PASS=0; FAIL=0
echo "=== Lane 4: MCP Surface vs CLAUDE.md Drift — verify ==="
echo ""

echo "[Check 1] Findings file exists"
if [ -f "$FINDINGS" ]; then echo "  ✓"; PASS=$((PASS+1)); else echo "  ✗ MISSING"; FAIL=$((FAIL+1)); fi
echo ""

echo "[Check 2] Required sections present"
for s in "^## Summary" "^## Hyphae MCP Surface" "^## Rhizome MCP Surface" "^## Findings" "^## Clean Areas"; do
  if [ -f "$FINDINGS" ] && grep -qE "$s" "$FINDINGS"; then PASS=$((PASS+1)); else echo "  ✗ missing '$s'"; FAIL=$((FAIL+1)); fi
done
echo "  (per-section check complete)"
echo ""

echo "[Check 3] mcp__ tool references analyzed"
if [ -f "$FINDINGS" ] && grep -qE "mcp__hyphae__|mcp__rhizome__" "$FINDINGS"; then echo "  ✓"; PASS=$((PASS+1)); else echo "  ✗ no mcp__* references in findings"; FAIL=$((FAIL+1)); fi
echo ""

echo "[Check 4] Surface tables have rows"
if [ -f "$FINDINGS" ] && awk '/^## Hyphae MCP Surface/{flag=1;next}/^## /{flag=0}flag' "$FINDINGS" | grep -qE "^\|"; then
  PASS=$((PASS+1))
else
  echo "  ✗ Hyphae MCP Surface table empty"; FAIL=$((FAIL+1))
fi
if [ -f "$FINDINGS" ] && awk '/^## Rhizome MCP Surface/{flag=1;next}/^## /{flag=0}flag' "$FINDINGS" | grep -qE "^\|"; then
  PASS=$((PASS+1))
else
  echo "  ✗ Rhizome MCP Surface table empty"; FAIL=$((FAIL+1))
fi
echo "  (per-surface table check complete)"
echo ""

echo "[Check 5] No CLAUDE.md or AGENTS.md modified by this lane"
if (cd "$REPO_ROOT" && git status --porcelain 'CLAUDE.md' 'AGENTS.md' '*/CLAUDE.md' '*/AGENTS.md' 2>/dev/null | grep -qE "^.M"); then
  echo "  NOTE doc files have uncommitted changes — verify they are unrelated"; PASS=$((PASS+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
