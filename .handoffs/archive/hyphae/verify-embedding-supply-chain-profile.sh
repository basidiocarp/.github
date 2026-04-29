#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root/hyphae"

pass=0
fail=0

run_check() {
  local name="$1"
  shift
  echo "==> $name"
  if "$@"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
  fi
}

run_check "fastembed dependency graph" cargo tree -i fastembed --locked
run_check "ort-sys dependency graph" cargo tree -i ort-sys --locked
run_check "no default features build" cargo build --no-default-features
run_check "no default features tests" cargo test --no-default-features

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
