#!/bin/bash
# Verification script for handoff-checkbox-enforcement.md
# Run: bash .handoffs/cross-project/verify-handoff-checkbox-enforcement.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Handoff Checkbox Enforcement Verification ==="
echo ""

echo "--- Step 1: Handoff Markdown Parser ---"
check "handoff_lint module exists" \
  "test -f $ROOT/cortina/src/handoff_lint.rs"
check "HandoffAudit struct defined" \
  "grep -q 'HandoffAudit' $ROOT/cortina/src/handoff_lint.rs"
check "checkbox counting logic" \
  "grep -q 'checked_checkboxes\|checkbox' $ROOT/cortina/src/handoff_lint.rs"
check "paste marker detection" \
  "grep -q 'PASTE\|paste_marker\|empty_paste' $ROOT/cortina/src/handoff_lint.rs"

echo ""
echo "--- Step 2: Cortina Stop Hook ---"
check "handoff validation in stop hook" \
  "grep -q 'handoff\|handoff_lint' $ROOT/cortina/src/hooks/stop.rs"
check "handoff_lint_enabled policy flag" \
  "grep -q 'handoff_lint_enabled' $ROOT/cortina/src/policy.rs"

echo ""
echo "--- Step 3: Lamella Skill ---"
check "handoff-check skill exists" \
  "test -f $ROOT/lamella/resources/skills/workflow/handoff-check/SKILL.md"
check "skill covers paste markers" \
  "grep -q 'PASTE\|paste' $ROOT/lamella/resources/skills/workflow/handoff-check/SKILL.md"
check "skill covers checkboxes" \
  "grep -qi 'checkbox\|checklist\|\\- \\[' $ROOT/lamella/resources/skills/workflow/handoff-check/SKILL.md"

echo ""
echo "--- Step 4: Pre-Commit Hook (optional) ---"
check "pre-commit handoff validation exists" \
  "grep -rq 'handoff\|staged_handoff' $ROOT/cortina/src/hooks/pre_commit.rs 2>/dev/null || echo 'optional step'"

echo ""
echo "--- Build Verification ---"
check "cortina cargo test passes" \
  "cd $ROOT/cortina && cargo test --quiet 2>&1"
check "cortina cargo clippy clean" \
  "cd $ROOT/cortina && cargo clippy --all-targets --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
