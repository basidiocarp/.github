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

check "backup has structured outcome" \
  rg -q 'BackupOutcome|BackupResult|Partial|failed|missing' "$ROOT/stipe/src/backup.rs" "$ROOT/stipe/src/commands/backup.rs"

check "backup tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test backup >/dev/null"

check "install tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test install >/dev/null"

check "init tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test init >/dev/null"

check "excessive bool suppressions removed from target seams" \
  /bin/zsh -lc "! rg -q 'fn_params_excessive_bools' '$ROOT/stipe/src/commands/install/runner.rs' '$ROOT/stipe/src/commands/init.rs'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
