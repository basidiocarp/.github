# Hymenium: Progress Monitoring and Recovery

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** hymenium/src/monitor.rs, hymenium/src/retry.rs
- **Cross-repo edits:** none
- **Non-goals:** workflow engine internals, dispatch logic, handoff parsing
- **Verification contract:** cargo test -p hymenium
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when complete

## Problem

Once a workflow is dispatched, hymenium needs to monitor progress and handle failures. Agents can stall (context exhaustion, drift into orchestration chatter, tool errors), and workflows can get stuck at phase gates. Today the operator manually watches for these problems and intervenes. Hymenium should detect stalls, attempt recovery, and escalate when automatic recovery fails.

## What exists (state)

- **Canopy heartbeat**: Agents send heartbeats; canopy tracks liveness
- **Canopy completeness check**: `canopy_check_handoff_completeness` counts checkboxes and paste markers
- **Workflow engine**: #118e provides phase state tracking and gate evaluation
- **Dispatch layer**: #118f links workflow phases to canopy tasks
- **SKILL.md hard gates**: "Do not treat status chatter as progress", "close stalled agents"

## What needs doing (intent)

Build the progress monitor and retry/recovery system.

---

### Step 1: Implement progress monitor

**Project:** `hymenium/`
**Effort:** 3-4 hours
**Depends on:** #118e (Workflow Engine), #118f (Canopy Dispatch)

Implement in `src/monitor.rs`:

```rust
pub struct ProgressMonitor {
    canopy: Box<dyn CanopyClient>,
    config: MonitorConfig,
}

pub struct MonitorConfig {
    pub heartbeat_timeout: Duration,      // default: 5 minutes
    pub progress_timeout: Duration,       // default: 30 minutes
    pub completeness_check_interval: Duration, // default: 2 minutes
}

pub enum ProgressSignal {
    Healthy { phase: String, last_activity: DateTime<Utc> },
    Stalled { phase: String, since: DateTime<Utc>, reason: StallReason },
    PhaseComplete { phase: String },
    GateSatisfied { gate: String },
    Failed { phase: String, error: String },
}

pub enum StallReason {
    HeartbeatTimeout,      // agent stopped sending heartbeats
    NoCodeDiff,            // time elapsed but no file changes
    NoPasteMarkerProgress, // verification sections still empty
    StatusChatterOnly,     // agent responding but no real work
}
```

The monitor should:
1. Poll canopy for task/agent state at configurable intervals
2. Check heartbeat freshness
3. Check for code diff progress (modified files in canopy task detail)
4. Check paste marker / checkbox progress via completeness check
5. Emit ProgressSignal events

#### Verification

```bash
cd hymenium && cargo test monitor 2>&1 | tail -10
```

**Checklist:**
- [ ] Monitor polls canopy at configurable intervals
- [ ] Heartbeat timeout detection works
- [ ] No-progress detection works (no diff, no paste markers)
- [ ] ProgressSignal events emitted correctly
- [ ] Tests pass with mock canopy client

---

### Step 2: Implement retry and recovery

**Project:** `hymenium/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Implement in `src/retry.rs`:

```rust
pub struct RetryPolicy {
    pub max_retries: u32,           // default: 2
    pub narrow_scope_on_retry: bool, // default: true
    pub escalate_tier_on_retry: bool, // default: false
}

pub enum RecoveryAction {
    Retry { narrowed_scope: Option<String>, new_tier: Option<AgentTier> },
    Escalate { reason: String },
    Cancel { reason: String },
}

pub fn decide_recovery(
    signal: &ProgressSignal,
    workflow: &WorkflowInstance,
    policy: &RetryPolicy,
) -> RecoveryAction;
```

Recovery logic:
1. First stall → retry with same scope
2. Second stall → retry with narrowed scope (fewer steps) or escalated tier
3. Third stall → escalate to operator (cancel with reason)
4. HeartbeatTimeout → close agent, retry immediately
5. StatusChatterOnly → close agent, narrow scope, retry
6. Failed → check if retryable, otherwise escalate

#### Verification

```bash
cd hymenium && cargo test retry 2>&1 | tail -10
```

**Checklist:**
- [ ] Recovery decisions based on stall type and retry count
- [ ] Scope narrowing on second retry
- [ ] Escalation on third failure
- [ ] Heartbeat timeout triggers immediate retry
- [ ] Status-chatter detection triggers scope narrowing
- [ ] Tests cover all recovery paths

---

### Step 3: Wire monitor into workflow lifecycle

**Project:** `hymenium/`
**Effort:** 2-3 hours
**Depends on:** Steps 1 and 2

Connect the monitor and retry system to the workflow engine:

1. After dispatch, start monitoring the active phase
2. On ProgressSignal::PhaseComplete → attempt gate check → advance to next phase
3. On ProgressSignal::Stalled → invoke recovery decision → execute action
4. On ProgressSignal::GateSatisfied → advance workflow
5. On RecoveryAction::Retry → close current agent, relaunch with new parameters
6. On RecoveryAction::Escalate → mark workflow as blocked, notify operator

#### Verification

```bash
cd hymenium && cargo test monitor 2>&1 | tail -10
cargo test retry 2>&1 | tail -10
```

**Checklist:**
- [ ] Monitor drives phase advancement
- [ ] Stall signals trigger recovery
- [ ] Recovery actions executed (retry, escalate, cancel)
- [ ] Workflow status updated throughout
- [ ] Tests cover full lifecycle with mock canopy

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output pasted
2. `cargo test` passes in `hymenium/`
3. All checklist items checked

## Context

Final piece of hymenium chain (#118g). Depends on #118e (workflow engine) and #118f (dispatch). Implements the "retry/recovery" and "progress monitoring" responsibilities from the hymenium design note. Automates the hard gates from SKILL.md: "Do not treat status chatter as progress", "close stalled agents", "narrow scope and relaunch."
