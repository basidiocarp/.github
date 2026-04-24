#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/lamella" 2>/dev/null || {
  echo "FAIL: could not find lamella repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

SKILL="resources/skills/core/token-efficiency/SKILL.md"

check "make validate" make validate
check "token-efficiency skill file exists" test -f "$SKILL"
check "YAML frontmatter present" grep -q "^name:\|^---" "$SKILL"
check "When to Activate section present" grep -q "When to Activate" "$SKILL"
check "How It Works section present" grep -q "How It Works" "$SKILL"
check "SessionStart referenced" grep -q "SessionStart" "$SKILL"
check "cortina referenced" grep -q "cortina" "$SKILL"
check "eval criteria present" grep -qi "eval\|baseline\|terse" "$SKILL"

echo ""
echo "Results: $PASS passed, $FAIL failed"
