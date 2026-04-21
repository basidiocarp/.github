# Hymenium: Handoff Decomposition

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hymenium`
- **Allowed write scope:** hymenium/src/decompose.rs
- **Cross-repo edits:** none
- **Non-goals:** workflow engine, canopy integration, dispatch
- **Verification contract:** cargo test -p hymenium
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when complete

## Problem

Large handoffs with many steps and high total effort stall smaller agents. When a handoff has 6+ steps or >8 hours total effort, it should be split into focused child handoffs that haiku-tier agents can complete without context exhaustion. Today this splitting is done manually by the operator.

## What exists (state)

- **Handoff parser**: #118c extracts the full handoff structure including steps, effort, dependencies
- **WORK-ITEM-TEMPLATE.md**: Defines the handoff format that decomposed pieces should follow
- **Manual splitting**: Operator reads large handoffs and creates child handoffs by hand

## What needs doing (intent)

Build a decomposition engine that takes a parsed handoff and splits it into focused child handoffs based on effort estimates, step dependencies, and project boundaries.

---

### Step 1: Define decomposition strategy types

**Project:** `hymenium/`
**Effort:** 2-3 hours
**Depends on:** #118c (Handoff Parser)

Define types in `src/decompose.rs`:

```rust
pub struct DecompositionConfig {
    pub max_effort_per_piece: Duration,    // default: 4 hours
    pub max_steps_per_piece: usize,        // default: 3
    pub respect_dependencies: bool,         // default: true
    pub respect_project_boundaries: bool,   // default: true
}

pub struct DecompositionResult {
    pub original: ParsedHandoff,
    pub pieces: Vec<HandoffPiece>,
    pub dependency_graph: Vec<(usize, usize)>,  // (piece_idx, depends_on_idx)
    pub warnings: Vec<String>,
}

pub struct HandoffPiece {
    pub suggested_slug: String,         // e.g., "otel-foundation-phase1"
    pub title: String,
    pub steps: Vec<ParsedStep>,
    pub estimated_effort: Option<Duration>,
    pub suggested_tier: AgentTier,      // based on effort/complexity
    pub depends_on: Vec<usize>,         // indices into pieces array
}

pub enum AgentTier {
    Haiku,   // <2h effort, straightforward
    Sonnet,  // 2-6h effort, moderate complexity
    Opus,    // >6h effort or requires complex judgment
}
```

#### Verification

```bash
cd hymenium && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Decomposition types defined
- [ ] AgentTier enum with effort-based heuristics
- [ ] DecompositionConfig with sensible defaults
- [ ] Build passes

---

### Step 2: Implement decomposition algorithm

**Project:** `hymenium/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Implement `decompose(handoff: &ParsedHandoff, config: &DecompositionConfig) -> DecompositionResult`:

1. Group steps by project directory (if steps target different repos)
2. Within each group, partition by dependency chains (steps that depend on each other stay together)
3. Within each partition, split at effort boundaries (if cumulative effort exceeds max_effort_per_piece)
4. Generate piece titles from step titles
5. Compute inter-piece dependency graph
6. Assign agent tier based on estimated effort

If the handoff has no effort estimates, fall back to step count (max_steps_per_piece).

#### Verification

```bash
cd hymenium && cargo test decompose 2>&1 | tail -10
```

**Checklist:**
- [ ] Groups by project directory
- [ ] Respects step dependencies (dependent steps stay together)
- [ ] Splits at effort boundaries
- [ ] Falls back to step count when no effort estimates
- [ ] Generates dependency graph between pieces
- [ ] Tests pass

---

### Step 3: Generate child handoff markdown

**Project:** `hymenium/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Add a `render_piece(piece: &HandoffPiece, parent: &ParsedHandoff) -> String` function that generates a valid handoff markdown document for each piece, following the WORK-ITEM-TEMPLATE format:

1. Title derived from parent + piece focus
2. Metadata block with owning repo, write scope from parent
3. Problem section referencing the parent handoff
4. Steps copied from the piece
5. Completion protocol
6. Context linking back to parent

#### Verification

```bash
cd hymenium && cargo test decompose 2>&1 | tail -10
```

**Checklist:**
- [ ] Generated markdown follows WORK-ITEM-TEMPLATE format
- [ ] Metadata block included
- [ ] Steps preserved with verification blocks
- [ ] Context links to parent handoff
- [ ] Tests pass

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step has verification output pasted
2. `cargo test` passes in `hymenium/`
3. All checklist items checked

## Context

Part of hymenium chain (#118d). Depends on #118c (handoff parser). Addresses the recurring problem of large handoffs that stall smaller agents. The decomposer takes parsed handoff input and produces smaller focused pieces that can be dispatched independently.
