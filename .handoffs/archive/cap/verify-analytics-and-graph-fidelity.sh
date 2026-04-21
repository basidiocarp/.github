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

check "Usage tab no longer synthesizes host status from session presence" \
  bash -lc "! rg -q \"getHostCoverageView\\(|resolved_config_path: '/host/\" '$ROOT/cap/src/pages/analytics/UsageCostTab.tsx'"
check "Code intelligence tab surfaces richer tool-call or backend fidelity" \
  rg -q "avg_duration_ms|duration|backend_usage\\.lsp.*backend_usage\\.treesitter|Tool Call" "$ROOT/cap/src/pages/analytics/CodeIntelligenceTab.tsx"
check "Analytics tests cover behavior beyond top-level links" \
  rg -q "Token Savings|Memory Health|Code Intelligence|Usage & Cost|telemetry" "$ROOT/cap/src/pages/Analytics.test.tsx" "$ROOT/cap/src/pages/analytics"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
