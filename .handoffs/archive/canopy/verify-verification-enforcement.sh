#!/bin/bash
# Verification script for .handoffs/canopy/verification-enforcement.md

set -euo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CANOPY="$ROOT/canopy"
TMPDIR="$(mktemp -d)"
DB="$TMPDIR/canopy.db"
HANDOFF="$TMPDIR/verification-enforcement.md"
STEP_SCRIPT="$TMPDIR/verify-verification-enforcement.sh"
PARENT_SCRIPT="$TMPDIR/verify-parent.sh"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

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

check_fails() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  FAIL: $desc"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  fi
}

extract_task_id() {
  local position="$1"
  local file="$2"
  sed -n "${position}p" "$file" | sed -E 's/.*"([^"]+)".*/\1/'
}

cat >"$HANDOFF" <<'EOF'
# Handoff: Example Handoff

### Step 1: First step
Implement the first step.

### Step 2: Second step
Implement the second step.
EOF

cat >"$STEP_SCRIPT" <<'EOF'
#!/bin/bash
set -euo pipefail
echo "=== Example Verification ==="
echo "--- Step 1: First step ---"
echo "  PASS: first step"
echo "--- Step 2: Second step ---"
echo "  FAIL: second step"
echo "Results: 1 passed, 1 failed"
exit 1
EOF

cat >"$PARENT_SCRIPT" <<'EOF'
#!/bin/bash
set -euo pipefail
echo "=== Example Verification ==="
echo "--- Step 1: First step ---"
echo "  PASS: first step"
echo "--- Step 2: Second step ---"
echo "  PASS: second step"
echo "Results: 2 passed, 0 failed"
EOF

chmod +x "$STEP_SCRIPT" "$PARENT_SCRIPT"

echo "=== HANDOFF-CANOPY-VERIFICATION-ENFORCEMENT Verification ==="
echo

IMPORT_JSON="$TMPDIR/import.json"
(cd "$CANOPY" && cargo run --quiet -- --db "$DB" import-handoff "$HANDOFF") >"$IMPORT_JSON"
TASK_IDS="$TMPDIR/task-ids.txt"
rg -o '"task_id": "[^"]+"' "$IMPORT_JSON" >"$TASK_IDS"
PARENT_ID="$(extract_task_id 1 "$TASK_IDS")"
STEP1_ID="$(extract_task_id 2 "$TASK_IDS")"
STEP2_ID="$(extract_task_id 3 "$TASK_IDS")"

echo "--- Step 1: ScriptVerification Evidence Kind ---"
check "ScriptVerification variant exists in models.rs" \
  "rg -n 'ScriptVerification' '$CANOPY/src/models.rs'"
check "evidence verification reports script failures" \
  "cd '$CANOPY' && cargo run --quiet -- --db '$DB' task verify --task-id '$STEP1_ID' --script '$STEP_SCRIPT' --step 'Step 1' >/dev/null && cargo run --quiet -- --db '$DB' evidence verify --task-id '$STEP1_ID' > '$TMPDIR/evidence-verify.json' && rg '\"source_kind\": \"script_verification\"' '$TMPDIR/evidence-verify.json' && rg '\"status\": \"verified\"' '$TMPDIR/evidence-verify.json'"

echo
echo "--- Step 2: canopy task verify --script ---"
check "task verify completes a passing leaf task" \
  "cd '$CANOPY' && cargo run --quiet -- --db '$DB' task show --task-id '$STEP1_ID' > '$TMPDIR/step1-task.json' && rg '\"status\": \"completed\"' '$TMPDIR/step1-task.json' && rg '\"verification_state\": \"passed\"' '$TMPDIR/step1-task.json'"
check "step filtering allows one passing section from a failing overall script" \
  "cd '$CANOPY' && cargo run --quiet -- --db '$DB' evidence list --task-id '$STEP1_ID' | rg 'Verification script \\(Step 1\\)'"
check_fails "task verify exits non-zero for a failing step" \
  "cd '$CANOPY' && cargo run --quiet -- --db '$DB' task verify --task-id '$STEP2_ID' --script '$STEP_SCRIPT' --step 'Step 2'"

echo
echo "--- Step 3: Completion Gate ---"
UNGATED_JSON="$TMPDIR/ungated.json"
(cd "$CANOPY" && cargo run --quiet -- --db "$DB" task create --title 'Needs verification' --requested-by operator --project-root /tmp/project --verification-required) >"$UNGATED_JSON"
UNGATED_ID="$(rg -o '\"task_id\": \"[^\"]+\"' "$UNGATED_JSON" | sed -E 's/.*"([^"]+)".*/\1/')"
check "verification-required task can enter in-progress normally" \
  "cd '$CANOPY' && cargo run --quiet -- --db '$DB' task status --task-id '$UNGATED_ID' --status in_progress --changed-by operator | rg '\"status\": \"in_progress\"'"
check_fails "verification-required task cannot complete without script evidence" \
  "cd '$CANOPY' && cargo run --quiet -- --db '$DB' task status --task-id '$UNGATED_ID' --status completed --changed-by operator --verification-state passed --closure-summary done"

echo
echo "--- Step 4: import-handoff Command ---"
check "import-handoff creates a verification-required parent task" \
  "rg '\"verification_required\": true' '$IMPORT_JSON'"
check "import-handoff creates subtasks for each step" \
  "grep -c '\"task_id\":' \"$IMPORT_JSON\" | rg '^3$'"
check "import-handoff attaches verification command notes" \
  "cd '$CANOPY' && cargo run --quiet -- --db '$DB' evidence list --task-id '$PARENT_ID' | rg 'Verification command'"

echo
echo "--- Step 5: Parent Auto-Completion ---"
check "verified parent stays open until all children are complete" \
  "cd '$CANOPY' && cargo run --quiet -- --db '$DB' task verify --task-id '$PARENT_ID' --script '$PARENT_SCRIPT' >/dev/null && cargo run --quiet -- --db '$DB' task show --task-id '$PARENT_ID' | rg '\"status\": \"open\"'"
check "final child completion auto-completes a verified parent" \
  "cd '$CANOPY' && cargo run --quiet -- --db '$DB' task verify --task-id '$STEP2_ID' --script '$PARENT_SCRIPT' --step 'Step 2' >/dev/null && cargo run --quiet -- --db '$DB' task show --task-id '$PARENT_ID' | rg '\"status\": \"completed\"'"

echo
echo "--- Build Verification ---"
check "cargo test passes" \
  "cd '$CANOPY' && cargo test --quiet"
check "cargo clippy exits 0" \
  "cd '$CANOPY' && cargo clippy --all-targets --quiet >/dev/null"

echo
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
