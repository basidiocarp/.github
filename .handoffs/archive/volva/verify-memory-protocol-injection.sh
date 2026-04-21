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

check "volva memory protocol injection exists" rg -q 'hyphae-memory-protocol|hyphae_gather_context|hyphae://protocol/current' "$ROOT/volva/crates/volva-runtime/src/context.rs"
check "volva context tests cover memory protocol injection" rg -q 'assemble_prompt_includes_hyphae_memory_protocol_block_when_available|hyphae_memory_protocol_block_is_concise_and_project_aware' "$ROOT/volva/crates/volva-runtime/src/context.rs"
check "volva verifier targets real crate layout" test -d "$ROOT/volva/crates/volva-runtime/src"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
