#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

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

check "AGENTS states CLI is not preferred system-to-system protocol" \
  /bin/zsh -lc "rg -q 'CLI.*human|human/operator|system-to-system' '$ROOT/AGENTS.md'"

check "contracts or foundations document the integration hierarchy" \
  /bin/zsh -lc "rg -q 'library|service endpoint|capability|CLI fallback|compatibility adapter' '$ROOT/septa' '$ROOT/docs/foundations' '$ROOT/.handoffs/cross-project'"

check "Canopy dispatch endpoint handoff treats CLI as operator surface" \
  /bin/zsh -lc "rg -q 'operator surface|human/operator|not.*system-to-system|CLI.*compatibility' '$ROOT/.handoffs/canopy/dispatch-request-service-endpoint.md'"

check "Hymenium capability client handoff treats CLI as fallback only" \
  /bin/zsh -lc "rg -q 'fallback only|compatibility fallback|typed endpoint.*preferred|CLI.*fallback' '$ROOT/.handoffs/hymenium/capability-dispatch-client.md'"

check "dashboard tracks the communication boundary handoff" \
  /bin/zsh -lc "rg -q 'System-To-System Communication Boundary|system-to-system' '$ROOT/.handoffs/HANDOFFS.md'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0

