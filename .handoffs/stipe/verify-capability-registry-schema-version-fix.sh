#!/bin/bash
# verify-capability-registry-schema-version-fix.sh — closes F2.19

set -e
REPO_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"
REGISTRY="$REPO_ROOT/stipe/src/commands/tool_registry/capability_registry.rs"

PASS=0; FAIL=0

echo "=== Capability-Registry Schema-Version Fix — verify ==="
echo ""

echo "[Check 1] Source file exists"
[ -f "$REGISTRY" ] && { echo "  ✓"; PASS=$((PASS+1)); } || { echo "  ✗"; FAIL=$((FAIL+1)); }
echo ""

echo "[Check 2] No bogus schema_version literal"
if grep -nE 'schema_version.*"capability-registry-v1"' "$REGISTRY"; then
  echo "  ✗ bogus literal still present"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "[Check 3] schema_version uses 1.0 (or a constant referencing it)"
if grep -nE '"1\.0"|CAPABILITY_REGISTRY_SCHEMA_VERSION|SCHEMA_VERSION.*=.*"1\.0"' "$REGISTRY" >/dev/null; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ schema_version='1.0' not visible"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 4] cargo test passes"
if (cd "$REPO_ROOT/stipe" && cargo test --release) >/dev/null 2>&1; then
  echo "  ✓"; PASS=$((PASS+1))
else
  echo "  ✗ cargo test failing"; FAIL=$((FAIL+1))
fi
echo ""

echo "[Check 5] septa schema unchanged"
if (cd "$REPO_ROOT" && git status --porcelain septa/capability-registry-v1.schema.json 2>/dev/null | grep -qE "^.M"); then
  echo "  ✗ schema modified"; FAIL=$((FAIL+1))
else
  echo "  ✓"; PASS=$((PASS+1))
fi
echo ""

echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ] && exit 0 || exit 1
