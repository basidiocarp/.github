#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    ((PASS++))
  else
    echo "FAIL: $label"
    ((FAIL++))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/stipe" 2>/dev/null || {
  echo "FAIL: could not find stipe repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings

# Step 1: MCP server health checks
check "MCP check code present" grep -rq "mcp\|MCP" src/
check "hyphae check present" grep -rq "hyphae" src/
check "rhizome check present" grep -rq "rhizome" src/
check "timeout enforced" grep -rq "timeout\|Duration\|time_limit" src/

# Step 2: Provider and API key checks
check "ANTHROPIC_API_KEY check present" grep -rq "ANTHROPIC_API_KEY\|anthropic.*key\|api.*key" src/
check "no secret logging (no plaintext key echo)" bash -c "! grep -rq 'println.*API_KEY\|eprintln.*API_KEY' src/"

# Step 3: Plugin and hook inventory
check "plugin or hook inventory present" grep -rq "plugin\|hook.*inventory\|inventory\|lamella" src/
check "version drift check present" grep -rq "version.*drift\|drift\|up.to.date\|behind\|ecosystem.versions\|pinned" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
