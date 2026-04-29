#!/usr/bin/env bash

set -euo pipefail

PASS=0
FAIL=0

check_file() {
  local path="$1"
  if [ -f "$path" ]; then
    echo "PASS: file exists: $path"
    ((PASS++))
  else
    echo "FAIL: missing file: $path"
    ((FAIL++))
  fi
}

check_rg() {
  local pattern="$1"
  local path="$2"
  local label="$3"
  if rg -q "$pattern" "$path"; then
    echo "PASS: $label"
    ((PASS++))
  else
    echo "FAIL: $label"
    ((FAIL++))
  fi
}

check_file "hymenium/src/parser/markdown.rs"
check_rg "What needs doing|what needs doing|normalize|canonical" "hymenium/src/parser hymenium/tests" "parser handles canonical or normalized intent headings"
check_rg "MissingSection|accepted|expected|required section" "hymenium/src/parser hymenium/tests" "missing-section diagnostics are covered"
check_rg "read-only|artifact|write scope|artifact write" "hymenium/src hymenium/tests" "read-only audit artifact scope is represented or tested"
check_rg "centralcommand|drop-shipping|audit-drop-shipping|handoff_intake" "hymenium/tests hymenium/src" "dogfood handoff fixture or intake test exists"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

