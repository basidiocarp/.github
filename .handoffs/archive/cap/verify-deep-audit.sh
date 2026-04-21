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

check "Deep audit follow-up handoffs exist" \
  test -f "$ROOT/.handoffs/archive/cap/auth-hardening.md" \
  && test -f "$ROOT/.handoffs/cap/config-write-validation.md" \
  && test -f "$ROOT/.handoffs/archive/cap/rhizome-project-boundary.md" \
  && test -f "$ROOT/.handoffs/cap/tooling-coverage.md" \
  && test -f "$ROOT/.handoffs/cap/canopy-performance.md" \
  && test -f "$ROOT/.handoffs/cap/app-layout-mobile-nav-a11y.md" \
  && test -f "$ROOT/.handoffs/cap/status-lifecycle-key-stability.md" \
  && test -f "$ROOT/.handoffs/cap/analytics-chart-sizing.md"
check "Deep audit findings document all steps" \
  rg -q "Step 1: Lint and Format Audit" "$ROOT/.handoffs/cap/deep-audit.md" \
  && rg -q "Step 9: Synthesize Findings" "$ROOT/.handoffs/cap/deep-audit.md"
check "Handoff index marks Deep Audit complete" \
  rg -q "\\[Deep Audit\\]\\(cap/deep-audit\\.md\\) \\| Complete" "$ROOT/.handoffs/HANDOFFS.md"
check "Handoff index lists new follow-up handoffs" \
  rg -q "Auth Hardening|Config Write Validation|Rhizome Project Boundary|Tooling Coverage|Canopy Performance|App Layout Mobile Nav Accessibility|Status Lifecycle Key Stability|Analytics Chart Sizing" "$ROOT/.handoffs/HANDOFFS.md"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
