#!/bin/bash

# Verification script for foundation-alignment handoff
# Checks:
# 1. rhizome/docs/architecture.md contains "Backend Boundary Rules" section
# 2. cargo build --workspace exits 0
# 3. cargo test --workspace exits 0

set -e

PASSED=0
FAILED=0

echo "=== Foundation Alignment Verification ==="
echo ""

# Check 1: Backend Boundary Rules section exists in architecture.md
echo "Check 1: Verifying Backend Boundary Rules section in architecture.md..."
if grep -q "Backend Boundary Rules" /Users/williamnewton/projects/basidiocarp/rhizome/docs/architecture.md; then
    echo "  PASS: Backend Boundary Rules section found"
    ((PASSED++))
else
    echo "  FAIL: Backend Boundary Rules section not found"
    ((FAILED++))
fi

# Check 2: cargo build --workspace
echo ""
echo "Check 2: Running cargo build --workspace..."
if cd /Users/williamnewton/projects/basidiocarp/rhizome && cargo build --workspace > /tmp/build.log 2>&1; then
    echo "  PASS: cargo build --workspace succeeded"
    ((PASSED++))
else
    echo "  FAIL: cargo build --workspace failed"
    cat /tmp/build.log
    ((FAILED++))
fi

# Check 3: cargo test --workspace
echo ""
echo "Check 3: Running cargo test --workspace..."
if cd /Users/williamnewton/projects/basidiocarp/rhizome && cargo test --workspace > /tmp/test.log 2>&1; then
    echo "  PASS: cargo test --workspace succeeded"
    ((PASSED++))
else
    echo "  FAIL: cargo test --workspace failed"
    cat /tmp/test.log
    ((FAILED++))
fi

echo ""
echo "=== Results ==="
echo "Results: $PASSED passed, $FAILED failed"

exit "$FAILED"
