#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
REPORT="$ROOT/cap/docs/operator-console-scope-reset.md"

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

check "scope reset report exists" test -f "$REPORT"

check "report has required sections" \
  /bin/zsh -lc "rg -q '^## Executive Decision' '$REPORT' && rg -q '^## Operator Role' '$REPORT' && rg -q '^## Route Inventory' '$REPORT' && rg -q '^## API Inventory' '$REPORT' && rg -q '^## Screen Classification' '$REPORT' && rg -q '^## Split Assessment' '$REPORT' && rg -q '^## Rebuild Plan' '$REPORT' && rg -q '^## Freeze Rules' '$REPORT'"

check "report uses required classification vocabulary" \
  /bin/zsh -lc "rg -q 'keep-for-dogfood' '$REPORT' && rg -q 'keep-contract-migrate' '$REPORT' && rg -q 'rebuild-after-contracts|defer|cut' '$REPORT'"

check "report identifies current frontend route sources" \
  /bin/zsh -lc "rg -q 'src/App.tsx|AppLayout|/canopy|/sessions|/settings' '$REPORT'"

check "report identifies server API sources" \
  /bin/zsh -lc "rg -q 'server/index.ts|server/routes|/api/canopy|/api/hyphae|/api/status' '$REPORT'"

check "report identifies CLI or database dependencies" \
  /bin/zsh -lc "rg -q 'CLI|shell|subprocess|direct database|SQLite|DB dependency' '$REPORT'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0

