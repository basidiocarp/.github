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

# deny.toml exists and has required sections
check "deny.toml exists" test -f deny.toml
check "deny.toml has [licenses] section" grep -q '^\[licenses\]' deny.toml
check "deny.toml has [sources] section" grep -q '^\[sources\]' deny.toml

# basidiocarp root dependabot.yml does NOT contain dead Cargo entries for sub-repos
# (sub-repos are separate git repositories, not subdirectories of basidiocarp)
check "root dependabot.yml has no dead cargo directory entries" \
    bash -c '! grep -q "directory: /mycelium\|directory: /hyphae\|directory: /volva" .github/dependabot.yml'

# All three previously-unmonitored repos now have their own dependabot.yml with Cargo
check "volva has Cargo dependabot monitoring" grep -q 'package-ecosystem.*cargo' volva/.github/dependabot.yml
check "annulus has Cargo dependabot monitoring" grep -q 'package-ecosystem.*cargo' annulus/.github/dependabot.yml
check "hymenium has Cargo dependabot monitoring" grep -q 'package-ecosystem.*cargo' hymenium/.github/dependabot.yml

# check-spore-pins.sh exists and passes
check "check-spore-pins.sh exists" test -f scripts/check-spore-pins.sh
check "spore pins use rev not tag" bash scripts/check-spore-pins.sh

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
