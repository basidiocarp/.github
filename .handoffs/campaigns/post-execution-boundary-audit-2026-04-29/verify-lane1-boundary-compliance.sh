#!/bin/bash
# verify-lane1-boundary-compliance.sh
#
# Confirms lane 1 of the Post-Execution Boundary Compliance Audit produced
# its findings file with the required structure.

set -e

REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." && pwd )"
FINDINGS="$REPO_ROOT/.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane1-boundary-compliance.md"

PASS=0
FAIL=0

echo "=== Lane 1: Boundary Compliance — verify ==="
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

# Check 3: existing C7 verifier still passes
echo "[Check 3] Existing C7 verifier still green"
if bash "$REPO_ROOT/.handoffs/cross-project/verify-cli-coupling-exemption-audit.sh" >/dev/null 2>&1; then
  echo "  ✓ C7 verifier exits 0"
  PASS=$((PASS+1))
else
  echo "  ✗ C7 verifier failing — investigate before audit"
  FAIL=$((FAIL+1))
fi
echo ""

# Check 4: existing C8 verifier still passes
echo "[Check 4] Existing C8 verifier still green"
if bash "$REPO_ROOT/.handoffs/cross-project/verify-system-to-system-communication-boundary.sh" >/dev/null 2>&1; then
  echo "  ✓ C8 verifier exits 0"
  PASS=$((PASS+1))
else
  echo "  ✗ C8 verifier failing — investigate before audit"
  FAIL=$((FAIL+1))
fi
echo ""

# Check 5: at least one finding row present (audit shouldn't be empty if there's drift)
# This is informational — zero findings is allowed but unusual
echo "[Check 5] Findings file has structure"
if [ -f "$FINDINGS" ]; then
  if grep -qE "^### \[F1\." "$FINDINGS" || grep -qE "no findings" "$FINDINGS" -i; then
    echo "  ✓ findings or explicit 'no findings' note present"
    PASS=$((PASS+1))
  else
    echo "  NOTE no F1.* finding rows and no 'no findings' note — verify by hand"
    PASS=$((PASS+1))
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
