#!/bin/bash
# verify-tool-usage-event-skip-serializing-fix.sh — closes F2.17

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
EMIT="$REPO_ROOT/cortina/src/hooks/stop/tool_usage_emit.rs"

PASS=0; FAIL=0

echo "=== Cortina tool-usage-event Skip-Serializing Fix — verify ==="
echo ""

echo "[Check 1] Source file exists"
[ -f "$EMIT" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] skip_serializing_if removed from tools_available / tools_relevant_unused"
# Look at the 4 lines preceding each field declaration; if skip_serializing_if appears, fail.
if awk '/pub tools_available/{for(i=NR-4;i<=NR;i++) print arr[i]} {arr[NR]=$0}' "$EMIT" | grep -q 'skip_serializing_if'; then
  echo "  ✗ skip_serializing_if still present near tools_available"; FAIL=$((FAIL+1))
else
  echo "  ✓ tools_available clean"; PASS=$((PASS+1))
fi
if awk '/pub tools_relevant_unused/{for(i=NR-4;i<=NR;i++) print arr[i]} {arr[NR]=$0}' "$EMIT" | grep -q 'skip_serializing_if'; then
  echo "  ✗ skip_serializing_if still present near tools_relevant_unused"; FAIL=$((FAIL+1))
else
  echo "  ✓ tools_relevant_unused clean"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 3] cargo test passes"
if (cd "$REPO_ROOT/cortina" && cargo test --release) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ cargo test failing"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] septa schema unchanged"
if (cd "$REPO_ROOT" && git status --porcelain septa/tool-usage-event-v1.schema.json 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ schema modified"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
