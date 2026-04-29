#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
ROADMAP="$ROOT/docs/foundations/core-hardening-freeze-roadmap.md"

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

check "freeze roadmap exists" test -f "$ROADMAP"

check "roadmap has required sections" \
  /bin/zsh -lc "rg -q '^## Freeze Decision' '$ROADMAP' && rg -q '^## Active Hardening Repos' '$ROADMAP' && rg -q '^## Maintenance/Frozen Repos' '$ROADMAP' && rg -q '^## Allowed Work During Freeze' '$ROADMAP' && rg -q '^## Deferred Work' '$ROADMAP' && rg -q '^## Exception Process' '$ROADMAP' && rg -q '^## Exit Criteria' '$ROADMAP' && rg -q '^## Current Handoff Triage' '$ROADMAP'"

check "roadmap names core repos" \
  /bin/zsh -lc "rg -q 'mycelium' '$ROADMAP' && rg -q 'rhizome' '$ROADMAP' && rg -q 'hyphae' '$ROADMAP' && rg -q 'septa' '$ROADMAP'"

check "roadmap names freeze or maintenance repos" \
  /bin/zsh -lc "rg -q 'cap' '$ROADMAP' && rg -q 'lamella|annulus|volva|hymenium|canopy' '$ROADMAP'"

check "dashboard links roadmap handoff" \
  /bin/zsh -lc "rg -q 'Core Hardening Freeze Roadmap|core-hardening-freeze-roadmap' '$ROOT/.handoffs/HANDOFFS.md'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0

