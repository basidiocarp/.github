# Hymenium: Canopy Dispatch Integration

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** hymenium/src/dispatch.rs
- **Cross-repo edits:** none
- **Non-goals:** workflow engine internals, progress monitoring, decomposition
- **Verification contract:** cargo test -p hymenium
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when complete

## Problem

Hymenium's workflow engine knows what phases to execute, but it needs to actually create canopy tasks, assign agents, and track the mapping between workflow phases and canopy task IDs. This is the bridge between hymenium's workflow model and canopy's task ledger.

## What exists (state)

- **Canopy MCP tools**: 34 tools including canopy_task_create, canopy_task_assign, canopy_import_handoff
- **Canopy CLI**: `canopy task create`, `canopy task assign`, etc.
- **Workflow engine**: #118e provides WorkflowInstance with phases and gate checking
- **Handoff parser**: #118c provides ParsedHandoff with steps and metadata

## What needs doing (intent)

Build the dispatch layer that translates workflow phases into canopy operations.

---

### Step 1: Define canopy client interface

**Project:** `hymenium/`
**Effort:** 2-3 hours
**Depends on:** #118a (Crate Scaffold)

Define a trait-based canopy client in `src/dispatch.rs`:

```rust
pub trait CanopyClient {
    fn create_task(&self, title: &str, description: &str, project_root: &str, options: &TaskOptions) -> Result<String>;
    fn create_subtask(&self, parent_id: &str, title: &str, description: &str, options: &TaskOptions) -> Result<String>;
    fn assign_task(&self, task_id: &str, agent_id: &str) -> Result<()>;
    fn get_task(&self, task_id: &str) -> Result<TaskDetail>;
    fn check_completeness(&self, handoff_path: &str) -> Result<CompletenessReport>;
    fn import_handoff(&self, path: &str, assign_to: Option<&str>) -> Result<ImportResult>;
}

pub struct TaskOptions {
    pub required_role: Option<String>,
    pub required_capability: Option<String>,
    pub verification_required: bool,
}
```

Provide two implementations:
1. `CliCanopyClient` — shells out to `canopy` CLI commands
2. `MockCanopyClient` — for testing

#### Verification

```bash
cd hymenium && cargo build 2>&1 | tail -5
cargo test dispatch 2>&1 | tail -10
```

**Checklist:**
- [ ] CanopyClient trait defined with task CRUD operations
- [ ] CLI implementation shells out to canopy commands
- [ ] Mock implementation for testing
- [ ] Build passes

---

### Step 2: Implement dispatch orchestration

**Project:** `hymenium/`
**Effort:** 3-4 hours
**Depends on:** Step 1, #118e (Workflow Engine)

Implement `dispatch_workflow(request: &DispatchRequest, canopy: &dyn CanopyClient) -> Result<WorkflowInstance>`:

1. Parse the handoff document
2. Load the workflow template
3. Create a parent canopy task from the handoff
4. For each phase, create a canopy subtask with the appropriate role
5. Assign the first phase's agent (if agent tier is specified)
6. Return the WorkflowInstance with canopy task IDs linked to phases

Follow the dispatch-request-v1 schema for input.

#### Verification

```bash
cd hymenium && cargo test dispatch 2>&1 | tail -10
```

**Checklist:**
- [ ] Dispatch creates parent task + phase subtasks in canopy
- [ ] Phase subtasks have correct roles
- [ ] First phase assigned immediately
- [ ] Subsequent phases left unassigned (gated)
- [ ] WorkflowInstance linked to canopy task IDs
- [ ] Tests pass with mock canopy client

---

### Step 3: Implement agent naming

**Project:** `hymenium/`
**Effort:** 1-2 hours
**Depends on:** Step 2

Generate agent names following the ecosystem convention: `<role>/<repo>/<handoff-slug>/<run>`

```rust
pub fn agent_name(role: &str, repo: &str, handoff_slug: &str, run: u32) -> String {
    format!("{role}/{repo}/{handoff_slug}/{run}")
}
```

Extract `repo` from handoff metadata's owning_repo. Extract `handoff_slug` from the handoff filename. Track `run` in the workflow instance (starts at 1, increments on relaunch).

#### Verification

```bash
cd hymenium && cargo test dispatch::agent_name 2>&1 | tail -10
```

**Checklist:**
- [ ] Agent names follow `<role>/<repo>/<handoff-slug>/<run>` convention
- [ ] Role derived from workflow phase
- [ ] Repo derived from handoff metadata
- [ ] Run number tracked and incremented on relaunch
- [ ] Tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output pasted
2. `cargo test` passes in `hymenium/`
3. All checklist items checked

## Context

Part of hymenium chain (#118f). Depends on #118a (scaffold), #118c (parser), #118e (workflow engine). This is the canopy integration layer — it translates workflow phases into canopy tasks and manages the bidirectional mapping.
