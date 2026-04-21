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

check "notification migration exists" \
  rg -q 'notifications \(|CREATE TABLE IF NOT EXISTS notifications' "$ROOT/canopy"

check "notification event enum exists" \
  rg -q 'NotificationEventType|TaskComplete|EvidenceReceived' "$ROOT/canopy/src"

check "cargo notification tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test notification --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
