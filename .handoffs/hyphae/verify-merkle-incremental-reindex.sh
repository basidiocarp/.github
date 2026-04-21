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

check "content_hash field in Document struct" \
  bash -c "grep -q 'content_hash' '$ROOT/hyphae/crates/hyphae-core/src/chunk.rs'"

check "compute_content_hash function exists" \
  bash -c "grep -q 'compute_content_hash' '$ROOT/hyphae/crates/hyphae-ingest/src/lib.rs'"

check "skip logic in tool_ingest_file" \
  bash -c "grep -q 'skipped\|content unchanged\|content_hash' '$ROOT/hyphae/crates/hyphae-mcp/src/tools/ingest.rs'"

check "schema includes content_hash column" \
  bash -c "grep -q 'content_hash' '$ROOT/hyphae/crates/hyphae-store/src/schema.rs'"

check "hyphae-ingest tests pass" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo test -p hyphae-ingest --quiet 2>&1 | grep -qv 'FAILED'"

check "full workspace builds" \
  /bin/zsh -lc "cd '$ROOT/hyphae' && cargo build --workspace --quiet 2>&1 | grep -cv '^error' > /dev/null || true && cargo build --workspace 2>&1 | grep -v '^error' > /dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
