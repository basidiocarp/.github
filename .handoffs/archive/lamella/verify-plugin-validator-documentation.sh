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
check "plugin validator reference doc exists" test -f docs/plugin-validator-reference.md
check "file path constraint documented" grep -q "file path\|directory path\|explicit.*path" docs/plugin-validator-reference.md
check "hooks field behavior documented" grep -q "hooks\|hook" docs/plugin-validator-reference.md
check "known-good example present" grep -qi "known.good\|known good" docs/plugin-validator-reference.md
check "known-bad example present" grep -qi "known.bad\|known bad" docs/plugin-validator-reference.md
check "reference listed in docs index" grep -rq "plugin-validator" docs/

echo ""
echo "Results: $PASS passed, $FAIL failed"
