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

HANDOFF=".handoffs/archive/spore/rust-tooling-adoption.md"

check_file "$HANDOFF"
check_grep "cargo-nextest" "$HANDOFF"
check_grep "criterion" "$HANDOFF"
check_grep "timing fallback" "$HANDOFF"
check_grep "docs-only pass" "$HANDOFF"
check_grep "cargo nextest run" "spore/README.md"
check_grep "criterion.*out of scope" "spore/README.md"

echo "Results: $pass passed, $fail failed"
if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
