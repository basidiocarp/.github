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

check "benchmarks fixtures directory exists" \
  test -d "$ROOT/hyphae/benchmarks/fixtures"

check "at least 3 fixture files exist" \
  bash -c "[ \$(ls '$ROOT/hyphae/benchmarks/fixtures/'*.json 2>/dev/null | wc -l) -ge 3 ]"

check "cmd_bench_retrieval function exists" \
  bash -c "grep -q 'cmd_bench_retrieval' '$ROOT/hyphae/crates/hyphae-cli/src/commands/bench.rs'"

check "BenchRetrieval CLI variant wired" \
  bash -c "grep -q 'BenchRetrieval\|bench.retrieval\|bench-retrieval' '$ROOT/hyphae/crates/hyphae-cli/src/main.rs'"

check "benchmarks README exists" \
  test -f "$ROOT/hyphae/benchmarks/README.md"

check "hyphae-cli tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test -p hyphae-cli --quiet 2>&1 | grep -qv 'FAILED'"

check "workspace builds" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo build --workspace --quiet 2>&1"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
