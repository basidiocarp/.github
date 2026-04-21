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

check "Doctor model mentions provider health" \
  rg -q 'ProviderHealth|provider health|provider_status' "$ROOT/stipe/src/commands/doctor"

check "Doctor model mentions MCP health" \
  rg -q 'McpHealth|mcp health|mcp_status' "$ROOT/stipe/src/commands/doctor"

check "Doctor code mentions plugin or package inventory" \
  rg -q 'plugin|package inventory|installed packages' "$ROOT/stipe/src/commands/doctor" "$ROOT/stipe/src/ecosystem"

check "Doctor code mentions worktree config discovery" \
  rg -q 'worktree' "$ROOT/stipe/src/commands/doctor" "$ROOT/stipe/src/ecosystem"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
