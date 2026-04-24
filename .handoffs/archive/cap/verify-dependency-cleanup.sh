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

check "zustand is in dependencies" \
  bash -c "grep -q '\"zustand\"' '$ROOT/cap/package.json' && grep -A 30 '\"dependencies\"' '$ROOT/cap/package.json' | grep -q '\"zustand\"'"

check "@mantine/tiptap not in package.json" \
  bash -c "! grep -q '\"@mantine/tiptap\"' '$ROOT/cap/package.json'"

check "@tiptap/extension-link not in package.json" \
  bash -c "! grep -q '\"@tiptap/extension-link\"' '$ROOT/cap/package.json'"

check "@tiptap/pm not in package.json" \
  bash -c "! grep -q '\"@tiptap/pm\"' '$ROOT/cap/package.json'"

check "@tiptap/react not in package.json" \
  bash -c "! grep -q '\"@tiptap/react\"' '$ROOT/cap/package.json'"

check "@tiptap/starter-kit not in package.json" \
  bash -c "! grep -q '\"@tiptap/starter-kit\"' '$ROOT/cap/package.json'"

check "@mantine/spotlight not in package.json" \
  bash -c "! grep -q '\"@mantine/spotlight\"' '$ROOT/cap/package.json'"

check "build succeeds" \
  /bin/zsh -lc "cd '$ROOT/cap' && npm run build >/dev/null 2>&1"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
