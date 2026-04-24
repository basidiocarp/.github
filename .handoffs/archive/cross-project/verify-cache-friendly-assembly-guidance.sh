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

check "cache-friendly assembly doc exists" \
  test -f "$ROOT/docs/foundations/cache-friendly-assembly.md"

check "assembly order documented with L0" \
  rg -q 'L0.*Global User Rules' "$ROOT/docs/foundations/cache-friendly-assembly.md"

check "assembly order documented with L1" \
  rg -q 'L1.*Workspace Root' "$ROOT/docs/foundations/cache-friendly-assembly.md"

check "assembly order documented with L2" \
  rg -q 'L2.*Project' "$ROOT/docs/foundations/cache-friendly-assembly.md"

check "assembly order documented with L3" \
  rg -q 'L3.*Directory' "$ROOT/docs/foundations/cache-friendly-assembly.md"

check "cache behavior is documented" \
  rg -q 'Cache behavior|cache hit|cache miss|TTL|5 minute' "$ROOT/docs/foundations/cache-friendly-assembly.md"

check "anti-patterns section exists" \
  rg -q -i 'anti-pattern' "$ROOT/docs/foundations/cache-friendly-assembly.md"

check "specific anti-patterns documented" \
  rg -q 'Volatile Content Before Stable|Mixing Stable and Dynamic|Large Volatile Blocks|Fetching External Content|Putting Stable Rules After' "$ROOT/docs/foundations/cache-friendly-assembly.md"

check "cross-reference to instruction-loading.md exists" \
  rg -q 'instruction-loading\.md' "$ROOT/docs/foundations/cache-friendly-assembly.md"

check "Anthropic prompt cache constraints documented" \
  rg -q 'Anthropic Prompt Cache Constraints' "$ROOT/docs/foundations/cache-friendly-assembly.md"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
