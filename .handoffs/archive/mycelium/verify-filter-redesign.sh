#!/bin/bash
# Verification script for filter-redesign.md
# Run: bash .handoffs/mycelium/verify-filter-redesign.sh

set -euo pipefail
PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MYCELIUM="$ROOT/mycelium"

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

echo "=== FILTER-REDESIGN Verification ==="
echo ""

echo "--- Step 1: Token-Based Classification ---"
check "classify_by_tokens function exists" \
  "grep -q 'classify_by_tokens\|passthrough_tokens' $MYCELIUM/src/adaptive.rs"
check "token threshold constants defined" \
  "grep -q 'PASSTHROUGH_TOKEN\|passthrough_tokens' $MYCELIUM/src/adaptive.rs || grep -q 'passthrough_tokens' $MYCELIUM/src/config.rs"
check "estimate_tokens used in adaptive" \
  "grep -q 'estimate_tokens' $MYCELIUM/src/adaptive.rs"

echo ""
echo "--- Step 2: FilterResult and FilterQuality ---"
check "FilterQuality enum exists" \
  "grep -rq 'FilterQuality' $MYCELIUM/src/filter.rs"
check "FilterResult struct exists" \
  "grep -rq 'FilterResult' $MYCELIUM/src/filter.rs"
check "Full variant exists" \
  "grep -q 'Full' $MYCELIUM/src/filter.rs"
check "Degraded variant exists" \
  "grep -q 'Degraded' $MYCELIUM/src/filter.rs"

echo ""
echo "--- Step 3: Filter Validation ---"
check "validate_filter_output function exists" \
  "grep -rq 'validate_filter_output\|validate_filter' $MYCELIUM/src/hyphae.rs"
check "savings threshold check (20%)" \
  "grep -rq '0.20\|0\.2\|twenty\|20.*savings\|savings.*20' $MYCELIUM/src/hyphae.rs"
check "aggressive reduction check (95%)" \
  "grep -rq '0.95\|95.*reduction\|suspiciously' $MYCELIUM/src/hyphae.rs"

echo ""
echo "--- Step 4: Filter Header ---"
check "filter header function exists" \
  "grep -rq 'add_filter_header\|filter_header\|mycelium filtered' $MYCELIUM/src/"
check "header includes proxy hint" \
  "grep -rq 'mycelium proxy\|proxy.*raw' $MYCELIUM/src/"
check "show_filter_header config option" \
  "grep -rq 'show_filter_header\|filter_header' $MYCELIUM/src/config.rs"

echo ""
echo "--- Step 5: Filter Quality Migration ---"
check "gh filter returns quality" \
  "grep -rq 'FilterQuality\|FilterResult\|filter_with_quality' $MYCELIUM/src/filters/gh.rs 2>/dev/null || grep -rq 'FilterQuality\|quality' $MYCELIUM/src/gh_cmd.rs 2>/dev/null"

echo ""
echo "--- Build Verification ---"
check "cargo test passes" \
  "cd $MYCELIUM && cargo test --quiet 2>&1"
check "cargo clippy clean" \
  "cd $MYCELIUM && cargo clippy --quiet 2>&1"

echo ""
echo "--- Functional Tests ---"
if command -v mycelium >/dev/null 2>&1; then
  check "short output passes through unchanged" \
    "test \"\$(mycelium proxy echo test)\" = \"\$(echo test)\""
  check "mycelium which returns a path" \
    "mycelium which git 2>/dev/null | grep -q '/'"
fi

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
