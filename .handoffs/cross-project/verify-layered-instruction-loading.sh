#!/usr/bin/env bash
set -e

PASS=0
FAIL=0

check() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $label"
    ((PASS++))
    return 0
  else
    echo "FAIL: $label"
    ((FAIL++))
    return 1
  fi
}

ROOT="/Users/williamnewton/projects/basidiocarp"

check "instruction loading doc exists" test -f "$ROOT/docs/foundations/instruction-loading.md" || true
check "doc covers L0-L3 layers" grep -q "L0\|L1\|L2\|L3" "$ROOT/docs/foundations/instruction-loading.md" || true
check "instruction_checks.rs exists" test -f "$ROOT/stipe/src/commands/doctor/instruction_checks.rs" || true

# Run cargo builds in the stipe directory
if (cd "$ROOT/stipe" && cargo build --release >/dev/null 2>&1); then
  echo "PASS: stipe builds"
  ((PASS++))
else
  echo "FAIL: stipe builds"
  ((FAIL++))
fi

if (cd "$ROOT/stipe" && cargo test >/dev/null 2>&1); then
  echo "PASS: stipe tests pass"
  ((PASS++))
else
  echo "FAIL: stipe tests pass"
  ((FAIL++))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -eq 0 ]; then
  exit 0
else
  exit 1
fi
