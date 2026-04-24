#!/usr/bin/env bash
set -u

PASS=0
FAIL=0

check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $label"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $label"
        FAIL=$((FAIL + 1))
    fi
}

CANOPY_DIR="$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel 2>/dev/null)/canopy" || {
    echo "FAIL: canopy not found"
    exit 1
}

cd "$CANOPY_DIR"

check "cargo build" cargo build --workspace
check "cargo test" timeout 120 cargo test --workspace --quiet
check "verification guard in task complete" grep -q "verification_required" src/tools/task.rs
check "force flag present" grep -q "force" src/tools/task.rs
check "needs_verification_count in codebase" grep -rq "needs_verification_count" src/

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -eq 0 ]; then
    exit 0
else
    exit 1
fi
