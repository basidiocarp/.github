# Hymenium: Workflow Template Engine

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** hymenium/src/workflow/...
- **Cross-repo edits:** none
- **Non-goals:** canopy integration, progress monitoring, retry logic
- **Verification contract:** cargo test -p hymenium
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when complete

## Problem

The implementer/auditor workflow is currently defined in prose (SKILL.md, AGENTS.md, CLAUDE.md). Hymenium needs this as a machine-readable workflow template with phases, gates, and transitions that the engine can execute. The workflow-template-v1 septa contract (#118b) defines the schema — this handoff implements the engine that loads, validates, and executes those templates.

## What exists (state)

- **SKILL.md**: 10-step implementer/auditor protocol with hard gates
- **workflow-template-v1.schema.json**: #118b defines the contract schema
- **Workflow module stubs**: #118a creates src/workflow/ with template.rs, engine.rs, gate.rs

## What needs doing (intent)

Implement the workflow template engine: load templates from septa, execute phase transitions, and enforce gates.

---

### Step 1: Implement template loader

**Project:** `hymenium/`
**Effort:** 2-3 hours
**Depends on:** #118a (Crate Scaffold), #118b (Septa Contracts)

Implement in `src/workflow/template.rs`:

1. Load workflow templates from a templates directory or bundled defaults
2. Parse JSON matching workflow-template-v1 schema
3. Validate phase references in transitions (no dangling phase_ids)
4. Provide a `get_template(id: &str) -> Result<WorkflowTemplate>` lookup
5. Bundle the implementer/auditor template as a built-in default

```rust
pub struct WorkflowTemplate {
    pub template_id: String,
    pub name: String,
    pub description: String,
    pub phases: Vec<Phase>,
    pub transitions: Vec<Transition>,
}

pub struct Phase {
    pub phase_id: String,
    pub role: AgentRole,
    pub agent_tier: AgentTier,
    pub entry_gate: Gate,
    pub exit_gate: Gate,
}

pub struct Gate {
    pub requires: Vec<GateCondition>,
}

pub enum GateCondition {
    CodeDiffExists,
    VerificationPassed,
    AuditClean,
    FindingsResolved,
    Custom(String),
}
```

#### Verification

```bash
cd hymenium && cargo test workflow::template 2>&1 | tail -10
```

**Checklist:**
- [ ] Templates loaded from JSON
- [ ] Built-in implementer/auditor template available
- [ ] Phase reference validation works
- [ ] Invalid templates rejected with clear error
- [ ] Tests pass

---

### Step 2: Implement workflow state machine

**Project:** `hymenium/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Implement in `src/workflow/engine.rs`:

1. `WorkflowInstance` — a running instance of a template for a specific handoff
2. State machine: pending → dispatched → phase transitions → completed/failed
3. `advance()` — attempt to move to the next phase, checking exit gates
4. `can_advance()` — check if current phase exit gates are satisfied
5. `current_phase()` — return active phase info
6. Phase history tracking (when each phase started/completed)

```rust
pub struct WorkflowInstance {
    pub workflow_id: String,
    pub template: WorkflowTemplate,
    pub handoff_path: String,
    pub status: WorkflowStatus,
    pub current_phase_idx: usize,
    pub phase_states: Vec<PhaseState>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

pub struct PhaseState {
    pub phase_id: String,
    pub status: PhaseStatus,
    pub agent_id: Option<String>,
    pub canopy_task_id: Option<String>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
}

pub enum PhaseStatus {
    Pending,
    Active,
    Completed,
    Failed,
    Skipped,
}
```

#### Verification

```bash
cd hymenium && cargo test workflow::engine 2>&1 | tail -10
```

**Checklist:**
- [ ] WorkflowInstance tracks phase state
- [ ] State machine enforces phase ordering
- [ ] Gate checking prevents premature advancement
- [ ] Phase history recorded with timestamps
- [ ] Tests cover happy path and gate rejection

---

### Step 3: Implement phase gating

**Project:** `hymenium/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Implement in `src/workflow/gate.rs`:

Gate condition evaluation — each GateCondition maps to a concrete check:

- `CodeDiffExists` → query canopy task for modified files, or check git status
- `VerificationPassed` → query canopy handoff completeness, check paste markers filled
- `AuditClean` → auditor phase completed with no findings
- `FindingsResolved` → all audit findings addressed and re-verified
- `Custom(expr)` → extensible for future gate types

```rust
pub trait GateEvaluator {
    fn evaluate(&self, condition: &GateCondition, context: &WorkflowContext) -> Result<bool>;
}
```

The evaluator is a trait so it can be mocked in tests and swapped for a real canopy-backed implementation later.

#### Verification

```bash
cd hymenium && cargo test workflow::gate 2>&1 | tail -10
```

**Checklist:**
- [ ] GateEvaluator trait defined
- [ ] Each GateCondition has evaluation logic
- [ ] Mock evaluator available for tests
- [ ] Gate failures return clear reasons
- [ ] Tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output pasted
2. `cargo test` passes in `hymenium/`
3. All checklist items checked

## Context

Part of hymenium chain (#118e). Depends on #118a (scaffold) and #118b (septa contracts). This is the core engine — it turns the prose protocol in SKILL.md into executable workflow logic. The dispatch handoff (#118f) uses this engine to drive actual agent work.
