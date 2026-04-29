#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root/cap"

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

run_check "no unqualified npx in package scripts or release script" sh -c "! rg -n '\\bnpx\\b' package.json scripts/release.sh"
run_check "build" npm run build
run_check "tests" npm test

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
