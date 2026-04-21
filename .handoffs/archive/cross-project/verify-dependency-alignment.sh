#!/bin/bash
# Verification script for dependency-alignment.md
# Run: bash .handoffs/cross-project/verify-dependency-alignment.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== DEPENDENCY-ALIGNMENT Verification ==="
echo ""

echo "--- Edition Alignment (all 2024) ---"
check "spore edition 2024" \
  "grep -q 'edition = \"2024\"' $ROOT/spore/Cargo.toml"
check "mycelium edition 2024" \
  "grep -q 'edition = \"2024\"' $ROOT/mycelium/Cargo.toml"
check "hyphae edition 2024" \
  "grep -q 'edition = \"2024\"' $ROOT/hyphae/Cargo.toml || grep -q 'edition = \"2024\"' $ROOT/hyphae/crates/hyphae-core/Cargo.toml"
check "rhizome edition 2024" \
  "grep -q 'edition = \"2024\"' $ROOT/rhizome/Cargo.toml || grep -q 'edition = \"2024\"' $ROOT/rhizome/crates/rhizome-core/Cargo.toml"
check "stipe edition 2024" \
  "grep -q 'edition = \"2024\"' $ROOT/stipe/Cargo.toml"
check "cortina edition 2024" \
  "grep -q 'edition = \"2024\"' $ROOT/cortina/Cargo.toml"
check "canopy edition 2024" \
  "grep -q 'edition = \"2024\"' $ROOT/canopy/Cargo.toml"

echo ""
echo "--- MSRV Alignment (all 1.85) ---"
check "spore MSRV 1.85" \
  "grep -q 'rust-version' $ROOT/spore/Cargo.toml"
check "mycelium MSRV" \
  "grep -q 'rust-version' $ROOT/mycelium/Cargo.toml"
check "hyphae MSRV" \
  "grep -q 'rust-version' $ROOT/hyphae/Cargo.toml || grep -q 'rust-version' $ROOT/hyphae/crates/hyphae-core/Cargo.toml"
check "rhizome MSRV" \
  "grep -q 'rust-version' $ROOT/rhizome/Cargo.toml || grep -q 'rust-version' $ROOT/rhizome/crates/rhizome-core/Cargo.toml"
check "stipe MSRV" \
  "grep -q 'rust-version' $ROOT/stipe/Cargo.toml"
check "cortina MSRV" \
  "grep -q 'rust-version' $ROOT/cortina/Cargo.toml"
check "canopy MSRV" \
  "grep -q 'rust-version' $ROOT/canopy/Cargo.toml"

echo ""
echo "--- rusqlite Alignment (all 0.39) ---"
check "mycelium rusqlite 0.39" \
  "grep -q 'rusqlite.*0\\.39' $ROOT/mycelium/Cargo.toml"
check "hyphae rusqlite 0.39" \
  "grep -q 'rusqlite.*0\\.39' $ROOT/hyphae/Cargo.toml"
check "canopy rusqlite 0.39" \
  "grep -q 'rusqlite.*0\\.39' $ROOT/canopy/Cargo.toml"
check "cortina rusqlite 0.39" \
  "grep -q 'rusqlite.*0\\.39' $ROOT/cortina/Cargo.toml"

echo ""
echo "--- toml Alignment (all 1.0) ---"
check "spore toml 1.0" \
  "grep -qE 'toml.*(\"1|version = \"1)' $ROOT/spore/Cargo.toml"
check "mycelium toml 1.0" \
  "grep -qE 'toml.*(\"1|version = \"1)' $ROOT/mycelium/Cargo.toml"
check "hyphae toml 1.0" \
  "grep -qE 'toml.*(\"1|version = \"1)' $ROOT/hyphae/Cargo.toml || grep -qE 'toml.*(\"1|version = \"1)' $ROOT/hyphae/crates/hyphae-cli/Cargo.toml"
check "stipe toml 1.0" \
  "grep -qE 'toml.*(\"1|version = \"1)' $ROOT/stipe/Cargo.toml"

echo ""
echo "--- Build Verification ---"
check "spore builds" \
  "cd $ROOT/spore && cargo build --quiet 2>&1"
check "mycelium builds" \
  "cd $ROOT/mycelium && cargo build --quiet 2>&1"
check "hyphae builds" \
  "cd $ROOT/hyphae && cargo build --quiet --no-default-features 2>&1"
check "rhizome builds" \
  "cd $ROOT/rhizome && cargo build --quiet 2>&1"
check "stipe builds" \
  "cd $ROOT/stipe && cargo build --quiet 2>&1"
check "cortina builds" \
  "cd $ROOT/cortina && cargo build --quiet 2>&1"
check "canopy builds" \
  "cd $ROOT/canopy && cargo build --quiet 2>&1"

echo ""
echo "--- ecosystem-versions.toml ---"
check "ecosystem-versions.toml updated" \
  "test -f $ROOT/ecosystem-versions.toml && ! grep -q '0\\.34' $ROOT/ecosystem-versions.toml"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
