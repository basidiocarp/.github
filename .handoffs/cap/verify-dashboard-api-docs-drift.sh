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

run_check "removed file references are gone" sh -c "! rg -n 'server/db\\.ts|src/lib/queries\\.ts|src/lib/api\\.ts' docs README.md"
run_check "known mounted namespaces are documented" sh -c "rg -n '/api/(cost|ecosystem|sessions|watchers|health|client-config)' docs/api.md README.md docs/getting-started.md"
run_check "known app routes are documented" sh -c "rg -n '/(sessions|lessons|canopy|settings)' README.md docs/getting-started.md docs/internals.md"
run_check "stale UI claims are gone" sh -c "! rg -n '1-5 hops|install/uninstall|manual restart|syntax highlighting' docs/getting-started.md README.md"
run_check "build" npm run build
run_check "tests" npm test

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
