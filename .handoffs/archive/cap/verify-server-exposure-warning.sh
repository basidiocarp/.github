#!/usr/bin/env bash
# Verify: cap server-exposure-warning
# Run from: basidiocarp root or cap/

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

CAP_DIR="$(cd "$(dirname "$0")/../.." && pwd)/cap"
cd "$CAP_DIR"

# 1. Warning code present in index.ts
check "warning condition exists in server/index.ts" \
    "grep -q 'CAP_HOST.*127.0.0.1\|127.0.0.1.*CAP_HOST\|host.*127.0.0.1\|127.0.0.1.*host' server/index.ts"

check "warning message mentions authentication" \
    "grep -qi 'authentication\|unauthenticated\|auth' server/index.ts"

# 2. Test file exists
check "server exposure warning test file exists" \
    "test -f server/__tests__/server-exposure-warning.test.ts"

# 3. Build
check "npm run build succeeds" \
    "npm run build 2>&1 | grep -vq 'error TS'"

# 4. Tests
check "npm test passes" \
    "npm test 2>&1 | grep -qE 'passed|Tests.*[1-9]'"

check "exposure warning tests pass" \
    "npm test -- server-exposure-warning 2>&1 | grep -qE 'passed|Tests.*[1-9]'"

# 5. Lint
check "npm run lint clean" \
    "npm run lint 2>&1 | grep -vq 'error'"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
