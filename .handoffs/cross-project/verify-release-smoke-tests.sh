#!/bin/bash
# Verification script for release-smoke-tests.md
# Run: bash .handoffs/cross-project/verify-release-smoke-tests.sh

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

REPOS=(canopy stipe hymenium cortina annulus volva)

echo "=== RELEASE-SMOKE-TESTS Verification ==="
echo ""

for repo in "${REPOS[@]}"; do
  RELEASE="$ROOT/$repo/.github/workflows/release.yml"
  echo "--- $repo ---"

  check "$repo: release.yml exists" \
    "test -f '$RELEASE'"

  check "$repo: has Smoke test step" \
    "grep -q 'name: Smoke test' '$RELEASE'"

  check "$repo: Smoke step has --version (L0)" \
    "grep -q '\-\-version' '$RELEASE'"

  check "$repo: Smoke step has cross-skip guard" \
    "grep -q \"matrix.cross != 'true'\" '$RELEASE'"

  check "$repo: Smoke step uses set -euo pipefail" \
    "grep -q 'set -euo pipefail' '$RELEASE'"

  check "$repo: Smoke step has L1 command beyond --version" \
    "grep -qE '(list|status|--help)' '$RELEASE'"

  echo ""
done

echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
