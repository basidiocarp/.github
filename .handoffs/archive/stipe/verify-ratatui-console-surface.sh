#!/usr/bin/env bash
set -euo pipefail

pass_count=0
fail_count=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "PASS: file exists - $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: missing file - $path"
    fail_count=$((fail_count + 1))
  fi
}

check_grep() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    echo "PASS: pattern '$pattern' found in $path"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: pattern '$pattern' missing in $path"
    fail_count=$((fail_count + 1))
  fi
}

HANDOFF=".handoffs/archive/stipe/ratatui-console-surface.md"

check_file "$HANDOFF"
check_grep "ratatui" "$HANDOFF"
check_grep "dialoguer" "$HANDOFF"
check_grep "indicatif" "$HANDOFF"
check_grep "\[x\] one bounded operator flow is selected|\[ \] one bounded operator flow is selected" "$HANDOFF"
check_grep "\[x\] ratatui adoption is either implemented in one bounded slice or explicitly rejected|\[ \] ratatui adoption is either implemented in one bounded slice or explicitly rejected" "$HANDOFF"

echo "Results: ${pass_count} passed, ${fail_count} failed"
if [[ "$fail_count" -ne 0 ]]; then
  exit 1
fi
