#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/williamnewton/projects/basidiocarp"
handoff="$ROOT/.handoffs/archive/cross-project/ecosystem-logging-rollout-phase2.md"

pass_count=0
fail_count=0

check() {
  local description="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$description"
    pass_count=$((pass_count + 1))
  else
    printf 'FAIL: %s\n' "$description"
    fail_count=$((fail_count + 1))
  fi
}

check "phase 2 handoff exists" test -f "$handoff"
check "phase 2 handoff names all target repos" rg -q 'mycelium|cortina|stipe|hyphae|rhizome|canopy|volva' "$handoff"
check "phase 2 handoff calls out shared spore logging contract" rg -q 'spore|logging|trace|stderr|stdout' "$handoff"
check "phase 2 handoff includes verification targets" rg -q '^## Verification targets' "$handoff"
check "phase 2 handoff records completion status" rg -q '^## Status' "$handoff"
check "phase 2 handoff records shipped outcome" rg -q '^## Outcome|v0\.8\.9|v0\.2\.8|v0\.7\.6|v0\.10\.5|a01dc03|44150d2|v0\.1\.1' "$handoff"

printf '\nResults: %d passed, %d failed\n' "$pass_count" "$fail_count"

if [ "$fail_count" -ne 0 ]; then
  exit 1
fi
