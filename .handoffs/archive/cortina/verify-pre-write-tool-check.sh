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

# Check DEFAULT_RULES exists
grep -q "DEFAULT_RULES" src/rules.rs 2>/dev/null && check "DEFAULT_RULES defined" "pass" || check "DEFAULT_RULES defined" "fail"

# Check matching_rules function
grep -q "fn matching_rules" src/rules.rs 2>/dev/null && check "matching_rules function" "pass" || check "matching_rules function" "fail"

# Check write_advisory function
grep -q "fn write_advisory" src/hooks/pre_tool_use.rs 2>/dev/null && check "write_advisory function" "pass" || check "write_advisory function" "fail"

# Check advisory tests pass
cargo test advisory --quiet 2>&1 | grep -q "test result: ok" && check "advisory tests pass" "pass" || check "advisory tests pass" "fail"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
