#!/usr/bin/env bash
set -euo pipefail

root="/Users/williamnewton/projects/basidiocarp"
repo="$root/stipe"

pass_count=0

check() {
  local description="$1"
  local command="$2"
  if eval "$command" >/dev/null 2>&1; then
    printf 'PASS: %s\n' "$description"
    pass_count=$((pass_count + 1))
  else
    printf 'FAIL: %s\n' "$description"
    exit 1
  fi
}

check "tool registry includes a volva spec" \
  "rg -n 'name:\\s*\"volva\"' '$repo/src/commands/tool_registry/specs.rs'"

check "probe path maps volva through spore" \
  "rg -n '^\\s*\"volva\"\\s*=>\\s*Some\\(Tool::Volva\\),' '$repo/src/commands/tool_registry/probe.rs'"

check "tool registry tests mention volva expectations" \
  "rg -n 'volva' '$repo/src/commands/tool_registry/tests.rs'"

printf 'Results: %d passed, 0 failed\n' "$pass_count"
