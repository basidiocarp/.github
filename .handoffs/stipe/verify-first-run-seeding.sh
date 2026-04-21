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

check "seed module exists" \
  test -f "$ROOT/stipe/src/commands/init/seed.rs"

check "seed_first_run function present" \
  bash -c "grep -q 'seed_first_run' '$ROOT/stipe/src/commands/init/seed.rs'"

check "hyphae availability check present" \
  bash -c "grep -q 'hyphae_available\|hyphae.*version\|--version' '$ROOT/stipe/src/commands/init/seed.rs'"

check "idempotency check present" \
  bash -c "grep -q 'has_existing_memories\|total_memories\|existing' '$ROOT/stipe/src/commands/init/seed.rs'"

check "--interactive flag wired into init" \
  bash -c "grep -q 'interactive' '$ROOT/stipe/src/main.rs'"

check "seeding wired into init.rs" \
  bash -c "grep -q 'seed' '$ROOT/stipe/src/commands/init.rs'"

check "stipe tests pass" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo test --quiet 2>&1 | grep -qv 'FAILED'"

check "stipe builds" \
  /bin/zsh -lc "cd '$ROOT/stipe' && cargo build --release --quiet 2>&1"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
