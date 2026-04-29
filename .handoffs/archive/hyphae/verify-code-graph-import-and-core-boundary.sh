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

check "import graph tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test -p hyphae-mcp import_code_graph >/dev/null"

check "relation validation is explicit" \
  rg -q 'relation.*(match|enum|allowed|validate)|validate_.*relation|unknown.*relation' "$ROOT/hyphae/crates/hyphae-mcp/src/tools/memoir.rs" "$ROOT/hyphae/crates/hyphae-mcp/src/tools/schema.rs"

check "weight validation is explicit" \
  rg -q 'weight.*0\\.0|weight.*1\\.0|validate_.*weight|out of range' "$ROOT/hyphae/crates/hyphae-mcp/src/tools/memoir.rs" "$ROOT/hyphae/crates/hyphae-mcp/src/tools/schema.rs"

check "identity fields are handled" \
  rg -q 'worktree_id|project_root' "$ROOT/hyphae/crates/hyphae-mcp/src" "$ROOT/hyphae/crates/hyphae-store/src" "$ROOT/hyphae/tests"

check "path truncation is not byte slicing" \
  /bin/zsh -lc "! rg -q '\\[[0-9]+\\.\\.\\]|\\.len\\(\\) - [0-9]+' '$ROOT/hyphae/crates/hyphae-mcp/src/tools/ingest.rs'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
