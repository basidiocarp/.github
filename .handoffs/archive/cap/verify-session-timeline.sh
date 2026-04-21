#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

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

ROOT="/Users/williamnewton/projects/basidiocarp"
CAP="$ROOT/cap"

check "Exact per-session timeline route exists" \
  rg -q "app\\.get\\('/:id/timeline'" "$CAP/server/routes/sessions.ts"
check "Per-session timeline route is mounted under /api/sessions" \
  rg -q "app\\.route\\('/api/sessions', sessionsRoutes\\)" "$CAP/server/index.ts"
check "Sessions page exposes a selected-session detail modal" \
  rg -q "SessionDetailModal" "$CAP/src/pages/sessions/SessionsPage.tsx"
check "Session detail modal renders activity rows" \
  rg -q "SessionEventRow" "$CAP/src/pages/sessions/SessionDetailModal.tsx"
check "Sessions tests cover drilldown and empty-state behavior" \
  rg -q "opens a session detail drilldown with the full event and command trace|preserves count-only error payloads in the session drilldown" "$CAP/src/pages/Sessions.test.tsx"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
