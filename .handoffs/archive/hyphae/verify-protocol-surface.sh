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

check "hyphae protocol surface exists" rg -q 'hyphae protocol|Protocol' "$ROOT/hyphae"
check "hyphae protocol emits versioned project-aware json" /bin/zsh -lc "cd '$ROOT/hyphae' && cargo run --quiet -- protocol --project demo | rg -q '\"schema_version\": \"1.0\"|\"project_topics\": \\['"
check "hyphae MCP protocol resource exists" rg -q 'hyphae://protocol/current' "$ROOT/hyphae/crates/hyphae-mcp/src"
check "hyphae tests pass" /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test --workspace >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
