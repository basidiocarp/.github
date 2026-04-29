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

check "dispatch tests pass" "out=\$(cd '$ROOT/hymenium' && cargo test dispatch 2>&1); echo \"\$out\" | grep -q 'test result: ok'"
check "env_clear used in dispatch cli" "grep -r 'env_clear' '$ROOT/hymenium/src/dispatch/'"
check "timeout applied to canopy subprocess" "grep -rE 'Duration|timeout|kill' '$ROOT/hymenium/src/dispatch/cli.rs'"
check "explicit canopy path resolution" "grep -rE 'which|canonicalize|PATH.*canopy' '$ROOT/hymenium/src/dispatch/cli.rs'"
check "actionable error on canopy not found" "grep -rE 'not found|cannot find|no canopy' '$ROOT/hymenium/src/dispatch/cli.rs'"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
