#!/usr/bin/env bash
set -euo pipefail
PASS=0; FAIL=0
ROOT="/Users/williamnewton/projects/basidiocarp"

check() {
  local name="$1"
  shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
    PASS=$((PASS+1))
  else
    printf 'FAIL: %s\n' "$name"
    FAIL=$((FAIL+1))
  fi
}

# Check: cargo build --workspace succeeds
check "cargo build --release" \
  bash -c "cd '$ROOT/canopy' && cargo build --release >/dev/null 2>&1"

# Check: cargo test --workspace passes
check "cargo test --workspace" \
  bash -c "cd '$ROOT/canopy' && cargo test >/dev/null 2>&1"

# Check: list_open_child_tasks method exists in Store impl
check "list_open_child_tasks exists in Store" \
  grep -q "pub fn list_open_child_tasks" "$ROOT/canopy/src/store/tasks.rs"

# Check: list_open_child_tasks exists in TaskLookupStore trait
check "list_open_child_tasks in TaskLookupStore trait" \
  grep -q "fn list_open_child_tasks" "$ROOT/canopy/src/store/traits.rs"

# Check: --tree flag exists in TaskCommand enum
check "--tree flag in TaskCommand" \
  grep -q "tree: bool" "$ROOT/canopy/src/cli.rs"

# Check: render_task_tree function exists
check "render_task_tree function exists" \
  grep -q "fn render_task_tree" "$ROOT/canopy/src/app.rs"

# Check: import-handoff command already exists
check "import-handoff command exists" \
  grep -q "ImportHandoff {" "$ROOT/canopy/src/cli.rs"

# Check: handle_import_handoff function exists
check "handle_import_handoff function exists" \
  grep -q "fn handle_import_handoff" "$ROOT/canopy/src/app.rs"

# Check: open children check in task complete handler
check "open children guard in CLI handler" \
  grep -q "list_open_child_tasks" "$ROOT/canopy/src/app.rs"

# Check: open children check in MCP tool
check "open children guard in MCP tool" \
  grep -q "list_open_child_tasks" "$ROOT/canopy/src/tools/task.rs"

printf '\nResults: %d passed, %d failed\n' "$PASS" "$FAIL"
test "$FAIL" -eq 0
