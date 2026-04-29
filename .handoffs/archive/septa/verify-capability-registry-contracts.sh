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

check "capability registry schema exists" \
  test -f "$ROOT/septa/capability-registry-v1.schema.json"

check "capability runtime lease schema exists" \
  test -f "$ROOT/septa/capability-runtime-lease-v1.schema.json"

check "capability fixtures exist" \
  /bin/zsh -lc "test -f '$ROOT/septa/fixtures/capability-registry-v1.example.json' && test -f '$ROOT/septa/fixtures/capability-runtime-lease-v1.example.json'"

check "canonical Septa validation passes" \
  /bin/zsh -lc "cd '$ROOT/septa' && bash validate-all.sh"

check "cross-tool payload registry checker passes" \
  /bin/zsh -lc "cd '$ROOT/septa' && bash scripts/check-cross-tool-payloads.sh"

check "inventory docs mention capability contracts" \
  /bin/zsh -lc "rg -q 'capability-registry-v1' '$ROOT/septa/README.md' '$ROOT/septa/CROSS-TOOL-PAYLOADS.md' && rg -q 'capability-runtime-lease-v1' '$ROOT/septa/README.md' '$ROOT/septa/CROSS-TOOL-PAYLOADS.md'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
