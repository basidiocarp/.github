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

check "Rhizome MCP root/write boundary tests exist" \
  bash -lc "rg -n 'root_override|write_boundary|configured.*root|escape' '$ROOT/rhizome/crates/rhizome-mcp' '$ROOT/rhizome/tests'"
check "installer subprocesses have timeout or bounded runner" \
  bash -lc "rg -n 'timeout|wait_timeout|kill|spawn' '$ROOT/rhizome/crates/rhizome-core/src/installer.rs'"
check "backend selector does not auto-install from probe path" \
  bash -lc "! rg -n 'install.*\\(' '$ROOT/rhizome/crates/rhizome-core/src/backend_selector.rs'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
