#!/bin/bash
# Verification script for gh-filter-quality.md
# Run: bash .handoffs/mycelium/verify-gh-filter-quality.sh

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

echo "=== GH-FILTER-QUALITY Verification ==="
echo ""

echo "--- FilterResult in GH handlers ---"
check "FilterResult used in gh_cmd" \
  "grep -rq 'FilterResult' $MYCELIUM/src/vcs/gh_cmd/"
check "FilterResult used in gh_pr" \
  "grep -rq 'FilterResult' $MYCELIUM/src/vcs/gh_pr/"
check "Quality detection in gh parsers" \
  "grep -rq 'FilterQuality\|Degraded\|Passthrough' $MYCELIUM/src/vcs/gh_cmd/"

echo ""
echo "--- Validation ---"
check "validate_filter_output called for gh output" \
  "grep -rq 'validate_filter_output\|route_or_filter' $MYCELIUM/src/vcs/gh_cmd/ $MYCELIUM/src/vcs/gh_pr/"

echo ""
echo "--- Build Verification ---"
check "cargo test passes" \
  "cd $MYCELIUM && cargo test --quiet 2>&1"
check "cargo clippy clean" \
  "cd $MYCELIUM && cargo clippy --quiet 2>&1"

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
