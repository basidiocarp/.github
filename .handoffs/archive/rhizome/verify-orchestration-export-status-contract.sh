#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
HANDOFF="$ROOT/.handoffs/archive/rhizome/orchestration-export-status-contract.md"

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

check "Handoff defines machine-facing export status intent" \
  rg -q 'machine-facing status|partial success|cached reuse|trust signal' "$HANDOFF"

check "Handoff includes repo_understanding step" \
  rg -q 'repo_understanding\.rs' "$HANDOFF"

check "Handoff includes export surface step" \
  rg -q 'export_tools\.rs|CLI and MCP export surfaces' "$HANDOFF"

check "Handoff includes orchestration semantics docs step" \
  rg -q 'orchestration guidance|display-only labels' "$HANDOFF"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
