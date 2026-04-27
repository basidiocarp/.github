#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
    local desc="$1"; shift
    if "$@" &>/dev/null; then
        echo "PASS: $desc"
        PASS=$((PASS+1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL+1))
    fi
}

# check-version-drift.sh exists and passes
check "check-version-drift.sh exists" test -f scripts/check-version-drift.sh
check "no version drift detected" bash scripts/check-version-drift.sh

# Stipe doctor tests pass
check "stipe doctor tests pass" bash -c "(cd stipe && cargo test doctor 2>&1 | grep -q 'test result: ok')"

# Hyphae release script includes hyphae-ingest
check "hyphae release script includes hyphae-ingest" grep -q 'hyphae-ingest' hyphae/scripts/release.sh

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
