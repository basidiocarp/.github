# Cortina: Canonical Lifecycle Pipeline Stages

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** `cortina/src/` (pipeline module, stage registry)
- **Cross-repo edits:** none (this handoff defines the internal pipeline; septa contract for the stage schema is follow-on)
- **Non-goals:** does not replace existing hook types (PreToolUse, PostToolUse, Stop, SessionEnd); does not change hook registration in Claude Code; does not add new hooks to lamella
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by headroom's canonical lifecycle pipeline (audit: `.audit/external/audits/headroom-ecosystem-borrow-audit.md`) and corroborated by cognee's task-based pipeline composition:

> "Canonical 8-stage pipeline: Setup → Pre-Start → Post-Start → Input Received → Input Cached → Input Routed → Input Compressed → Input Remembered → Pre-Send → Post-Send → Response Received. Extensions observe/customize lifecycle stages at well-defined hooks."

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:**
  - `src/pipeline.rs` (new) — `PipelineStage` enum and `Pipeline` runner
  - `src/hooks/` — register stage handlers alongside existing hook capture logic
  - `src/lib.rs` or `src/main.rs` — wire pipeline into existing hook event flow
- **Reference seams:**
  - Existing hook capture in cortina — read `src/` first to understand the current hook event capture pattern before writing code
  - headroom `LifecyclePipeline` class as external reference (do not copy; understand the pattern)
- **Spawn gate:** read cortina's current hook event flow before spawning — identify where events are captured and dispatched today

## Problem

Cortina captures hook events (PreToolUse, PostToolUse, Stop, SessionEnd) but the internal processing is ad-hoc — each hook type has its own handling path without a shared pipeline abstraction. This means:

1. Adding observability (logging, metrics, memory write) to every stage requires modifying multiple independent paths
2. Extensions cannot register handlers at specific named stages
3. The lifecycle of a tool call (receive input → validate → dispatch → capture output → store) has no explicit representation

Headroom's insight: name the stages explicitly, give each a pre/post variant, and let handlers register at any stage. The pipeline becomes a composable, testable first-class object instead of scattered conditional code.

## What needs doing (intent)

Add a `PipelineStage` enum covering the lifecycle of a tool call through cortina. Add a `Pipeline` runner that executes registered handlers for each stage in order. Wire the existing hook event capture into the pipeline so that all existing behavior is preserved, but now expressed as named stage handlers.

## Stage taxonomy

```
ToolCallReceived     → input arrives at cortina from the hook
ToolCallValidated    → input passes schema/format checks
ToolCallDispatched   → tool is being executed
ToolCallCompleted    → tool execution finished (success or error)
OutputCaptured       → output captured from tool result
OutputFiltered       → output passed through mycelium/filter layer
OutputStored         → output written to hyphae or other store
SessionSignalEmitted → lifecycle signal (Stop, SessionEnd) emitted
```

Each stage has `pre_<stage>` and `post_<stage>` variants for before/after semantics.

## Scope

- **Allowed files:** `cortina/src/pipeline.rs` (new), relevant wiring in `cortina/src/`
- **Explicit non-goals:**
  - No changes to how hooks are registered in Claude Code settings or lamella
  - No new hook types exposed externally
  - No septa contract yet — pipeline is internal to cortina for now

---

### Step 0: Seam-finding pass

**Effort:** tiny
**Depends on:** nothing

Read cortina's source before writing any code. Answer:
1. How does cortina receive hook events today? (stdin, socket, IPC?)
2. Where is the current dispatch/routing logic?
3. What handler registration mechanism exists, if any?
4. What external dependencies are in scope (tokio, async-trait, etc.)?

Document findings in a comment block at the top of `src/pipeline.rs`.

---

### Step 1: Define PipelineStage and handler trait

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 0

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PipelineStage {
    ToolCallReceived,
    ToolCallValidated,
    ToolCallDispatched,
    ToolCallCompleted,
    OutputCaptured,
    OutputFiltered,
    OutputStored,
    SessionSignalEmitted,
}

/// A handler registered at one or more pipeline stages.
/// Handlers are called in registration order.
/// Returning an error from a handler logs a warning and continues (fail-open).
pub trait StageHandler: Send + Sync {
    fn stage(&self) -> PipelineStage;
    fn handle(&self, ctx: &PipelineContext) -> Result<(), Box<dyn std::error::Error>>;
}

