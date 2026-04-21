#!/bin/bash
# Verification script for create-handoff-skill.md
# Run: bash .handoffs/lamella/verify-create-handoff-skill.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LAMELLA="$ROOT/lamella"
CANOPY="$ROOT/canopy"

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

echo "=== CREATE-HANDOFF-SKILL Verification ==="
echo ""

echo "--- Step 1: Skill File ---"
check "SKILL.md exists" \
  "test -f $LAMELLA/resources/skills/meta/create-handoff/SKILL.md"
check "has frontmatter with name" \
  "grep -q 'name: create-handoff' $LAMELLA/resources/skills/meta/create-handoff/SKILL.md"
check "documents directory convention" \
  "grep -q '<project>' $LAMELLA/resources/skills/meta/create-handoff/SKILL.md"
check "includes verify script template" \
  "grep -q 'check()' $LAMELLA/resources/skills/meta/create-handoff/SKILL.md"
check "lists anti-patterns" \
  "grep -qi 'anti.pattern' $LAMELLA/resources/skills/meta/create-handoff/SKILL.md"

echo ""
echo "--- Step 2: Plugin Manifest ---"
check "create-handoff in meta manifest" \
  "grep -q 'create-handoff' $LAMELLA/manifests/claude/meta.json"

echo ""
echo "--- Step 3: Canopy Convention Validation ---"
check "validate_handoff_path function exists" \
  "grep -rq 'validate_handoff_path\\|validate.*handoff.*path' $CANOPY/src/"
check "warns on root-level handoffs" \
  "grep -rq 'handoffs.*root\\|root.*handoff\\|parent.*handoffs' $CANOPY/src/"
check "warns on missing verify script" \
  "grep -rq 'verify.*script.*found\\|No verify script\\|verify.*missing' $CANOPY/src/"

echo ""
echo "--- Step 4: Slash Command ---"
check "create-handoff command exists" \
  "test -f $LAMELLA/resources/commands/development/create-handoff.md"
check "command has frontmatter" \
  "grep -q 'name: create-handoff' $LAMELLA/resources/commands/development/create-handoff.md"

echo ""
echo "--- Build Verification ---"
check "lamella validate passes" \
  "cd $LAMELLA && make validate 2>&1"
check "canopy cargo test passes" \
  "cd $CANOPY && cargo test --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
