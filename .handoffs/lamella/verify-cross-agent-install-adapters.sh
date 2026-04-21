#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    ((PASS++))
  else
    echo "FAIL: $label"
    ((FAIL++))
  fi
}

cd "$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)/lamella" 2>/dev/null || {
  echo "FAIL: could not find lamella repo"
  echo "Results: 0 passed, 1 failed"
  exit 1
}

check "make validate" make validate
check "adapters directory exists" test -d scripts/adapters
check "adapter interface documented" test -f scripts/adapters/README.md
check "codex adapter exists" find scripts/adapters -name "*codex*" -type f | grep -q .
check "cursor adapter exists" find scripts/adapters -name "*cursor*" -type f | grep -q .
check "gemini adapter exists" find scripts/adapters -name "*gemini*" -type f | grep -q .
check "platform ownership guard present" grep -rq "PLATFORM\|ownership\|guard" scripts/adapters/
check "build-marketplace invokes adapters" grep -q "adapters\|adapter" Makefile

echo ""
echo "Results: $PASS passed, $FAIL failed"
