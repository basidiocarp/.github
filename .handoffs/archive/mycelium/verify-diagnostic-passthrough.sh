#!/bin/bash
# Verification script for HANDOFF-MYCELIUM-DIAGNOSTIC-PASSTHROUGH.md
# Run: bash .handoffs/mycelium/verify-diagnostic-passthrough.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    ((PASS++))
  else
    echo "  FAIL: $desc"
    ((FAIL++))
  fi
}

echo "=== HANDOFF-MYCELIUM-DIAGNOSTIC-PASSTHROUGH Verification ==="
echo ""

echo "--- Option A: Diagnostic Passthrough List ---"
check "passthrough list exists in mycelium" \
  "grep -rq 'DIAGNOSTIC_PASSTHROUGH\\|diagnostic_passthrough\\|passthrough_commands' $ROOT/mycelium/src/"
check "which is in passthrough list" \
  "grep -rq '\"which\"' $ROOT/mycelium/src/"
check "type is in passthrough list" \
  "grep -rq '\"type\"' $ROOT/mycelium/src/"
check "file is in passthrough list" \
  "grep -rq '\"file\"' $ROOT/mycelium/src/"
check "stat is in passthrough list" \
  "grep -rq '\"stat\"' $ROOT/mycelium/src/"
check "echo is in passthrough list" \
  "grep -rq '\"echo\"' $ROOT/mycelium/src/"

echo ""
echo "--- Option C: Adaptive Threshold ---"
check "adaptive.rs exists" \
  "test -f $ROOT/mycelium/src/adaptive.rs || test -f $ROOT/mycelium/src/filters/adaptive.rs"
check "small output passthrough (<5 lines)" \
  "grep -rq '5\\|small_output\\|min_lines\\|passthrough_threshold' $ROOT/mycelium/src/adaptive.rs 2>/dev/null || grep -rq 'passthrough' $ROOT/mycelium/src/filters/adaptive.rs 2>/dev/null"

echo ""
echo "--- Functional Tests ---"
if command -v mycelium >/dev/null 2>&1; then
  check "mycelium which git returns a path" \
    "mycelium which git 2>/dev/null | grep -q '/'"
  check "mycelium echo test returns test" \
    "mycelium echo test 2>/dev/null | grep -q 'test'"
  check "mycelium file /usr/bin/ls returns file type" \
    "mycelium file /usr/bin/ls 2>/dev/null | grep -qi 'mach-o\\|ELF\\|executable'"
  check "mycelium stat /usr/bin/ls returns stats" \
    "mycelium stat /usr/bin/ls 2>/dev/null | grep -qi 'size\\|modify\\|access\\|File:'"
else
  echo "  SKIP: mycelium not installed — skipping functional tests"
fi

echo ""
echo "--- Build Verification ---"
check "cargo test passes" \
  "cd $ROOT/mycelium && cargo test --quiet 2>&1"
check "cargo clippy clean" \
  "cd $ROOT/mycelium && cargo clippy --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
