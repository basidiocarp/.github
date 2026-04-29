#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}

check "notify write boundary is resolved" \
  /bin/zsh -lc "if rg -q 'UPDATE notifications SET seen' '$ROOT/annulus/src'; then rg -q 'notification.*ack|notify.*write|Canopy-owned|not read-only' '$ROOT/annulus/README.md' '$ROOT/annulus/AGENTS.md' '$ROOT/annulus/CLAUDE.md' '$ROOT/annulus/docs'; else true; fi"

check "statusline schema includes default segments or defaults omit extras" \
  /bin/zsh -lc "defaults=\$(rg 'vec!\\[|default_segments|degradation|hyphae' '$ROOT/annulus/src/config.rs' '$ROOT/annulus/src/statusline.rs'); if printf '%s' \"\$defaults\" | rg -q 'degradation|hyphae'; then rg -q 'degradation|hyphae' '$ROOT/septa/annulus-statusline-v1.schema.json'; else true; fi"

check "annulus version ledger matches cargo version" \
  /bin/zsh -lc "version=\$(sed -n 's/^version = \"\\(.*\\)\"/\\1/p' '$ROOT/annulus/Cargo.toml' | head -1); rg -q \"annulus = \\\"\$version\\\"\" '$ROOT/ecosystem-versions.toml'"

check "annulus tests pass" \
  /bin/zsh -lc "cd '$ROOT/annulus' && cargo test >/dev/null"

check "annulus statusline fixture validates" \
  /bin/zsh -lc "cd '$ROOT/septa' && check-jsonschema --schemafile annulus-statusline-v1.schema.json fixtures/annulus-statusline-v1.example.json >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
