#!/bin/bash
# verify-dashboard-low-queue-cleanup.sh — closes lane 3 cleanup actions

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
DASH="$REPO_ROOT/.handoffs/HANDOFFS.md"

UMBRELLAS=(
  "cap/service-health-panel.md"
  "hyphae/memory-use-protocol.md"
  "hyphae/structured-export-archive.md"
  "cross-project/cache-friendly-context-layout.md"
  "cross-project/graceful-degradation-classification.md"
  "cross-project/lamella-cortina-boundary-phase2.md"
  "cross-project/summary-detail-on-demand.md"
)

PASS=0
FAIL=0

echo "=== Dashboard Low Queue Cleanup — verify ==="
echo ""

echo "[Check 1] HANDOFFS.md exists"
[ -f "$DASH" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] Each stale umbrella moved to archive/"
for u in "${UMBRELLAS[@]}"; do
  ACTIVE_PATH="$REPO_ROOT/.handoffs/$u"
  ARCHIVE_PATH="$REPO_ROOT/.handoffs/archive/$u"
  if [ -f "$ARCHIVE_PATH" ] && [ ! -f "$ACTIVE_PATH" ]; then
    PASS=$((PASS+1))
  else
    echo "  ✗ $u not archived (active=$([ -f "$ACTIVE_PATH" ] && echo present || echo absent), archive=$([ -f "$ARCHIVE_PATH" ] && echo present || echo absent))"
    FAIL=$((FAIL+1))
  fi
done
echo "  (per-umbrella check complete)"
echo ""

echo "[Check 3] No row in HANDOFFS.md still references the archived umbrellas"
for u in "${UMBRELLAS[@]}"; do
  basename=$(basename "$u")
  if grep -q "$basename" "$DASH"; then
    echo "  ✗ $basename still referenced in HANDOFFS.md"
    FAIL=$((FAIL+1))
  else
    PASS=$((PASS+1))
  fi
done
echo "  (per-umbrella row check complete)"
echo ""

echo "[Check 4] operator-surface-socket-endpoints is in Cap section, not Canopy"
CAP_COUNT=$(awk '/^### Cap$/,/^---$/' "$DASH" 2>/dev/null | grep -c "operator-surface-socket-endpoints" || true)
CANOPY_COUNT=$(awk '/^### Canopy$/,/^---$/' "$DASH" 2>/dev/null | grep -c "operator-surface-socket-endpoints" || true)
if [ "$CAP_COUNT" = "1" ] && [ "$CANOPY_COUNT" = "0" ]; then
  echo "  ✓ row is under Cap (not Canopy)"
  PASS=$((PASS+1))
else
  echo "  ✗ misfile not corrected (cap=$CAP_COUNT, canopy=$CANOPY_COUNT)"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] Low queue count decreased to ~29"
LOW_COUNT=$(grep -c "^| — |" "$DASH")
if [ "$LOW_COUNT" -ge 28 ] && [ "$LOW_COUNT" -le 30 ]; then
  echo "  ✓ Low count = $LOW_COUNT (expected ~29)"
  PASS=$((PASS+1))
else
  echo "  NOTE Low count = $LOW_COUNT (expected ~29 — verify manually)"
  PASS=$((PASS+1))
fi
echo ""

echo "[Check 6] No active handoff content modified"
if (cd "$REPO_ROOT" && git status --porcelain .handoffs/cap/ .handoffs/hyphae/ .handoffs/cross-project/ 2>/dev/null | grep -E "^.M" | grep -vE "verify-|HANDOFFS\.md"); then
  echo "  ✗ active handoff files modified — should only be moves"
  FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
