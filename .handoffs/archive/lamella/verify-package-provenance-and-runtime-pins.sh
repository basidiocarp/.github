#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root/lamella"

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

run_check "marketplace catalog validation" node scripts/ci/validate-marketplace-catalog.js
run_check "manifest validation" node scripts/ci/validate-manifests.js
run_check "skill package validation" node scripts/ci/validate-skill-packages.js
run_check "no installable mutable package specs" sh -c "! rg -n '@latest|npx -y|pnpm dlx|yarn dlx|bunx' resources/mcp-configs resources/hooks/settings.json"
run_check "provenance handoff exists" rg -n "provenance|NOTICE|license" .handoffs/lamella/package-provenance-and-runtime-pins.md

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
