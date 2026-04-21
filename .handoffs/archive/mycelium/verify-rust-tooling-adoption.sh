#!/usr/bin/env bash
set -euo pipefail

pass=0
fail=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "PASS: file exists - $path"
    pass=$((pass + 1))
  else
    echo "FAIL: missing file - $path"
    fail=$((fail + 1))
  fi
}

check_grep() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    echo "PASS: pattern '$pattern' found in $path"
    pass=$((pass + 1))
  else
    echo "FAIL: pattern '$pattern' missing in $path"
    fail=$((fail + 1))
  fi
}

HANDOFF=".handoffs/archive/mycelium/rust-tooling-adoption.md"

check_file "$HANDOFF"
check_file "mycelium/benches/tooling_hot_paths.rs"
check_grep "cargo-nextest" "$HANDOFF"
check_grep "Criterion" "$HANDOFF"
check_grep "whole-command timing" "$HANDOFF"
check_grep "tooling_hot_paths" "$HANDOFF"
check_grep "mycelium cargo nextest" "mycelium/docs/commands.md"
check_grep "end-to-end timing" "mycelium/docs/test-exec-time.md"
check_grep "criterion = \"0.5\"" "mycelium/Cargo.toml"
check_grep 'name = "tooling_hot_paths"' "mycelium/Cargo.toml"

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
