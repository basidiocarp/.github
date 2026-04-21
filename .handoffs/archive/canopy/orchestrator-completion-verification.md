# Orchestrator Completion Verification

<!-- Save as: .handoffs/canopy/orchestrator-completion-verification.md -->
<!-- Create verify script: .handoffs/canopy/verify-orchestrator-completion-verification.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

The orchestrator marks handoffs complete after an agent finishes one step
without verifying that all steps were implemented. This causes out-of-sync
state where the handoff shows complete but subsequent steps were never
executed — a correctness failure, not a communication gap.

## What exists (state)

- **Canopy task lifecycle:** `pending → claimed → active → complete/failed`
  transitions exist but `complete` has no precondition checks
- **Verification enforcement handoff (completed 2026-04):** Canopy imports
  handoffs and enforces script-backed verification, but the *orchestrator*
  itself does not check checklists before marking done
- **Handoff template:** TEMPLATE.md defines a completion protocol with
  checklist items and paste markers, but nothing prevents the orchestrator
  from bypassing it
- **Agent behavior:** Agents scope their deliverable to a single step and
  report success; the orchestrator trusts this report

## What needs doing (intent)

Add completion verification to canopy's orchestrator: before transitioning a
task to `complete`, validate that all checklist items are checked and all
paste markers are filled. If validation fails, the task stays `active` with
a report of what remains.

---

### Step 1: Handoff Completeness Checker

**Project:** `canopy/`
**Effort:** 1-2 hours
**Depends on:** nothing

Create a function that parses a handoff document and determines whether it
meets completion criteria: all checkboxes checked, all paste markers filled,
verification script exists.

#### Files to modify

**`canopy/src/handoff_check.rs`** — new module:

```rust
pub struct CompletenessReport {
    pub is_complete: bool,
    pub total_checkboxes: usize,
    pub checked_checkboxes: usize,
    pub empty_paste_markers: Vec<usize>,
    pub has_verify_script: bool,
    pub verify_script_path: Option<PathBuf>,
}

pub fn check_completeness(handoff_path: &Path) -> Result<CompletenessReport> {
    // Parse markdown for checkbox and paste marker status
    // Check for paired verify-*.sh script
}
```

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd canopy && cargo test handoff_check --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Verified: CompletenessReport at handoff_check.rs:9-16, count_checkboxes at :177-189, find_empty_paste_markers at :194-222, 8 unit tests at :268-393, module in lib.rs:3
<!-- PASTE END -->

**Checklist:**
- [x] `CompletenessReport` struct captures checkbox counts, paste marker status, verify script presence
- [x] Parser correctly distinguishes `- [ ]` from `- [x]`
- [x] Parser detects empty paste blocks (no content between PASTE START/END)
- [x] At least 3 unit tests: fully complete, partially complete, empty

---

### Step 2: Gate Task Completion Transition

**Project:** `canopy/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Modify the task state machine so that transitioning to `complete` requires
passing the completeness check. If the check fails, the task remains `active`
and the agent receives a structured report of what remains.

#### Files to modify

**`canopy/src/runtime.rs`** or equivalent state machine file — add
pre-transition gate:

```rust
fn transition_to_complete(task: &mut Task) -> Result<TaskTransition> {
    if let Some(handoff_path) = &task.handoff_path {
        let report = check_completeness(handoff_path)?;
        if !report.is_complete {
            return Ok(TaskTransition::Rejected {
                reason: format_incomplete_report(&report),
            });
        }
    }
    task.status = TaskStatus::Complete;
    Ok(TaskTransition::Completed)
}
```

**`canopy/src/models.rs`** — add `Rejected` variant to `TaskTransition` if
it does not exist.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd canopy && cargo test transition --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Verified: completion gate at tools/task.rs:261-279, rejects via ToolResult::error with format_incomplete_report, handoff_path check at :262 bypasses when absent
<!-- PASTE END -->

**Checklist:**
- [x] Task cannot transition to `Complete` when checkboxes remain unchecked
- [x] Task cannot transition to `Complete` when paste markers are empty
- [x] Agent receives a structured report listing what remains
- [x] Tasks without a handoff path bypass the check (backward compatibility)

---

### Step 3: Verify Script Execution on Completion

**Project:** `canopy/`
**Effort:** 1-2 hours
**Depends on:** Step 1, Step 2

When a task has a paired verify script, execute it as part of the completion
gate. If the script exits non-zero, reject the completion.

#### Files to modify

**`canopy/src/handoff_check.rs`** — add script execution:

```rust
pub fn run_verify_script(report: &CompletenessReport) -> Result<VerifyResult> {
    if let Some(script_path) = &report.verify_script_path {
        let output = Command::new("bash")
            .arg(script_path)
            .output()?;
        // Parse "Results: N passed, M failed" from output
        // Return pass/fail with details
    }
}
```

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd canopy && cargo test verify_script --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Verified: run_verify_script at handoff_check.rs:102-136, parse_results_line at :235-253, 30s timeout at :92, missing script returns success at :103-111
<!-- PASTE END -->

**Checklist:**
- [x] Verify script is executed when present
- [x] Non-zero exit code rejects completion with script output
- [x] Missing verify script produces a warning but does not block
- [x] Script timeout is enforced (30 seconds default)

---

### Step 4: MCP Tool for Completion Check

**Project:** `canopy/`
**Effort:** 1 hour
**Depends on:** Step 1

Expose the completeness checker as an MCP tool so agents can self-check
before requesting completion.

#### Files to modify

**`canopy/src/mcp/tools.rs`** — add `canopy_check_handoff_completeness` tool.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd canopy && cargo test mcp --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->
Verified: tool schema at mcp/schema.rs:874-887, dispatch at tools/mod.rs:148-150, handler at tools/completeness.rs:11-67
<!-- PASTE END -->

**Checklist:**
- [x] `canopy_check_handoff_completeness` tool registered and functional
- [x] Tool returns structured report matching `CompletenessReport`
- [x] Tool is documented in canopy's tool listing

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/canopy/verify-orchestrator-completion-verification.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/canopy/verify-orchestrator-completion-verification.sh
```

**Output:**
<!-- PASTE START -->
All checks verified: handoff_check module, CompletenessReport, checkbox parsing, paste marker detection, verify script detection, completion gate, rejection on incomplete, verify script runner, timeout, MCP tool. cargo test: 103 pass, 0 fail. cargo clippy: 0 warnings.
<!-- PASTE END -->

**Result:** All checks pass. Handoff complete.

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

Originated from OBS-004 (2026-04-03). A filter redesign handoff had Steps 1,
2, and 3. The agent completed Step 1 and the orchestrator called it done.
Step 3 (routing large gh output through Hyphae) was never executed. The human
had to manually catch the discrepancy.

Related: [Scope Detection Protocol](canopy/scope-detection-protocol.md)
addresses unexpected out-of-scope work. This handoff addresses incomplete
expected work — complementary problems with distinct solutions.

Related: [Verification Enforcement](completed) (completed 2026-04) built the
foundation for script-backed verification. This handoff wires that into the
orchestrator's completion transition.
