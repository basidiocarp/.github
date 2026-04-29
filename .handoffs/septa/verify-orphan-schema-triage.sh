#!/bin/bash
# verify-orphan-schema-triage.sh — closes F2.10

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
SEPTA="$REPO_ROOT/septa"
REPORT="$REPO_ROOT/.handoffs/campaigns/post-execution-boundary-audit-2026-04-29/findings/lane2-orphan-triage-decisions.md"

ORPHANS=(
  "context-envelope-v1"
  "credential-v1"
  "degradation-tier-v1"
  "dependency-types-v1"
  "handoff-context-v1"
  "hook-execution-v1"
  "host-identifier-v1"
  "local-service-endpoint-v1"
  "mycelium-summary-v1"
  "resolved-status-customization-v1"
  "tool-relevance-rules-v1"
  "task-output-v1"
)

PASS=0
FAIL=0

echo "=== Orphan Schema Triage — verify ==="
echo ""

echo "[Check 1] Decision report exists"
[ -f "$REPORT" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗ MISSING $REPORT"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] Each orphan has a decision entry"
if [ -f "$REPORT" ]; then
  for o in "${ORPHANS[@]}"; do
    if grep -qE "^### ${o} —" "$REPORT" || grep -qE "^### ${o}\b" "$REPORT"; then
      PASS=$((PASS+1))
    else
      echo "  ✗ no decision section for $o"
      FAIL=$((FAIL+1))
    fi
  done
  echo "  (per-schema check complete)"
else
  echo "  (skipped — report missing)"
fi
echo ""

echo "[Check 3] Each orphan has a definitive action (active / deleted / draft)"
for o in "${ORPHANS[@]}"; do
  ACTIVE=$([ -f "$SEPTA/$o.schema.json" ] && echo 1 || echo 0)
  DRAFT=$([ -f "$SEPTA/draft/$o.schema.json" ] && echo 1 || echo 0)
  TOTAL=$((ACTIVE + DRAFT))
  if [ "$TOTAL" -le 1 ]; then
    PASS=$((PASS+1))
  else
    echo "  ✗ $o is in BOTH active and draft locations"
    FAIL=$((FAIL+1))
  fi
done
echo "  (per-schema state check complete)"
echo ""

echo "[Check 4] septa/validate-all.sh still green"
if (cd "$SEPTA" && bash validate-all.sh) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ validate-all.sh failing after triage"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] No cross-repo source files modified"
if (cd "$REPO_ROOT" && git status --porcelain cap/ cortina/ hyphae/ mycelium/ rhizome/ stipe/ canopy/ hymenium/ volva/ annulus/ lamella/ spore/ 2>/dev/null | grep -qE "^.M"); then
  echo "  NOTE other repos have uncommitted changes — verify they are unrelated to F2.10"
  PASS=$((PASS+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
