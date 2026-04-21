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

check "gemini format spec exists" \
  test -f "$ROOT/annulus/docs/providers/gemini.md"

check "format section present" \
  rg -q '^## Format' "$ROOT/annulus/docs/providers/gemini.md"

check "token-fields section present" \
  rg -q '^## Token fields' "$ROOT/annulus/docs/providers/gemini.md"

check "session-boundary section present" \
  rg -q '^## Session boundary' "$ROOT/annulus/docs/providers/gemini.md"

check "fixture directory exists" \
  test -d "$ROOT/annulus/tests/fixtures/gemini"

check "fixture README documents provenance" \
  test -f "$ROOT/annulus/tests/fixtures/gemini/README.md"

check "at least one fixture file present" \
  bash -c "ls '$ROOT/annulus/tests/fixtures/gemini/' | grep -v '^README.md$' | head -1 | grep -q ."

check "no source changes (research-only handoff)" \
  bash -c "cd '$ROOT/annulus' && git diff --quiet src/ 2>/dev/null && ! git status --porcelain src/ | grep -q ."

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
