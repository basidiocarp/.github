#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    ((PASS++))
  else
    echo "FAIL: $label"
    ((FAIL++))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/lamella" 2>/dev/null || {
  echo "FAIL: could not find lamella repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "make validate" make validate
check "strategic-compact skill file exists" test -f resources/skills/strategic-compact.md
check "YAML frontmatter present" grep -q "^name:\|^---" resources/skills/strategic-compact.md
check "When to Activate section present" grep -q "When to Activate" resources/skills/strategic-compact.md
check "decision table with thresholds present" grep -q "80\|60\|threshold\|compact now\|compact soon" resources/skills/strategic-compact.md
check "annulus referenced for context metrics" grep -q "annulus" resources/skills/strategic-compact.md
check "PreCompact hook integration present" grep -q "PreCompact\|pre-compact\|pre_compact" resources/skills/strategic-compact.md

echo ""
echo "Results: $PASS passed, $FAIL failed"
