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

# Read ledger values (|| true so a no-match yields empty -> visible FAIL, not a set -e abort)
ledger_annulus=$(grep '^annulus\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"' || true)
ledger_cap=$(grep '^cap\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"' || true)
ledger_lamella=$(grep '^lamella\s*=' "$ROOT/ecosystem-versions.toml" | grep -o '"[^"]*"' | tr -d '"' || true)

# Compare manifests against ledger
manifest_annulus=$(grep '^version\s*=' "$ROOT/annulus/Cargo.toml" | head -1 | grep -o '"[^"]*"' | tr -d '"' || true)
manifest_cap=$(python3 -c "import json,sys; print(json.load(open('$ROOT/cap/package.json'))['version'])" 2>/dev/null || grep '"version"' "$ROOT/cap/package.json" | head -1 | grep -o '"[0-9][^"]*"' | tr -d '"' || true)
manifest_lamella=$(tr -d '[:space:]' < "$ROOT/lamella/VERSION" 2>/dev/null || true)

check_pair "annulus Cargo.toml matches ledger" "$ledger_annulus" "$manifest_annulus"
check_pair "cap package.json matches ledger" "$ledger_cap" "$manifest_cap"
check_pair "lamella VERSION matches ledger" "$ledger_lamella" "$manifest_lamella"

# Stipe doctor pins are GENERATED from ecosystem-versions.toml [tools] via build.rs
# (stipe/src/commands/doctor/version_pins.rs is an @generated include). Ledger<->doctor
# drift is therefore impossible by construction — we verify the generation wiring is intact
# rather than diffing a hand-maintained pin table that no longer exists.
pins_file="$ROOT/stipe/src/commands/doctor/version_pins.rs"
build_file="$ROOT/stipe/build.rs"
if grep -q '@generated' "$pins_file" 2>/dev/null \
   && grep -q 'pinned_ecosystem_versions' "$pins_file" 2>/dev/null \
   && grep -q 'ecosystem-versions.toml' "$build_file" 2>/dev/null \
   && grep -q '"tools"' "$build_file" 2>/dev/null; then
    echo "PASS: stipe doctor pins generated from ledger [tools] (build.rs wiring intact)"
    PASS=$((PASS+1))
else
    echo "FAIL: stipe version-pin generation wiring missing (build.rs / version_pins.rs)"
    FAIL=$((FAIL+1))
fi

# Check hyphae release script includes hyphae-ingest
if grep -q 'hyphae-ingest' "$ROOT/hyphae/scripts/release.sh"; then
    echo "PASS: hyphae release script includes hyphae-ingest"
    PASS=$((PASS+1))
else
    echo "FAIL: hyphae release script missing hyphae-ingest"
    FAIL=$((FAIL+1))
fi

# Check the [contracts] mirror is in sync with septa's enforced registry
if bash "$ROOT/scripts/sync-contracts.sh" --check >/dev/null 2>&1; then
    echo "PASS: [contracts] mirror in sync with septa/CROSS-TOOL-PAYLOADS.md"
    PASS=$((PASS+1))
else
    echo "FAIL: [contracts] mirror stale — run 'bash scripts/sync-contracts.sh'"
    FAIL=$((FAIL+1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
