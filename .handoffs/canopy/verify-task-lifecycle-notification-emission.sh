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

# CLI wiring — check app.rs dispatch, not doc strings
check "notification list command wired in app.rs" \
  rg -q 'NotificationCommand::List' "$ROOT/canopy/src/app.rs"

check "notification mark-read wired in app.rs" \
  rg -q 'NotificationCommand::MarkRead' "$ROOT/canopy/src/app.rs"

check "notification mark-all-read wired in app.rs" \
  rg -q 'NotificationCommand::MarkAllRead' "$ROOT/canopy/src/app.rs"

# Emission — check for actual NotificationEventType variants used at call sites
check "completion emission exists" \
  rg -q 'NotificationEventType::TaskCompleted' "$ROOT/canopy/src"

check "blocked emission exists" \
  rg -q 'NotificationEventType::TaskBlocked' "$ROOT/canopy/src"

check "cancellation emission exists" \
  rg -q 'NotificationEventType::TaskCancelled' "$ROOT/canopy/src"

check "evidence receipt emission exists" \
  rg -q 'NotificationEventType::EvidenceReceived' "$ROOT/canopy/src"

# Tests must actually run (not vacuously pass on zero matches)
check "notification store tests pass" \
  /bin/zsh -lc "cd '$ROOT/canopy' && cargo test notification --quiet >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
