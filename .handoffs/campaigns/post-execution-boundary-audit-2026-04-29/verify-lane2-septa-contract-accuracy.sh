#!/bin/bash
# verify-lane2-septa-contract-accuracy.sh
#
# Confirms lane 2 of the Post-Execution Boundary Compliance Audit produced
# its findings file with the required structure.

set -e

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." && pwd )"
FINDINGS="$REPO_ROOT/.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-septa-contract-accuracy.md"

PASS=0
FAIL=0

echo "=== Lane 2: Septa Contract Accuracy — verify ==="
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
  "^## Baseline"
  "^## Producer/Consumer Map"
  "^## Findings"
  "^## Clean Areas"
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

# Check 3: septa/validate-all.sh still green
echo "[Check 3] septa/validate-all.sh still green"
if (cd "$REPO_ROOT/septa" && bash validate-all.sh) >/dev/null 2>&1; then
  echo "  ✓ validate-all.sh exits 0"
  PASS=$((PASS+1))
else
  echo "  ✗ validate-all.sh failing — investigate before audit"
  FAIL=$((FAIL+1))
fi
echo ""

# Check 4: at least one schema file referenced in the findings
echo "[Check 4] Findings reference at least one schema"
if [ -f "$FINDINGS" ]; then
  if grep -qE "\.schema\.json|-v[0-9]" "$FINDINGS"; then
    echo "  ✓ schema references present"
    PASS=$((PASS+1))
  else
    echo "  ✗ no schema references in findings"
    FAIL=$((FAIL+1))
  fi
fi
echo ""

# Check 5: producer/consumer map has rows
echo "[Check 5] Producer/Consumer Map has rows"
if [ -f "$FINDINGS" ]; then
  # Pull the section between "## Producer/Consumer Map" and the next ## heading.
  if awk '/^## Producer\/Consumer Map/{flag=1;next}/^## /{flag=0}flag' "$FINDINGS" | grep -qE "^\|"; then
    echo "  ✓ map table has rows"
    PASS=$((PASS+1))
  else
    echo "  ✗ producer/consumer map appears empty"
    FAIL=$((FAIL+1))
  fi
fi
echo ""

# Summary
echo "Results: $PASS passed, $FAIL failed"
if [ $FAIL -eq 0 ]; then
  exit 0
else
  exit 1
fi
