#!/bin/bash
# verify-lane3-version-pin-drift.sh

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." && pwd )"
FINDINGS="$REPO_ROOT/.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/findings/lane3-version-pin-drift.md"

PASS=0; FAIL=0
echo "=== Lane 3: Shared Version Pin Drift — verify ==="
echo ""

echo "[Check 1] Findings file exists"
if [ -f "$FINDINGS" ]; then echo "  ✓"; PASS=$((PASS+1)); else echo "  ✗ MISSING"; FAIL=$((FAIL+1)); fi
echo ""

echo "[Check 2] Required sections present"
for s in "^## Summary" "^## Workspace-Pinned Versions" "^## Per-Repo Comparison" "^## Findings" "^## Clean Areas"; do
  if [ -f "$FINDINGS" ] && grep -qE "$s" "$FINDINGS"; then PASS=$((PASS+1)); else echo "  ✗ missing '$s'"; FAIL=$((FAIL+1)); fi
done
echo "  (per-section check complete)"
echo ""

echo "[Check 3] ecosystem-versions.toml referenced"
if [ -f "$FINDINGS" ] && grep -qE "ecosystem-versions\.toml|spore" "$FINDINGS"; then echo "  ✓"; PASS=$((PASS+1)); else echo "  ✗"; FAIL=$((FAIL+1)); fi
echo ""

echo "[Check 4] Per-repo comparison table has rows"
if [ -f "$FINDINGS" ] && awk '/^## Per-Repo Comparison/{flag=1;next}/^## /{flag=0}flag' "$FINDINGS" | grep -qE "^\|"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ comparison table empty"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] No Cargo.toml modified by this lane"
if (cd "$REPO_ROOT" && git status --porcelain '*Cargo.toml' 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ Cargo.toml modified — out of scope"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
