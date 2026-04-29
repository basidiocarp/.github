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

check "hook event DTO exists" \
  rg -q 'VolvaHookEventV1|volva-hook-event-v1|HookAdapterPayload' "$ROOT/volva/crates/volva-runtime/src" "$ROOT/volva/tests"

check "timeout bounds are enforced" \
  rg -q '30000|30_000|timeout.*range|timeout.*clamp|timeout.*validate' "$ROOT/volva/crates/volva-config/src" "$ROOT/volva/crates/volva-runtime/src"

check "hook docs avoid out-of-contract 60s timeout" \
  /bin/zsh -lc "! rg -q '60000|60s|60 seconds' '$ROOT/volva/docs/hook-adapter-cortina.md'"

check "runtime identity contract is referenced" \
  rg -q 'workflow-participant-runtime-identity|workflow_id|host_ref|backend_ref' "$ROOT/volva/crates"

check "volva focused tests pass" \
  /bin/zsh -lc "cd '$ROOT/volva' && cargo test -p volva-runtime -p volva-config -p volva-cli >/dev/null"

check "volva hook fixture validates" \
  /bin/zsh -lc "cd '$ROOT/septa' && check-jsonschema --schemafile volva-hook-event-v1.schema.json fixtures/volva-hook-event-v1.example.json >/dev/null"

check "hook execution fixture validates" \
  /bin/zsh -lc "cd '$ROOT/septa' && check-jsonschema --schemafile hook-execution-v1.schema.json fixtures/hook-execution-v1.example.json >/dev/null"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
