#!/usr/bin/env bash
# Verifies Rust supply chain policy implementation.
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

# deny.toml exists
check "deny.toml exists" test -f deny.toml

# dependabot.yml covers cargo
check "dependabot.yml covers cargo" grep -q 'package-ecosystem.*cargo' .github/dependabot.yml

# check-spore-pins.sh exists and passes
check "check-spore-pins.sh exists" test -f scripts/check-spore-pins.sh
check "spore pins use rev not tag" bash scripts/check-spore-pins.sh

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