pub struct PipelineContext {
    pub stage: PipelineStage,
    pub tool_name: Option<String>,
    pub agent_id: Option<String>,
    pub payload: serde_json::Value,
}
```

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Types compile
- [ ] Handler trait is object-safe

---

### Step 2: Implement the Pipeline runner

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 1

```rust
pub struct Pipeline {
    handlers: Vec<Box<dyn StageHandler>>,
}

impl Pipeline {
    pub fn new() -> Self { Pipeline { handlers: Vec::new() } }

    pub fn register(&mut self, handler: Box<dyn StageHandler>) {
        self.handlers.push(handler);
    }

    pub fn run(&self, ctx: &PipelineContext) {
        for handler in &self.handlers {
            if handler.stage() == ctx.stage {
                if let Err(e) = handler.handle(ctx) {
                    tracing::warn!(
                        stage = ?ctx.stage,
                        error = %e,
                        "pipeline handler failed (continuing)"
                    );
                }
            }
        }
    }
}
```

Fail-open is the invariant: a handler error must never block pipeline progress.

#### Verification

```bash
cd cortina && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `Pipeline::run` executes all matching handlers in order
- [ ] Error from one handler does not stop subsequent handlers

---

### Step 3: Wire existing hook capture into pipeline stages

**Project:** `cortina/`
**Effort:** medium
**Depends on:** Step 2 and Step 0 (seam identified)

At the existing hook event dispatch points, emit the appropriate pipeline stage:

```rust
let ctx = PipelineContext {
    stage: PipelineStage::ToolCallReceived,
    tool_name: Some(tool_name.to_string()),
    agent_id: event.agent_id.clone(),
    payload: serde_json::to_value(&event).unwrap_or_default(),
};
pipeline.run(&ctx);
// ... existing dispatch logic ...
let ctx = PipelineContext {
    stage: PipelineStage::ToolCallCompleted,
    ..ctx
};
pipeline.run(&ctx);
```

All existing behavior should be preserved — the pipeline adds observability around it, not replacing it.

#### Verification

```bash
cd cortina && cargo test 2>&1 | tail -20
```

**Checklist:**
- [ ] All existing tests still pass
- [ ] Pipeline stages are emitted at expected points

---

### Step 4: Add a logging handler as a concrete example

**Project:** `cortina/`
**Effort:** tiny
**Depends on:** Step 3

Register a `LoggingHandler` that emits a `tracing::debug!` for each stage. This proves the extension model works and gives operators a free observability layer.

```rust
struct LoggingHandler { stage: PipelineStage }

impl StageHandler for LoggingHandler {
    fn stage(&self) -> PipelineStage { self.stage }
    fn handle(&self, ctx: &PipelineContext) -> Result<(), Box<dyn std::error::Error>> {
        tracing::debug!(
            stage = ?ctx.stage,
            tool = ?ctx.tool_name,
            agent = ?ctx.agent_id,
            "pipeline stage"
        );
        Ok(())
    }
}
```

#### Verification

```bash
cd cortina && RUST_LOG=debug cargo run -- --help 2>&1 | grep "pipeline stage" | head -5
```

(Adapt to actual cortina invocation.)

**Checklist:**
- [ ] `LoggingHandler` registers and emits debug logs per stage

---

### Step 5: Unit tests

**Project:** `cortina/`
**Effort:** small
**Depends on:** Step 4

Test that handlers are called in order, that fail-open behavior works, and that stage filtering is correct.

```bash
cd cortina && cargo test pipeline 2>&1
```

**Checklist:**
- [ ] Handlers called in registration order
- [ ] Error from one handler does not stop subsequent handlers
- [ ] Handlers only called for their registered stage

---

### Step 6: Full suite

```bash
cd cortina && cargo test 2>&1 | tail -20
cd cortina && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd cortina && cargo fmt --check 2>&1
```

**Checklist:**
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The full test suite passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated to reflect completion

## Follow-on work (not in scope here)

- `septa/lifecycle-stage-v1.schema.json` — if stage events need to cross tool boundaries
- `hyphae` handler that writes stage events to hyphae at `OutputStored` stage
- `mycelium` integration at `OutputFiltered` stage (compression as a named stage handler)

## Context

Spawned from Wave 2 audit program (2026-04-23). headroom's canonical lifecycle pipeline and cognee's task composition both point to the same gap: cortina's hook event flow is ad-hoc. Naming the stages explicitly enables composable handlers, testable pipelines, and clear extension points for future tools (hyphae storage, mycelium compression) without requiring changes to cortina's core logic.
