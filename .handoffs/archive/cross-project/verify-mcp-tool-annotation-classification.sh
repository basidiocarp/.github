#!/usr/bin/env bash
set -euo pipefail
PASS=0
FAIL=0

check() {
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" > /dev/null 2>&1; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

check "classification doc exists" "test -f docs/foundations/mcp-tool-annotations.md"
check "doc mentions readOnlyHint" "grep -q 'readOnlyHint' docs/foundations/mcp-tool-annotations.md"
check "doc mentions destructiveHint" "grep -q 'destructiveHint' docs/foundations/mcp-tool-annotations.md"
check "doc mentions idempotentHint" "grep -q 'idempotentHint' docs/foundations/mcp-tool-annotations.md"
check "doc mentions rhizome tools" "grep -q 'get_definition\|get_symbols' docs/foundations/mcp-tool-annotations.md"
check "doc mentions hyphae tools" "grep -q 'hyphae_memory_recall\|hyphae_memoir' docs/foundations/mcp-tool-annotations.md"
check "doc has ambiguous cases section" "grep -q 'Ambiguous' docs/foundations/mcp-tool-annotations.md"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
