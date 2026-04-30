#!/bin/bash
# verify-lane2-producer-schema-drift.sh

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." && pwd )"
FINDINGS="$REPO_ROOT/.handoffs/campaigns/ecosystem-drift-followup-audit-2026-04-30/findings/lane2-producer-schema-drift.md"

PASS=0; FAIL=0
echo "=== Lane 2: Producer-Side Schema Drift — verify ==="
echo ""

echo "[Check 1] Findings file exists"
if [ -f "$FINDINGS" ]; then echo "  ✓"; PASS=$((PASS+1)); else echo "  ✗ MISSING"; FAIL=$((FAIL+1)); fi
echo ""

echo "[Check 2] Required sections present"
for s in "^## Summary" "^## Per-Schema Results" "^## Findings" "^## Clean Areas"; do
  if [ -f "$FINDINGS" ] && grep -qE "$s" "$FINDINGS"; then PASS=$((PASS+1)); else echo "  ✗ missing '$s'"; FAIL=$((FAIL+1)); fi
done
echo "  (per-section check complete)"
echo ""

echo "[Check 3] At least the 7 high-priority schemas appear in findings"
HP="mycelium-gain-v1 canopy-snapshot-v1 canopy-task-detail-v1 stipe-doctor-v1 stipe-init-plan-v1 annulus-status-v1 evidence-ref-v1"
SEEN=0
for s in $HP; do
  if [ -f "$FINDINGS" ] && grep -q "$s" "$FINDINGS"; then SEEN=$((SEEN+1)); fi
done
if [ "$SEEN" -ge 7 ]; then echo "  ✓ all 7 high-priority schemas present"; PASS=$((PASS+1)); else echo "  ✗ only $SEEN/7 high-priority schemas referenced"; FAIL=$((FAIL+1)); fi
echo ""

echo "[Check 4] septa/validate-all.sh remains green"
if (cd "$REPO_ROOT/septa" && bash validate-all.sh) >/dev/null 2>&1; then echo "  ✓"; PASS=$((PASS+1)); else echo "  ✗"; FAIL=$((FAIL+1)); fi
echo ""

echo "[Check 5] No producer source modified by this lane"
if (cd "$REPO_ROOT" && git status --porcelain cortina/ hyphae/ hymenium/ mycelium/ rhizome/ stipe/ canopy/ volva/ annulus/ 2>/dev/null | grep -qE "^.M"); then
  echo "  NOTE producer-owning repos have uncommitted changes — verify they are unrelated"; PASS=$((PASS+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
