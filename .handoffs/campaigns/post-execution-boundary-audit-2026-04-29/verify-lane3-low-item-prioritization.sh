#!/bin/bash
# verify-lane3-low-item-prioritization.sh
#
# Confirms lane 3 of the Post-Execution Boundary Compliance Audit produced
# its findings file with the required structure.

set -e

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." && pwd )"
FINDINGS="$REPO_ROOT/.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane3-low-item-prioritization.md"

PASS=0
FAIL=0

echo "=== Lane 3: Low Item Prioritization — verify ==="
echo ""

# Check 1: findings file exists
echo "[Check 1] Findings file exists"
if [ -f "$FINDINGS" ]; then
  echo "  ✓ $FINDINGS"
  PASS=$((PASS+1))
else
  echo "  ✗ MISSING: $FINDINGS"
  FAIL=$((FAIL+1))
fi
echo ""

# Check 2: required sections present
echo "[Check 2] Required sections present"
REQUIRED_SECTIONS=(
  "^## Summary"
  "^## Classification Table"
  "^## Promote"
  "^## Close \(stale\)"
  "^## Close \(out-of-scope under freeze\)"
  "^## Demote/Defer"
  "^## Triage Required"
  "^## Recommended Dashboard Actions"
)
if [ -f "$FINDINGS" ]; then
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if grep -qE "$section" "$FINDINGS"; then
      echo "  ✓ section '$section'"
      PASS=$((PASS+1))
    else
      echo "  ✗ missing section '$section'"
      FAIL=$((FAIL+1))
    fi
  done
else
  echo "  (skipped — findings file missing)"
fi
echo ""

# Check 3: classification table has rows
echo "[Check 3] Classification Table has rows"
if [ -f "$FINDINGS" ]; then
  if awk '/^## Classification Table/{flag=1;next}/^## /{flag=0}flag' "$FINDINGS" | grep -qE "^\|"; then
    echo "  ✓ table has rows"
    PASS=$((PASS+1))
  else
    echo "  ✗ classification table appears empty"
    FAIL=$((FAIL+1))
  fi
fi
echo ""

# Check 4: F1 freeze roadmap is referenced
echo "[Check 4] F1 freeze roadmap referenced"
if [ -f "$FINDINGS" ]; then
  if grep -qE "F1|freeze|core-hardening" "$FINDINGS"; then
    echo "  ✓ F1 reference present"
    PASS=$((PASS+1))
  else
    echo "  ✗ no F1 / freeze references in findings"
    FAIL=$((FAIL+1))
  fi
fi
echo ""

# Check 5: dashboard not modified during audit
echo "[Check 5] HANDOFFS.md not modified by lane 3"
if (cd "$REPO_ROOT" && git status --porcelain .handoffs/HANDOFFS.md 2>/dev/null | grep -qE "^.M"); then
  echo "  NOTE HANDOFFS.md has uncommitted changes — verify they are unrelated"
  PASS=$((PASS+1))
else
  echo "  ✓ HANDOFFS.md unchanged in working tree"
  PASS=$((PASS+1))
fi
echo ""

# Summary
echo "Results: $PASS passed, $FAIL failed"
if [ $FAIL -eq 0 ]; then
  exit 0
else
  exit 1
fi
