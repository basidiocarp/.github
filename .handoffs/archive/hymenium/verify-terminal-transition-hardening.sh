#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/hymenium" 2>/dev/null || {
  echo "FAIL: could not find hymenium repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy -D warnings" cargo clippy -- -D warnings
check "cargo fmt --check" cargo fmt --check

# Step 1: current_phase_idx persisted as integer column (not just named in a comment)
check "current_phase_idx referenced in store" grep -q "current_phase_idx" src/store.rs
# At least one SELECT/UPDATE/INSERT or ensure_column reference, proving it's persisted
check "current_phase_idx in SQL or schema evolution" \
  bash -c "grep -Eq 'SELECT[^;]*current_phase_idx|UPDATE[^;]*current_phase_idx|current_phase_idx[^;]*INTEGER|ensure_column[^)]*current_phase_idx' src/store.rs"
check "heuristic scan removed" bash -c "! grep -q 'rposition.*Completed' src/store.rs"

# Step 2: default-path stderr warning
check "default_path warning" grep -q "eprintln" src/store.rs

# Step 3: i64 clamp replaced
check "no silent i64 clamp" bash -c "! grep -q 'unwrap_or(i64::MAX)' src/store.rs"

# Step 4: Duration::MAX fallback replaced
check "no silent Duration::MAX" bash -c "! grep -q 'unwrap_or(chrono::Duration::MAX)' src/monitor/"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
