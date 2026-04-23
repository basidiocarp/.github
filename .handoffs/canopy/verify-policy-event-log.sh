#!/usr/bin/env bash
# Verify: canopy policy-event-log
# Run from: basidiocarp root or canopy/

set -euo pipefail

PASS=0
FAIL=0

check() {
    local label="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null; then
        echo "PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $label"
        FAIL=$((FAIL + 1))
    fi
}

CANOPY_DIR="$(cd "$(dirname "$0")/../.." && pwd)/canopy"
cd "$CANOPY_DIR"

# 1. Build passes
check "cargo build succeeds" "cargo build 2>&1 | grep -q 'Finished\|Compiling canopy'"

# 2. policy_events table in schema
check "policy_events table in schema.rs" \
    "grep -q 'policy_events' src/store/schema.rs"

# 3. policy_events store module exists
check "src/store/policy_events.rs exists" \
    "test -f src/store/policy_events.rs"

# 4. log_policy_event trait method in traits.rs
check "log_policy_event in store traits" \
    "grep -q 'log_policy_event' src/store/traits.rs"

# 5. dispatch_tool calls log_policy_event
check "dispatch_tool logs policy decision" \
    "grep -q 'log_policy_event' src/tools/mod.rs"

# 6. unit tests for policy_events pass
check "policy_event unit tests pass" \
    "cargo test policy_event 2>&1 | grep -qE 'test result: ok|0 failed'"

# 7. full test suite
check "full test suite passes" \
    "cargo test 2>&1 | grep -qE 'test result: ok|0 failed'"

# 8. clippy clean
check "clippy clean" \
    "cargo clippy --all-targets -- -D warnings 2>&1 | grep -vq 'error'"

# 9. fmt check
check "cargo fmt check" \
    "cargo fmt --check 2>&1 | grep -vq 'Diff'"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
