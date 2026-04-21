# Scope Detection Protocol

<!-- Save as: .handoffs/canopy/scope-detection-protocol.md -->
<!-- Create verify script: .handoffs/canopy/verify-scope-detection-protocol.sh -->
<!-- Update index: .handoffs/HANDOFFS.md -->

## Problem

When an agent encounters work outside the active handoff scope, there is no
protocol to follow. The agent either drifts into out-of-scope territory,
surfaces it as "future work" and stops, or waits for human direction. This
forces manual intervention to split handoffs and update statuses, wasting
agent and operator time.

## What exists (state)

- **Canopy handoff schema:** `canopy/src/models.rs` defines `Task` with status
  fields but no `blocked` or `on-hold` state for scope gaps
- **Canopy state machine:** Task lifecycle handles `pending → claimed → active →
  complete/failed` but has no transition for scope-blocked
- **Agent behavior:** Agents either continue into out-of-scope work or stop with
  a "future work" note — no structured classification step
- **Child handoffs:** No mechanism for agents to create child handoffs from
  within a session

## What needs doing (intent)

Define a first-class scope-detection protocol in canopy's handoff state machine:
agent detects out-of-scope work, classifies it as blocking or non-blocking,
and either continues (non-blocking) or creates a child handoff and pauses
(blocking). The protocol should be expressible in the handoff schema and
enforceable by canopy's runtime.

---

### Step 1: Add Scope-Blocked Status to Task Model

**Project:** `canopy/`
**Effort:** 1-2 hours
**Depends on:** nothing

Add a `Blocked` variant to the task status enum with a reason field. Add a
`parent_task_id` optional field to `Task` for child handoff linkage.

#### Files to modify

**`canopy/src/models.rs`** — add `Blocked` status variant and parent linkage:

```rust
// Add to TaskStatus enum:
Blocked { reason: String, child_task_id: Option<String> },

// Add to Task struct:
pub parent_task_id: Option<String>,
```

**`canopy/src/store/schema.rs`** — add `parent_task_id` column and update
status serialization to handle `blocked` with reason.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd canopy && cargo test --quiet 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `TaskStatus::Blocked` variant exists with `reason` and optional `child_task_id`
- [ ] `Task` struct has `parent_task_id: Option<String>` field
- [ ] Schema migration adds `parent_task_id` column
- [ ] Existing tests still pass

---

### Step 2: Implement Scope Classification Logic

**Project:** `canopy/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Create a `scope.rs` module (or extend existing scope logic) with functions to:
1. Compare a work item description against the handoff's declared scope
2. Classify a scope gap as blocking (work cannot proceed without it) or
   non-blocking (work can continue, gap is additive)

#### Files to modify

**`canopy/src/scope.rs`** — add classification functions:

```rust
pub enum ScopeGap {
    Blocking { description: String },
    NonBlocking { description: String },
}

pub fn classify_scope_gap(
    work_item: &str,
    handoff_scope: &[String],
) -> Option<ScopeGap> {
    // Check if work_item references files/modules outside handoff_scope
    // Return None if in scope, Some(gap) if out of scope
}
```

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd canopy && cargo test scope --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `ScopeGap` enum with `Blocking` and `NonBlocking` variants exists
- [ ] `classify_scope_gap` function compares work items against declared scope
- [ ] At least 3 unit tests cover: in-scope, blocking gap, non-blocking gap

---

### Step 3: Add State Machine Transitions for Scope Gaps

**Project:** `canopy/`
**Effort:** 2-3 hours
**Depends on:** Step 1, Step 2

Wire the scope classification into canopy's task state machine. When an agent
reports a scope gap:
- Non-blocking: log the gap, continue to next step
- Blocking: transition task to `Blocked`, create a child task for the
  out-of-scope work, surface to operator

#### Files to modify

**`canopy/src/runtime.rs`** or equivalent state machine file — add transition
handlers:

```rust
fn handle_scope_gap(task: &mut Task, gap: ScopeGap) -> TaskTransition {
    match gap {
        ScopeGap::NonBlocking { description } => {
            log_scope_note(task, &description);
            TaskTransition::Continue
        }
        ScopeGap::Blocking { description } => {
            let child = create_child_task(task, &description);
            task.status = TaskStatus::Blocked {
                reason: description,
                child_task_id: Some(child.id.clone()),
            };
            TaskTransition::Pause { child_task: child }
        }
    }
}
```

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd canopy && cargo test --quiet 2>&1 | tail -5
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Non-blocking gaps log a note and continue
- [ ] Blocking gaps transition task to `Blocked` status
- [ ] Blocking gaps create a child task linked to parent
- [ ] Child task has `parent_task_id` set to the blocked parent's ID

---

### Step 4: Expose Scope Detection via MCP Tools

**Project:** `canopy/`
**Effort:** 1-2 hours
**Depends on:** Step 3

Add MCP tools so agents can report scope gaps from within a session:
- `canopy_report_scope_gap` — agent reports a gap with blocking/non-blocking
  classification
- `canopy_get_handoff_scope` — agent retrieves the declared scope for the
  active handoff to compare against

#### Files to modify

**`canopy/src/mcp/tools.rs`** — add tool definitions and handlers.

#### Verification

<!-- AGENT: Run the command and paste output between the markers -->
```bash
cd canopy && cargo test mcp --quiet 2>&1 | tail -10
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] `canopy_report_scope_gap` tool registered and functional
- [ ] `canopy_get_handoff_scope` tool registered and functional
- [ ] Tools are documented in canopy's tool listing

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/canopy/verify-scope-detection-protocol.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/canopy/verify-scope-detection-protocol.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

Originated from OBS-001 (2026-04-03). When an agent hit work in
`src/vcs/gh_cmd/` and `src/vcs/gh_pr/` instead of the expected
`src/filters/gh.rs`, it surfaced "future work" and stopped. The human had
to manually split the handoff and decide whether to block the parent. This
protocol makes that decision structured and agent-driven.

Related: [Orchestrator Completion Verification](canopy/orchestrator-completion-verification.md)
addresses a complementary problem — incomplete expected work rather than
unexpected out-of-scope work.
