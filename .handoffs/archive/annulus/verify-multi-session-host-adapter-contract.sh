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

# check_any: pass if any of the given commands succeed
check_any() {
  local label="$1"; shift
  for cmd in "$@"; do
    if eval "$cmd" >/dev/null 2>&1; then
      echo "PASS: $label"
      PASS=$((PASS + 1))
      return
    fi
  done
  echo "FAIL: $label"
  FAIL=$((FAIL + 1))
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/annulus" 2>/dev/null || {
  echo "FAIL: could not find annulus repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check_any "stdin JSON schema documented" \
  "grep -q session_path README.md" \
  "grep -rq session_path docs/"

check_any "provider field documented" \
  "grep -q provider README.md" \
  "grep -rq '\"provider\"' docs/"

check_any "codex hook example" \
  "grep -q codex docs/multi-session.md" \
  "grep -rq codex README.md"

check_any "gemini hook example" \
  "grep -q gemini docs/multi-session.md" \
  "grep -rq gemini README.md"

check_any "precedence chain documented" \
  "grep -rq precedence docs/" \
  "grep -rq priority docs/" \
  "grep -rq override docs/"

echo ""
echo "Results: $PASS passed, $FAIL failed"
