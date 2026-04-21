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
check "canonical source manifest exists" test -f skill-sync.toml -o -f scripts/sync-skills.sh
check "sync script exists" test -f scripts/sync-skills.sh
check "sync-check target in Makefile" grep -q "sync-check" Makefile

echo ""
echo "Results: $PASS passed, $FAIL failed"
