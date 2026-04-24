#!/usr/bin/env bash
set -euo pipefail
PASS=0; FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

check() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"; FAIL=$((FAIL + 1))
  fi
}

# Verify files exist
check "mycelium README exists" test -f "$ROOT/mycelium/README.md"
check "hyphae README exists" test -f "$ROOT/hyphae/README.md"
check "hyphae cli-reference exists" test -f "$ROOT/hyphae/docs/cli-reference.md"
check "hyphae guide exists" test -f "$ROOT/hyphae/docs/guide.md"

# Verify builds
check "mycelium builds" /bin/zsh -lc "cd '$ROOT/mycelium' && cargo build --release --quiet 2>&1"
check "hyphae builds" /bin/zsh -lc "cd '$ROOT/hyphae' && cargo build --release --quiet 2>&1"

# Verify docs don't reference removed/renamed commands
check "cli-reference doesn't reference hyphae recall" \
  bash -c "! grep -q 'hyphae recall' '$ROOT/hyphae/docs/cli-reference.md'"

check "cli-reference references hyphae search" \
  bash -c "grep -q 'hyphae search' '$ROOT/hyphae/docs/cli-reference.md'"

check "cli-reference doesn't reference hyphae list" \
  bash -c "! grep -q '^### \`hyphae list\`' '$ROOT/hyphae/docs/cli-reference.md'"

check "cli-reference references hyphae memory" \
  bash -c "grep -q 'hyphae memory' '$ROOT/hyphae/docs/cli-reference.md'"

check "cli-reference doesn't reference hyphae decay command" \
  bash -c "! grep -q '### \`hyphae decay\`' '$ROOT/hyphae/docs/cli-reference.md'"

check "cli-reference references bench-retrieval not bench-recall" \
  bash -c "grep -q 'hyphae bench-retrieval' '$ROOT/hyphae/docs/cli-reference.md' && ! grep -q 'hyphae bench-recall' '$ROOT/hyphae/docs/cli-reference.md'"

check "guide doesn't reference hyphae recall" \
  bash -c "! grep -q 'hyphae recall' '$ROOT/hyphae/docs/guide.md'"

check "guide references hyphae search" \
  bash -c "grep -q 'hyphae search' '$ROOT/hyphae/docs/guide.md'"

check "README references bench-retrieval" \
  bash -c "grep -q 'bench-retrieval' '$ROOT/hyphae/README.md'"

printf '\nResults: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
