#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
    local label="$1"
    local result="$2"
    if [ "$result" = "pass" ]; then
        echo "PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $label"
        FAIL=$((FAIL + 1))
    fi
}

cd "$(dirname "$0")/../../cortina"

# Check compute_tool_adoption_gaps function exists
grep -q "fn compute_tool_adoption_gaps" src/hooks/stop.rs 2>/dev/null \
    && check "compute_tool_adoption_gaps function" "pass" \
    || check "compute_tool_adoption_gaps function" "fail"

# Check tools_relevant_unused is populated in emit_tool_usage_event
grep -q "tools_relevant_unused" src/hooks/stop/tool_usage_emit.rs 2>/dev/null \
    && check "tools_relevant_unused field populated" "pass" \
    || check "tools_relevant_unused field populated" "fail"

# Check stderr advisory emission exists
grep -q "tool adoption gaps" src/hooks/stop.rs 2>/dev/null \
    && check "adoption gap advisory emission" "pass" \
    || check "adoption gap advisory emission" "fail"

# Check gap tests pass
cargo test gap --quiet 2>&1 | grep -q "test result: ok" \
    && check "gap tests pass" "pass" \
    || check "gap tests pass" "fail"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
