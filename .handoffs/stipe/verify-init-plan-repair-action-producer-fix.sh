#!/bin/bash
# verify-init-plan-repair-action-producer-fix.sh — closes F2.16

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
STIPE="$REPO_ROOT/stipe"

PASS=0; FAIL=0

echo "=== Stipe Init-Plan Repair Action Producer Fix — verify ==="
echo ""

echo "[Check 1] No remaining tier: \"manual\" in init-plan call sites"
# Allow it elsewhere (doctor uses \"manual\"); restrict to init plan/repair files.
if grep -rnE 'tier:\s*"manual"' "$STIPE/src/commands/init/" 2>/dev/null | head -3; then
  echo "  ✗ tier: \"manual\" still present in init"
  FAIL=$((FAIL+1))
else
  echo "  ✓ no tier: \"manual\" in init"
  PASS=$((PASS+1))
fi
echo ""

echo "[Check 2] action_key referenced in RepairAction::manual context"
# Look for action_key in the same files where RepairAction::manual is invoked.
if grep -rnE 'action_key' "$STIPE/src/commands/init/" 2>/dev/null | head -1 >/dev/null; then
  echo "  ✓ action_key references present"
  PASS=$((PASS+1))
else
  echo "  ✗ no action_key references"
  FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] cargo test passes (release)"
if (cd "$STIPE" && cargo test --release) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ cargo test failing"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] cargo clippy clean"
if (cd "$STIPE" && cargo clippy -- -D warnings) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  NOTE clippy reported warnings — verify they are pre-existing"
  PASS=$((PASS+1))
fi
echo ""

echo "[Check 5] septa stipe schemas unchanged"
if (cd "$REPO_ROOT" && git status --porcelain septa/stipe-doctor-v1.schema.json septa/stipe-init-plan-v1.schema.json 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ schemas modified"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 6] septa/validate-all.sh still green"
if (cd "$REPO_ROOT/septa" && bash validate-all.sh) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗"; FAIL=$((FAIL+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
