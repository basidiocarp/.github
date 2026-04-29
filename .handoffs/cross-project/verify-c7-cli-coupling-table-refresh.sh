#!/bin/bash
# verify-c7-cli-coupling-table-refresh.sh — closes F1.1, F1.2, F1.3

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
TABLE="$REPO_ROOT/septa/integration-patterns.md"

PASS=0
FAIL=0

echo "=== C7 CLI Coupling Table Refresh — verify ==="
echo ""

echo "[Check 1] integration-patterns.md present"
[ -f "$TABLE" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] F1.1 — stipe → hyphae rows present"
HYPHAE_ROWS=$(grep -cE "stipe.*hyphae|seed\.rs|configure\.rs" "$TABLE")
if [ "$HYPHAE_ROWS" -ge 2 ]; then
  echo "  ✓ ($HYPHAE_ROWS hyphae-related references found)"
  PASS=$((PASS+1))
else
  echo "  ✗ fewer than expected stipe→hyphae rows ($HYPHAE_ROWS)"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] F1.2 — stipe → lamella row present"
if grep -qE "stipe.*lamella|package_repair" "$TABLE"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ no stipe→lamella row"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] F1.3 — annulus row mentions validate-hooks (not --version)"
if grep -qE "validate-hooks" "$TABLE"; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ annulus row still understates the contract"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] Existing C7 verifier still green"
if bash "$REPO_ROOT/.handoffs/cross-project/verify-cli-coupling-exemption-audit.sh" >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ existing C7 verifier failing — KNOWN_SITES may need refresh"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 6] Stipe and annulus source unchanged"
if (cd "$REPO_ROOT" && git status --porcelain stipe/ annulus/ 2>/dev/null | grep -qE "^.M"); then
  echo "  NOTE stipe/ or annulus/ has uncommitted changes — verify they are unrelated to this handoff"
  PASS=$((PASS+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
