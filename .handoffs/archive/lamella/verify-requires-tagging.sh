#!/bin/bash
# Verification script for HANDOFF-LAMELLA-REQUIRES-TAGGING.md (Phase 1)
# Run: bash .handoffs/lamella/verify-requires-tagging.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LAMELLA="$ROOT/lamella"

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    ((FAIL++))
  fi
}

echo "=== HANDOFF-LAMELLA-REQUIRES-TAGGING Verification (Phase 1) ==="
echo ""

echo "--- Validator Updates ---"
check "validate-skills.js accepts requires field" \
  "grep -q 'requires' $LAMELLA/scripts/ci/validate-skills.js"
check "validate-subagents.js accepts requires field" \
  "grep -q 'requires' $LAMELLA/scripts/ci/validate-subagents.js"
check "validate-commands.js accepts requires field" \
  "grep -q 'requires' $LAMELLA/scripts/ci/validate-commands.js"
check "validate-hooks.js accepts requires field" \
  "grep -q 'requires' $LAMELLA/scripts/ci/validate-hooks.js"

echo ""
echo "--- Content Tagged ---"
check "test-routing skill has requires" \
  "grep -q 'requires:' $LAMELLA/resources/skills/core/test-routing/SKILL.md 2>/dev/null || grep -q 'requires:' $LAMELLA/resources/skills/*/test-routing/SKILL.md 2>/dev/null"
check "diagnose skill has requires" \
  "grep -q 'requires:' $LAMELLA/resources/skills/core/diagnose/SKILL.md 2>/dev/null || grep -q 'requires:' $LAMELLA/resources/skills/*/diagnose/SKILL.md 2>/dev/null"
check "token-reduction-optimizer has requires" \
  "grep -q 'requires:' $LAMELLA/resources/skills/tools/token-reduction-optimizer/SKILL.md 2>/dev/null"
check "hooks.json entries have requires where needed" \
  "grep -q 'requires' $LAMELLA/resources/hooks/hooks.json"

echo ""
echo "--- Detection Mechanism ---"
check "detected-tools.json cache logic exists" \
  "grep -rq 'detected.tools\\|detect.*tools\\|tool.*detect' $LAMELLA/scripts/plugins/ 2>/dev/null"

echo ""
echo "--- Install Pipeline ---"
check "install-plugin.sh checks requires" \
  "grep -q 'requires' $LAMELLA/scripts/plugins/install-plugin.sh"
check "--refresh flag supported" \
  "grep -q 'refresh' $LAMELLA/scripts/plugins/install-plugin.sh"
check "--all flag supported" \
  "grep -q '\\-\\-all' $LAMELLA/scripts/plugins/install-plugin.sh"

echo ""
echo "--- Build Pipeline ---"
check "build-plugin.sh preserves requires metadata" \
  "grep -q 'requires' $LAMELLA/scripts/plugins/build-plugin.sh"

echo ""
echo "--- Validation ---"
check "make validate passes" \
  "cd $LAMELLA && make validate 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
