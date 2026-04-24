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
check "agent-introspection-debugging skill file exists" test -f resources/skills/agent-introspection-debugging.md
check "YAML frontmatter present" grep -q "^name:\|^---" resources/skills/agent-introspection-debugging.md
check "When to Activate section present" grep -q "When to Activate" resources/skills/agent-introspection-debugging.md
check "four-phase protocol present" grep -q "Failure Capture\|Root-Cause\|Contained Recovery\|Introspection Report" resources/skills/agent-introspection-debugging.md
check "Operating Contract section present" grep -q "Operating Contract" resources/skills/agent-introspection-debugging.md
check "failure pattern table present" grep -q "Loop detection\|rate.limit\|stale.diff\|permission" resources/skills/agent-introspection-debugging.md
check "introspection report format defined" grep -q "Introspection Report\|report format" resources/skills/agent-introspection-debugging.md
check "hyphae referenced for storage" grep -q "hyphae" resources/skills/agent-introspection-debugging.md

echo ""
echo "Results: $PASS passed, $FAIL failed"
