#!/usr/bin/env bash
# Detects drift between ecosystem-versions.toml [tools] table,
# Stipe doctor pins, and repo manifests.
# Usage: bash scripts/check-version-drift.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check_pair() {
    local desc="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "PASS: $desc ($actual)"
        PASS=$((PASS+1))
    else
        echo "FAIL: $desc — ledger=$expected manifest=$actual"
        FAIL=$((FAIL+1))
    fi
}

# Read ledger values
ledger_annulus=$(grep '^annulus\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"')
ledger_cap=$(grep '^cap\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"')
ledger_lamella=$(grep '^lamella\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"')
ledger_hyphae=$(grep '^hyphae\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"')
ledger_canopy=$(grep '^canopy\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"')
ledger_stipe=$(grep '^stipe\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"')
ledger_spore=$(grep '^spore\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"' | head -1)

# Compare manifests against ledger
manifest_annulus=$(grep '^version\s*=' "$ROOT/annulus/Cargo.toml" | head -1 | grep -o '"[^"]*"' | tr -d '"')
manifest_cap=$(python3 -c "import json,sys; print(json.load(open('$ROOT/cap/package.json'))['version'])" 2>/dev/null || grep '"version"' "$ROOT/cap/package.json" | head -1 | grep -o '"[0-9][^"]*"' | tr -d '"')
manifest_lamella=$(cat "$ROOT/lamella/VERSION" | tr -d '[:space:]')

check_pair "annulus Cargo.toml matches ledger" "$ledger_annulus" "$manifest_annulus"
check_pair "cap package.json matches ledger" "$ledger_cap" "$manifest_cap"
check_pair "lamella VERSION matches ledger" "$ledger_lamella" "$manifest_lamella"

# Compare Stipe doctor pins against ledger
stipe_hyphae=$(grep 'pins.insert("hyphae"' "$ROOT/stipe/src/commands/doctor/plugin_inventory_checks.rs" | head -1 | grep -o '"[0-9][^"]*"' | tail -1 | tr -d '"')
stipe_canopy=$(grep 'pins.insert("canopy"' "$ROOT/stipe/src/commands/doctor/plugin_inventory_checks.rs" | head -1 | grep -o '"[0-9][^"]*"' | tail -1 | tr -d '"')
stipe_stipe=$(grep 'pins.insert("stipe"' "$ROOT/stipe/src/commands/doctor/plugin_inventory_checks.rs" | head -1 | grep -o '"[0-9][^"]*"' | tail -1 | tr -d '"')
stipe_spore=$(grep 'pins.insert("spore"' "$ROOT/stipe/src/commands/doctor/plugin_inventory_checks.rs" | head -1 | grep -o '"[0-9][^"]*"' | tail -1 | tr -d '"')
stipe_annulus=$(grep 'pins.insert("annulus"' "$ROOT/stipe/src/commands/doctor/plugin_inventory_checks.rs" | head -1 | grep -o '"[0-9][^"]*"' | tail -1 | tr -d '"')
stipe_cap=$(grep 'pins.insert("cap"' "$ROOT/stipe/src/commands/doctor/plugin_inventory_checks.rs" | head -1 | grep -o '"[0-9][^"]*"' | tail -1 | tr -d '"')

check_pair "stipe doctor hyphae pin matches ledger" "$ledger_hyphae" "$stipe_hyphae"
check_pair "stipe doctor canopy pin matches ledger" "$ledger_canopy" "$stipe_canopy"
check_pair "stipe doctor stipe pin matches ledger" "$ledger_stipe" "$stipe_stipe"
check_pair "stipe doctor spore pin matches ledger" "$ledger_spore" "$stipe_spore"
check_pair "stipe doctor annulus pin matches ledger" "$ledger_annulus" "$stipe_annulus"
check_pair "stipe doctor cap pin matches ledger" "$ledger_cap" "$stipe_cap"

# Check hyphae release script includes hyphae-ingest
if grep -q 'hyphae-ingest' "$ROOT/hyphae/scripts/release.sh"; then
    echo "PASS: hyphae release script includes hyphae-ingest"
    PASS=$((PASS+1))
else
    echo "FAIL: hyphae release script missing hyphae-ingest"
    FAIL=$((FAIL+1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
