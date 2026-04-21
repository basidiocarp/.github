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

ROOT="$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)"
cd "$ROOT"

# The broken generic loop is gone
check "generic check-jsonschema loop removed" \
  bash -c "! grep -Eq 'for schema in septa/\*.schema.json' scripts/test-integration.sh"

# The delegation to validate-all.sh is wired in
check "validate-all.sh delegation present" \
  grep -q "septa/validate-all.sh" scripts/test-integration.sh

# Integration script runs cleanly end-to-end (or has only explicitly documented failures)
script_fails=$(bash scripts/test-integration.sh 2>&1 | grep -Ec '^ *FAIL|^\x1b\[0;31mFAIL' || true)
if [ "$script_fails" -eq 0 ]; then
  echo "PASS: integration script reports 0 failures"
  PASS=$((PASS + 1))
else
  echo "FAIL: integration script reports $script_fails failure(s)"
  FAIL=$((FAIL + 1))
fi

# septa/validate-all.sh still passes (authoritative)
cd septa
check "septa/validate-all.sh authoritative pass" bash validate-all.sh
cd "$ROOT"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
