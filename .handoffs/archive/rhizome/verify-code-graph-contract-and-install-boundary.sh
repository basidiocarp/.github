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

check "graph avoids zero line metadata" \
  /bin/zsh -lc "! rg -q 'line_(start|end).*\"0\"|\"0\".*line_(start|end)' '$ROOT/rhizome/crates/rhizome-core/src/graph.rs'"

check "graph tests pass" \
  /bin/zsh -lc "cd '$ROOT/rhizome' && cargo test -p rhizome-core graph >/dev/null"

check "hyphae export tests pass" \
  /bin/zsh -lc "cd '$ROOT/rhizome' && cargo test -p rhizome-core hyphae >/dev/null"

check "backend probe does not ensure install from selector" \
  /bin/zsh -lc "! rg -q 'ensure_server|install' '$ROOT/rhizome/crates/rhizome-core/src/backend_selector.rs'"

check "code graph fixture validates" \
  /bin/zsh -lc "cd '$ROOT/septa' && check-jsonschema --schemafile code-graph-v1.schema.json fixtures/code-graph-v1.example.json >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
