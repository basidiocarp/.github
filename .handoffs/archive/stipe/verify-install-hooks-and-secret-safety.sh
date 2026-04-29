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

check "lockfile uses atomic create and owner-scoped release" \
  bash -lc "rg -n 'create_new|OpenOptions|pid|token|owner' '$ROOT/stipe/src/lockfile.rs'"
check "install/repair subprocess paths are bounded" \
  bash -lc "rg -n 'timeout|wait_timeout|kill|deadline' '$ROOT/stipe/src/commands/install' '$ROOT/stipe/src/commands/package_repair.rs'"
check "provider setup protects plaintext secrets" \
  bash -lc "rg -n '0600|set_permissions|gitignore|keychain|explicit|opt' '$ROOT/stipe/src/commands/provider.rs'"
check "Claude hook settings cover lifecycle policy" \
  bash -lc "rg -n 'PreToolUse|SessionEnd|Stop|timeout|matcher' '$ROOT/stipe/src/commands/claude_hooks.rs'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
