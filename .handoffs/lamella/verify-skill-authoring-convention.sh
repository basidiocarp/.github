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

check "make validate" make validate
check "skill authoring convention doc exists" test -f docs/skill-authoring-convention.md
check "skill template file exists" test -f resources/skills/SKILL_TEMPLATE.md
check "lint-skills target in Makefile" grep -q "lint-skills" Makefile
check "lint-skills wired into validate" grep -A5 "^validate" Makefile | grep -q "lint-skills"

echo ""
echo "Results: $PASS passed, $FAIL failed"
