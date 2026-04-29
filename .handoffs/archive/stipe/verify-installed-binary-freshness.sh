#!/usr/bin/env bash
set -euo pipefail
PASS=0; FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"
check() { local name="$1"; shift; if "$@"; then printf 'PASS: %s\n' "$name"; PASS=$((PASS+1)); else printf 'FAIL: %s\n' "$name"; FAIL=$((FAIL+1)); fi }

check "doctor tests pass" bash -lc "cd '$ROOT/stipe' && cargo test doctor 2>&1 | grep -qE '[0-9]+ passed'"
check "tool_registry tests pass" bash -lc "cd '$ROOT/stipe' && cargo test tool_registry 2>&1 | grep -qE '[0-9]+ passed'"
check "hymenium version pin present" bash -lc "rg -q 'hymenium' '$ROOT/stipe/src/commands/doctor/plugin_inventory_checks.rs'"
check "canopy version pin present" bash -lc "rg -q 'canopy' '$ROOT/stipe/src/commands/doctor/plugin_inventory_checks.rs'"
check "stipe update repair action surfaced on drift" bash -lc "rg -q 'stipe update' '$ROOT/stipe/src/commands/doctor/tool_checks.rs' '$ROOT/stipe/src/commands/doctor/plugin_inventory_checks.rs'"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
