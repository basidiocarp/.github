#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

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

run_check "CLI help renders" sh -c "cd hymenium && cargo run -- --help >/tmp/hymenium-help.txt"
run_check "docs do not advertise removed commands" sh -c "! rg -n 'hymenium (run|serve|retry)\\b|\\b(run|serve|retry)\\b.*hymenium' hymenium/README.md hymenium/AGENTS.md hymenium/CLAUDE.md"
run_check "MCP server claims are not shipped-usage claims" sh -c "! rg -n 'CLI and MCP server|hymenium serve|MCP server' hymenium/README.md hymenium/AGENTS.md hymenium/CLAUDE.md"
run_check "stale flat module paths removed" sh -c "! rg -n 'src/(dispatch|monitor)\\.rs' hymenium/README.md hymenium/AGENTS.md hymenium/CLAUDE.md"
run_check "tests" sh -c "cd hymenium && cargo test"

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
