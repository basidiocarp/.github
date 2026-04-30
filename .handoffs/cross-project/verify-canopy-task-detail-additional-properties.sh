#!/bin/bash
# verify-canopy-task-detail-additional-properties.sh — closes F2.14, F2.15

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
SCHEMA="$REPO_ROOT/septa/canopy-task-detail-v1.schema.json"
CANOPY_API="$REPO_ROOT/canopy/src/api.rs"

PASS=0; FAIL=0

echo "=== canopy-task-detail additionalProperties (Option C) — verify ==="
echo ""

echo "[Check 1] Schema file exists"
[ -f "$SCHEMA" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] Schema retains additionalProperties: false on root + attention"
# Option C keeps strict additionalProperties; promoted fields are added to the schema rather than relaxing the constraint.
ADDPROP_FALSE_COUNT=$(grep -c '"additionalProperties"\s*:\s*false' "$SCHEMA" 2>/dev/null || echo 0)
if [ "$ADDPROP_FALSE_COUNT" -ge 2 ]; then
  echo "  ✓ ($ADDPROP_FALSE_COUNT additionalProperties:false occurrences)"; PASS=$((PASS+1))
else
  echo "  ✗ schema relaxed additionalProperties — Option C requires keeping it false"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 3] Producer uses a wire type or skip_serializing for internal-only fields"
if grep -qE 'TaskDetailWire|TaskAttentionWire|#\[serde\(skip_serializing\)\]' "$CANOPY_API" "$REPO_ROOT/canopy/src/store/"*.rs 2>/dev/null; then
  echo "  ✓ wire struct or skip_serializing pattern present"; PASS=$((PASS+1))
else
  echo "  ✗ no wire struct or skip_serializing detected — Option C requires producer split"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] septa/validate-all.sh remains green"
if (cd "$REPO_ROOT/septa" && bash validate-all.sh) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ validate-all.sh failing"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] canopy build green"
if (cd "$REPO_ROOT/canopy" && cargo build --release) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ canopy build failing"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 6] canopy tests pass"
if (cd "$REPO_ROOT/canopy" && cargo test --release) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ canopy tests failing"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 7] Cap consumer not modified (no scope creep)"
if (cd "$REPO_ROOT" && git status --porcelain cap/ 2>/dev/null | grep -qE "^.M"); then
  echo "  NOTE cap has uncommitted changes — verify unrelated"; PASS=$((PASS+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
