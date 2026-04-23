# Canopy: Task Output Envelope

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/tasks/` (new output types), `canopy/src/tools/` (update task result tool)
- **Cross-repo edits:** `septa/task-output-v1.schema.json` (new schema — create alongside)
- **Non-goals:** does not implement LLM-specific output parsing (raw string passthrough only); does not add training or evaluation loops; does not change existing canopy task status model
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Extracted from the crewAI ecosystem borrow audit (`.audit/external/audits/crewai-ecosystem-borrow-audit.md`):

> "Tasks produce structured TaskOutput with raw, JSON, and Pydantic variants, plus token usage tracking. CrewOutput wraps all outputs from a crew, preserving per-task results."

> "Best fit: `septa` (contract), `canopy` (orchestration owner)."

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:**
  - `src/tasks/output.rs` (new) — `TaskOutput`, `TokenUsage`, `TaskResult` types
  - `src/tools/task_tools.rs` — update `canopy_task_complete` to accept and store output
  - `septa/task-output-v1.schema.json` (new, cross-repo) — JSON Schema for the envelope
- **Reference seams:**
  - `canopy/src/tasks/` — read existing task handling before adding output types
  - `canopy/src/store/` — understand how task state is stored today
- **Spawn gate:** read existing task complete path before spawning

## Problem

Canopy's `canopy_task_complete` tool today marks a task done with no structured output. There is no way to carry the result of a task (the text the agent produced, token usage, whether it was a JSON result) from completion into downstream tasks or into the operator dashboard.

crewAI shows that the right primitive is a `TaskOutput` with three representation tiers (raw string, parsed JSON, typed result) plus a `TokenUsage` struct. This gives downstream nodes and operators the data they need without requiring them to re-parse the agent's output.

## What needs doing (intent)

1. Define `TokenUsage` struct (prompt_tokens, completion_tokens, tool_calls)
2. Define `TaskOutput` struct with raw + json + typed + usage
3. Define `TaskResult` enum wrapping the completion outcome
4. Update `canopy_task_complete` to accept an optional output payload
5. Create the paired `septa/task-output-v1.schema.json` schema

## Output model

```rust
/// Token usage for a single task execution.
#[derive(Debug, Clone, Default, serde::Serialize, serde::Deserialize)]
pub struct TokenUsage {
    pub prompt_tokens: u32,
    pub completion_tokens: u32,
    /// Number of tool calls made during this task.
    pub tool_calls: u32,
}

/// Structured output from a completed task.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct TaskOutput {
    /// Raw agent output as a string (always present).
    pub raw: String,
    /// Parsed JSON if the agent returned structured data.
    pub json: Option<serde_json::Value>,
    /// Token usage for this task execution.
    pub usage: TokenUsage,
}

/// The result of completing a canopy task.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(tag = "status", rename_all = "snake_case")]
pub enum TaskResult {
    /// Task completed with output.
    Success(TaskOutput),
    /// Task failed with an error message.
    Failed { reason: String },
    /// Task was intentionally skipped (e.g., all inputs were already complete).
    Skipped { reason: String },
}
```

## Schema (septa/task-output-v1.schema.json)

The septa schema should define the JSON serialization of `TaskOutput` and `TokenUsage` so other tools can deserialize task results without depending on canopy's Rust types:

Required fields: `schema_version` (const "task-output-v1"), `status` (success|failed|skipped), `raw`.
Optional fields: `json` (object or null), `usage` (prompt_tokens, completion_tokens, tool_calls), `reason` (for failed/skipped).

## Tool update

`canopy_task_complete(task_id: str, output?: TaskOutput) → {}`

When `output` is provided, store it alongside the task status update. When absent (backward-compatible), mark complete with no output.

Add a new `canopy_task_output(task_id: str) → TaskOutput | null` tool to retrieve stored output.

## Scope

- **Allowed files:** `canopy/src/tasks/output.rs` (new), `canopy/src/tools/task_tools.rs` (update complete tool + add output tool), `canopy/src/store/schema.rs` (add output column to tasks table), `septa/task-output-v1.schema.json` (new)
- **Explicit non-goals:**
  - No LLM-specific output parsers (raw string passthrough only)
  - No typed "Pydantic-style" schema validation of task output content
  - No changes to task status state machine

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Before writing code, read:
1. `canopy/src/tasks/` — what does the current task struct look like? What fields exist?
2. `canopy/src/tools/task_tools.rs` — what does `canopy_task_complete` accept today?
3. `canopy/src/store/schema.rs` — what columns exist on the tasks table?

---

### Step 1: Define output types

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 0

Create `src/tasks/output.rs` with `TokenUsage`, `TaskOutput`, `TaskResult`.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `TokenUsage` compiles with Default + serde
- [ ] `TaskOutput` compiles with serde
- [ ] `TaskResult` enum compiles with tag = "status"

---

### Step 2: Add output column to tasks table

**Project:** `canopy/`
**Effort:** tiny
**Depends on:** Step 1

Add `output TEXT` column to the tasks table in `src/store/schema.rs`. Add migration.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Tasks table has `output` column (JSON, nullable)
- [ ] Migration runs cleanly on existing DB

---

### Step 3: Update task_complete tool and add task_output tool

**Project:** `canopy/`
**Effort:** small
**Depends on:** Step 2

Update `canopy_task_complete` to accept optional `output` JSON parameter. Store serialized `TaskOutput` in the new column. Add `canopy_task_output(task_id)` tool that returns the stored output or null.

#### Verification

```bash
cd canopy && cargo build 2>&1 | tail -5
cd canopy && cargo test task_output 2>&1
```

**Checklist:**
- [ ] `canopy_task_complete` accepts optional output (backward-compatible when omitted)
- [ ] `canopy_task_output` returns stored output or null
- [ ] Round-trip: complete with output → retrieve output

---

### Step 4: Write the septa schema

**Project:** `septa/`
**Effort:** tiny
**Depends on:** Step 3

Create `septa/task-output-v1.schema.json` and `septa/task-output-v1.fixture.json`. Add to `validate-all.sh`.

#### Verification

```bash
cd septa && bash validate-all.sh 2>&1 | tail -5
```

**Checklist:**
- [ ] Schema defines success/failed/skipped variants
- [ ] Fixture covers all three TaskResult variants
- [ ] validate-all.sh passes

---

### Step 5: Full suite

```bash
cd canopy && cargo test 2>&1 | tail -20
cd canopy && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd canopy && cargo fmt --check 2>&1
cd septa && bash validate-all.sh 2>&1 | tail -5
```

**Checklist:**
- [ ] All canopy tests pass
- [ ] Clippy clean
- [ ] Fmt clean
- [ ] septa validates

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output
2. Full test suite passes in canopy
3. septa schema validates
4. All checklist items checked
5. `.handoffs/HANDOFFS.md` updated

## Follow-on work (not in scope here)

- `cap`: surface TaskOutput in the operator dashboard (task result preview)
- `hyphae`: store TaskOutput in memory when instructed (link task results to memory entries)
- Typed output: add schema validation for task output content (e.g., require JSON-schema-valid output)
- Multi-task `CrewOutput` wrapper: aggregate output from all tasks in a graph run

## Context

Spawned from Wave 2 audit program (2026-04-23). crewAI's TaskOutput shows that a three-tier representation (raw string / parsed JSON / typed) covers the full range of what agents produce. The key primitive is `usage: TokenUsage` — tracking prompt_tokens, completion_tokens, and tool_calls per task gives the operator dashboard the data it needs for cost tracking without requiring a separate telemetry system. The design is additive: existing `canopy_task_complete` callers that omit output continue to work.
