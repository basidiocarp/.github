#!/usr/bin/env bash
set -euo pipefail
handoff=".handoffs/archive/canopy/compile-info-optimization.md"
manifest="canopy/Cargo.toml"
pass=0
fail=0
grep -q 'confirmed `modern_sqlite` is not present' "$handoff" && pass=$((pass+1)) || { echo "FAIL: modern_sqlite absence not documented"; fail=$((fail+1)); }
grep -q 'Status: complete under current scope\.' "$handoff" && pass=$((pass+1)) || { echo "FAIL: handoff status not marked complete"; fail=$((fail+1)); }
grep -q 'rusqlite = { version = "0.39", features = \["bundled"\] }' "$manifest" && pass=$((pass+1)) || { echo "FAIL: bundled-only rusqlite manifest entry missing"; fail=$((fail+1)); }
if grep -q 'modern_sqlite' "$manifest"; then
  echo "FAIL: modern_sqlite still present in canopy/Cargo.toml"
  fail=$((fail+1))
else
  pass=$((pass+1))
fi
grep -q "spore" "$handoff" && pass=$((pass+1)) || { echo "FAIL: spore target missing"; fail=$((fail+1)); }
echo "Results: $pass passed, $fail failed"
exit "$fail"
