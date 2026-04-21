#!/usr/bin/env bash
set -euo pipefail
handoff=".handoffs/archive/cortina/compile-info-optimization.md"
pass=0
fail=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    pass=$((pass + 1))
  else
    echo "FAIL: missing file - $path"
    fail=$((fail + 1))
  fi
}

check_grep() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    pass=$((pass + 1))
  else
    echo "FAIL: missing pattern '$pattern' in $path"
    fail=$((fail + 1))
  fi
}

check_absent() {
  local pattern="$1"
  local path="$2"
  if rg -q "$pattern" "$path"; then
    echo "FAIL: unexpected pattern '$pattern' still present in $path"
    fail=$((fail + 1))
  else
    pass=$((pass + 1))
  fi
}

check_file "$handoff"
check_grep "from the system on non-Windows targets" "$handoff"
check_grep "regex-free now" "$handoff"
check_grep "logging remains shared and intentional" "$handoff"
check_grep "This handoff is complete under the current scope" "$handoff"
check_grep "non_zero_exit" "$handoff"
check_grep "is_significant_command" "$handoff"
check_grep "regex-automata" "$handoff"
check_grep "Cortina links SQLite from the system on non-Windows targets" "cortina/README.md"
check_grep "Command classification stays regex-free" "cortina/README.md"
check_grep "cfg\\(windows\\)" "cortina/Cargo.toml"
check_grep 'features = \["bundled"\]' "cortina/Cargo.toml"
check_grep "cfg\\(not\\(windows\\)\\)" "cortina/Cargo.toml"
check_absent 'regex = "1"' "cortina/Cargo.toml"
check_absent 'use regex::Regex' "cortina/src/utils/command_signals.rs"

echo "Results: $pass passed, $fail failed"
exit "$fail"
