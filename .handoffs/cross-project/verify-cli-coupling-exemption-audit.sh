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

check "foundation standard defines CLI fallback rules" \
  /bin/zsh -lc "rg -q 'CLI fallback|compatibility shim|replacement handoff|system-to-system' '$ROOT/docs/foundations/inter-app-communication.md'"

check "integration inventory classifies CLI coupling" \
  /bin/zsh -lc "rg -q 'CLI.*exception|operator surface|compatibility debt|replacement handoff|hook-time exception' '$ROOT/septa/integration-patterns.md'"

check "active handoffs include typed endpoint replacements" \
  /bin/zsh -lc "rg -q 'Dispatch Request Service Endpoint|Capability Dispatch Client|Local Service Endpoint Contracts|Local Service Transport Primitives' '$ROOT/.handoffs/HANDOFFS.md'"

check "source scan finds process spawning for audit review" \
  /bin/zsh -lc "rg -n 'Command::new|std::process::Command|tokio::process::Command' '$ROOT' -g 'src/**' -g 'tests/**' >/dev/null"

check "verify script documents sibling tool names for future scan hardening" \
  /bin/zsh -lc "rg -q 'mycelium|hyphae|rhizome|canopy|hymenium|stipe|cortina|spore|annulus|volva' '$ROOT/.handoffs/cross-project/verify-cli-coupling-exemption-audit.sh' '$ROOT/septa/integration-patterns.md'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0

