#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root/stipe"

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

run_check "install tests" cargo test install
run_check "self-update tests" cargo test self_update
run_check "release install tests" cargo test install::release

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
