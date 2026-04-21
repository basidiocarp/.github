#!/usr/bin/env bash
set -euo pipefail
PASS=0; FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"; FAIL=$((FAIL + 1))
  fi
}

check "lamella validates" /bin/bash -c "cd '$ROOT/lamella' && make validate --quiet 2>&1"
check "cortina README exists" test -f "$ROOT/cortina/README.md"
check "cap README exists" test -f "$ROOT/cap/README.md"
check "lamella README exists" test -f "$ROOT/lamella/README.md"
check "lamella skills-spec exists" test -f "$ROOT/lamella/docs/authoring/skills-spec.md"

# Content checks for fixes made
check "no deprecated cortina statusline in cortina README" \
  bash -c "! grep -q 'cortina statusline' '$ROOT/cortina/README.md'"

check "cortina README mentions annulus statusline instead" \
  bash -c "grep -q 'annulus statusline' '$ROOT/cortina/README.md'"

check "lamella skill-inventory mentions core/ category path" \
  bash -c "grep -q 'resources/skills/core/' '$ROOT/lamella/docs/maintainers/skill-inventory.md'"

check "cap getting-started mentions Command History tab" \
  bash -c "grep -q 'Command History' '$ROOT/cap/docs/getting-started.md'"

check "cap getting-started mentions Ecosystem tab" \
  bash -c "grep -q 'Ecosystem' '$ROOT/cap/docs/getting-started.md'"

check "lamella skill-inventory references correct create-skill path" \
  bash -c "grep -q 'resources/skills/meta/create-skill' '$ROOT/lamella/docs/maintainers/skill-inventory.md'"

printf '\nResults: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
