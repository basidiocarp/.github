#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PASS=0; FAIL=0
check() { local d="$1"; shift; if "$@" &>/dev/null; then echo "PASS: $d"; PASS=$((PASS+1)); else echo "FAIL: $d"; FAIL=$((FAIL+1)); fi; }
check "gate_guard tests pass" bash -c "(cd '$ROOT/cortina' && cargo test gate_guard 2>&1 | grep -q 'test result: ok')"
check "pre_tool_use tests pass" bash -c "(cd '$ROOT/cortina' && cargo test pre_tool_use 2>&1 | grep -q 'test result: ok')"
check "adapter tests pass" bash -c "(cd '$ROOT/cortina' && cargo test adapter 2>&1 | grep -q 'test result: ok')"
check "README does not reference nonexistent statusline.rs" bash -c "! grep -q 'src/statusline.rs' '$ROOT/cortina/README.md'"
check "GateGuard default is advisory mode" grep -q 'Advisory\|advisory' "$ROOT/cortina/src/hooks/gate_guard.rs"
echo ""; echo "Results: $PASS passed, $FAIL failed"; [ "$FAIL" -eq 0 ]
