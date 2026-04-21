#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

check "Rhizome mentions analyzer or plugin extension" \
  rg -q 'RepoSurfaceSummary|RepoSurfaceKind|RepoUnderstandingArtifact|export_repo_understanding' \
    "$ROOT/rhizome/crates"

check "Rhizome export tools exist" \
  test -f "$ROOT/rhizome/crates/rhizome-mcp/src/tools/export_tools.rs"

check "Rhizome exposes understanding export in CLI and MCP" \
  rg -q 'ExportUnderstanding|export_repo_understanding' \
    "$ROOT/rhizome/crates/rhizome-cli/src/main.rs" \
    "$ROOT/rhizome/crates/rhizome-mcp/src/tools/mod.rs" \
    "$ROOT/rhizome/crates/rhizome-mcp/src/server.rs" \
    "$ROOT/rhizome/crates/rhizome-mcp/src/tools/symbol_tools/onboard.rs"

check "Rhizome mentions incremental or cached update behavior" \
  rg -q 'UnderstandingUpdateClass|from_export_stats|update_class' \
    "$ROOT/rhizome/crates"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
