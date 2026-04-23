#!/usr/bin/env bash
# Reads the canonical spore version from ecosystem-versions.toml
# and verifies each consumer's Cargo.toml matches it.
# Usage: bash scripts/check-spore-pins.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOML="$ROOT/ecosystem-versions.toml"

CANONICAL=$(awk '/^\[spore\]/{found=1} found && /^version/{gsub(/version = "|"/, ""); print; exit}' "$TOML")
if [ -z "$CANONICAL" ]; then
  echo "ERROR: could not read [spore] version from $TOML"
  exit 1
fi

echo "Canonical spore version: $CANONICAL"

CONSUMERS=(mycelium hyphae canopy rhizome stipe cortina annulus hymenium volva)
FAIL=0

for repo in "${CONSUMERS[@]}"; do
  CARGO="$ROOT/$repo/Cargo.toml"
  if [ ! -f "$CARGO" ]; then
    echo "SKIP: $repo/Cargo.toml not found"
    continue
  fi
  PINNED=$(grep -o 'tag = "v[0-9.]*"' "$CARGO" 2>/dev/null | head -1 | sed 's/tag = "v//;s/"//')
  if [ -z "$PINNED" ]; then
    # Try rev-based spore dep
    PINNED=$(grep -A5 'spore' "$CARGO" | grep -o 'tag = "v[0-9.]*"' | head -1 | sed 's/tag = "v//;s/"//')
  fi
  if [ -z "$PINNED" ]; then
    echo "SKIP: $repo — no spore tag found in Cargo.toml"
    continue
  fi
  if [ "$PINNED" != "$CANONICAL" ]; then
    echo "FAIL: $repo pins spore v$PINNED, canonical is $CANONICAL"
    FAIL=$((FAIL + 1))
  else
    echo "OK:   $repo on v$CANONICAL"
  fi
done

echo ""
[ "$FAIL" -eq 0 ] && echo "All spore pins match canonical." && exit 0
echo "$FAIL repo(s) out of sync."
exit 1
