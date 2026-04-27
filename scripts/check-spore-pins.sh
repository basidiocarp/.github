#!/usr/bin/env bash
# Validates that all Spore git dependencies use rev= (immutable) not tag= (mutable).
# Usage: bash scripts/check-spore-pins.sh
set -euo pipefail

PASS=0
FAIL=0

check_repo() {
    local repo="$1"
    local toml="$repo/Cargo.toml"
    [ -f "$toml" ] || return 0
    if grep -q 'basidiocarp/spore' "$toml"; then
        if grep -A3 'basidiocarp/spore' "$toml" | grep -q 'tag\s*='; then
            echo "FAIL: $toml uses mutable tag= for spore; change to rev="
            FAIL=$((FAIL+1))
        else
            echo "PASS: $toml pins spore by rev="
            PASS=$((PASS+1))
        fi
    fi
}

for repo in mycelium hyphae rhizome stipe cortina spore canopy volva annulus hymenium; do
    check_repo "$repo"
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
