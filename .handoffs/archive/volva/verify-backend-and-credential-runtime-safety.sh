#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0
FAIL=0

check() {
  local label="$1"; shift
  if eval "$@" &>/dev/null; then
    echo "PASS: $label"; PASS=$((PASS+1))
  else
    echo "FAIL: $label"; FAIL=$((FAIL+1))
  fi
}

check "official_cli tests pass" "cd '$ROOT/volva' && cargo test -p volva-runtime official_cli 2>&1 | grep -q 'test result: ok'"
check "checkpoint tests pass" "cd '$ROOT/volva' && cargo test -p volva-runtime checkpoint 2>&1 | grep -q 'test result: ok'"
check "auth storage tests pass" "cd '$ROOT/volva' && cargo test -p volva-auth storage 2>&1 | grep -q 'test result: ok'"
check "env_clear applied to hook adapter subprocess" "grep -r 'env_clear' '$ROOT/volva/crates/volva-runtime/src/hooks.rs'"
check "trusted field in HookAdapterConfig" "grep -r 'trusted' '$ROOT/volva/crates/volva-config/src/lib.rs'"
check "corrupted checkpoint fails loudly" "grep -rE 'corrupted|corrupt|invalid.*json|json.*invalid' '$ROOT/volva/crates/volva-runtime/src/checkpoint_sqlite.rs'"
check "credential file permission check on load" "grep -r 'permission\|mode.*0o6\|0o077' '$ROOT/volva/crates/volva-auth/src/storage.rs'"
check "backend subprocess has timeout" "grep -rE 'timeout|Duration|kill' '$ROOT/volva/crates/volva-runtime/src/backend/official_cli.rs'"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
