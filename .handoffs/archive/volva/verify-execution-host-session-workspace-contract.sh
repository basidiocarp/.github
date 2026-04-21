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

check "Volva core mentions execution session types" \
  rg -q 'ExecutionSession|SessionState|workspace|worktree' "$ROOT/volva/crates/volva-core/src"

check "Volva runtime carries session or workspace identity" \
  rg -q 'session|workspace|worktree|participant' "$ROOT/volva/crates/volva-runtime/src/context.rs"

check "Volva CLI run or chat surfaces mention session identity" \
  rg -q 'session|workspace|worktree' "$ROOT/volva/crates/volva-cli/src/run.rs" "$ROOT/volva/crates/volva-cli/src/chat.rs"

check "Volva architecture doc mentions execution-host session boundary" \
  rg -q 'execution-host|session|workspace|worktree' "$ROOT/volva/docs/VOLVA-ARCHITECTURE.md"

check "Volva runtime persists and loads execution session snapshots" \
  rg -q 'persist_execution_session|load_execution_session' "$ROOT/volva/crates/volva-runtime/src/lib.rs"

check "Volva backend session surface reads persisted execution sessions" \
  rg -q 'load_execution_session' "$ROOT/volva/crates/volva-cli/src/backend.rs"

check "Volva chat path can emit paused or resumed session state" \
  rg -q 'Paused|Resumed|chat_once_with_state_observer' "$ROOT/volva/crates/volva-cli/src/chat.rs" "$ROOT/volva/crates/volva-api/src/lib.rs"

check "Volva core uses non-timestamp execution session ids" \
  rg -q 'Uuid::new_v4|execution_session_id_generation_is_not_timestamp_shaped' "$ROOT/volva/crates/volva-core/src/lib.rs"

check "Volva has a dedicated paused-resumed persistence regression test" \
  rg -q 'persisted_chat_retry_transitions_capture_paused_then_resumed' "$ROOT/volva/crates/volva-cli/src/chat.rs"

check "Handoff step checklists are marked complete" \
  rg -q '\- \[x\] shared execution-session and workspace identity types exist' "$ROOT/.handoffs/archive/volva/execution-host-session-workspace-contract.md"

check "Handoff includes build and test proof" \
  rg -q 'Finished `dev` profile|Finished `test` profile|test result: ok\.' "$ROOT/.handoffs/archive/volva/execution-host-session-workspace-contract.md"

check "Handoff includes verify proof" \
  rg -q 'Results: [0-9]+ passed, 0 failed' "$ROOT/.handoffs/archive/volva/execution-host-session-workspace-contract.md"

printf 'Results: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
