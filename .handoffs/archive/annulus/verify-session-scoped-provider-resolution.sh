#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/annulus" 2>/dev/null || {
  echo "FAIL: could not find annulus repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "cargo check" cargo check
check "cargo test" cargo test
check "cargo clippy" cargo clippy -- -D warnings
check "StatuslineInput has provider field" grep -rq "provider.*Option.*String\|session_path.*Option.*String" src/statusline.rs
check "CodexProvider session_file support" grep -rq "session_file\|with_session_file" src/providers/codex.rs
check "GeminiProvider session_file support" grep -rq "session_file\|with_session_file" src/providers/gemini.rs
check "statusline_view uses stdin provider" grep -rq "input\.provider\|input_provider" src/statusline.rs
check "multi-session test exists" grep -rq "session.*scop\|multi.*session\|session_path" tests/ 2>/dev/null || grep -rq "session.*scop\|multi.*session\|session_path" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
