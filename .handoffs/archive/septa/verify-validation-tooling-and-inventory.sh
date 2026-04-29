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

check "canonical Septa validation passes" \
  bash -lc "cd '$ROOT/septa' && bash validate-all.sh"
check "cross-tool payload registry checker passes" \
  bash -lc "cd '$ROOT/septa' && bash scripts/check-cross-tool-payloads.sh"
check "variant fixtures are visible to validation tooling" \
  bash -lc "rg -n 'full|degraded|flagged|find|fixtures' '$ROOT/septa/validate-all.sh' '$ROOT/septa/scripts'"
check "contract inventory docs mention recently missing schemas" \
  bash -lc "rg -n 'annulus-statusline-v1|context-envelope-v1|credential-v1|dependency-types-v1|task-output-v1' '$ROOT/septa/README.md' '$ROOT/septa/CROSS-TOOL-PAYLOADS.md' '$ROOT/ecosystem-versions.toml'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
