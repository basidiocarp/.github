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

run_check "validate" make validate
run_check "stale PLUGIN build example removed or implemented" sh -c "! rg -n 'make build PLUGIN=' README.md CLAUDE.md docs"
run_check "stale skill counts removed" sh -c "! rg -n '\\b(286|292) skills\\b' README.md docs"
run_check "marketplace builder is named correctly" sh -c "! rg -n 'build-claude-plugin\\.sh.*marketplace|updates the marketplace catalog' docs/architecture.md"
run_check "plugin-only hook paths are not shown as raw settings paths" sh -c "! rg -n '\\.claude/settings\\.json|CLAUDE_PLUGIN_ROOT' docs/authoring/hooks-authoring.md"
run_check "Codex generated-manifest path documented" sh -c "rg -n 'dist/generated/codex-manifests|build-codex' manifests/codex/README.md docs README.md"
run_check "count" make count

echo "Results: $pass passed, $fail failed"
test "$fail" -eq 0
