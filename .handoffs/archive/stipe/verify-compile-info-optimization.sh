#!/usr/bin/env bash
set -euo pipefail
handoff=".handoffs/archive/stipe/compile-info-optimization.md"
pass=0
fail=0
grep -q "compile-info pass is complete" "$handoff" && pass=$((pass+1)) || { echo "FAIL: completion marker missing"; fail=$((fail+1)); }
grep -q 'blocking `reqwest` was replaced with `ureq`' "$handoff" && pass=$((pass+1)) || { echo "FAIL: reqwest to ureq completion missing"; fail=$((fail+1)); }
grep -q '`dialoguer` was updated to `0.12.0`' "$handoff" && pass=$((pass+1)) || { echo "FAIL: dialoguer completion missing"; fail=$((fail+1)); }
grep -q 'the `spore` pin was confirmed aligned' "$handoff" && pass=$((pass+1)) || { echo "FAIL: spore alignment note missing"; fail=$((fail+1)); }
grep -q "cargo build" "$handoff" && pass=$((pass+1)) || { echo "FAIL: build verification missing"; fail=$((fail+1)); }
grep -q "cargo test" "$handoff" && pass=$((pass+1)) || { echo "FAIL: test verification missing"; fail=$((fail+1)); }
echo "Results: $pass passed, $fail failed"
exit "$fail"
