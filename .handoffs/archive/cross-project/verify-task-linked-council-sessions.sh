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

check "Canopy mentions council-session model or storage" \
  rg -q 'council.?session|CouncilSession' "$ROOT/canopy"

check "Cap mentions council timeline or roster UI" \
  rg -q 'council|roster|timeline' "$ROOT/cap/src"

check "Lamella mentions council role bundle or response convention" \
  rg -q 'council|reviewer|architect' "$ROOT/lamella"

check "Stipe mentions summon prerequisites or council checks" \
  rg -q 'summon|council|model availability|prerequisite' "$ROOT/stipe"

check "Hyphae mentions council artifacts or retrieval" \
  rg -q 'council' "$ROOT/hyphae"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
