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

run_check "docs validator" python3 scripts/validate-docs.py
run_check "no known broken foundation links" sh -c "! rg -n 'stipe/CLAUDE\\.md|/Users/williamnewton/' docs/foundations"
run_check "no missing active handoff links in docs" sh -c "! rg -n '\\.handoffs/(cross-project/orchestration-reset|canopy/|cap/|cortina/|hymenium/|hyphae/|lamella/|rhizome/|septa/|stipe/|volva/)[^ )]+\\.md' docs/workspace docs/research/orchestration"
run_check "troubleshooting shell pipes escaped in table commands" sh -c "! rg -n '\\|[^`]*\\|\\| true' docs/operate/troubleshooting.md"
run_check "root guidance does not name unavailable local skills" sh -c "! rg -n '\\b(writing-voice|tool-preferences|test-writing)\\b' AGENTS.md CLAUDE.md"

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
