# Volva Execution-Host Session Workspace Contract

## Problem

The newer audit wave repeatedly pointed at the same missing seam: `volva` owns execution-host behavior, but it does not yet have a first-class contract for execution sessions, workspace identity, participant identity, and pause or resume state. That makes it too easy for host state to stay implicit or drift across CLI, runtime, and downstream coordination layers.

## What exists (state)

- **`volva-cli`:** already owns run, chat, backend, and auth entry points
- **`volva-runtime`:** already owns runtime context, hook forwarding, and backend integration
- **`volva-core`:** currently has room for shared contract types but not a clear execution-session model
- **Examples:** `autogen`, `claude-mem`, and `claude-squad` all reinforced the need for explicit runtime identity; `cmux` and `vibe-kanban` added pressure around workspace and handle identity

## What needs doing (intent)

Define `volva` as the execution-host boundary for:

- execution session identity
- workspace or worktree binding
- participant identity
- pause or resume state
- host-context shaping before execution

Do this as typed contract work first, then thread it through runtime and CLI surfaces.

---

### Step 1: Add typed execution-session and workspace identity models

**Project:** `volva/`
**Effort:** 3-4 hours
**Depends on:** nothing

Add shared types for execution-session identity and workspace binding in a crate that both CLI and runtime can use. Keep the shape small and explicit:

- execution session id
- workspace or worktree ref
- backend id
- participant set or primary participant
- state such as active, paused, resumed, finished

#### Files to modify

**`volva/crates/volva-core/src/lib.rs`** — add shared execution-session and workspace identity types.

**`volva/docs/VOLVA-ARCHITECTURE.md`** — document the ownership boundary so the runtime contract is explicit.

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -40
cd volva && cargo test --workspace 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->
    Finished `dev` profile [optimized + debuginfo] target(s) in 1.27s
    Finished `test` profile [optimized + debuginfo] target(s) in 1.61s
test result: ok. 20 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.17s
test result: ok. 24 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.50s

<!-- PASTE END -->

**Checklist:**
- [x] shared execution-session and workspace identity types exist
- [x] the architecture doc names `volva` as the execution-host boundary
- [x] build and tests pass

---

### Step 2: Thread the contract through runtime and CLI entry points

**Project:** `volva/`
**Effort:** 4-5 hours
**Depends on:** Step 1

Use the new types in runtime and CLI flows so execution does not rely on ad hoc strings.

At minimum, wire the contract through:

- run and chat entry points
- runtime context assembly
- backend dispatch
- hook forwarding surfaces where session identity is relevant

#### Files to modify

**`volva/crates/volva-runtime/src/context.rs`** — carry workspace and participant identity in the runtime context.

**`volva/crates/volva-runtime/src/lib.rs`** — thread the contract through runtime entry points.

**`volva/crates/volva-cli/src/run.rs`** — construct or pass execution-session identity.

**`volva/crates/volva-cli/src/chat.rs`** — use the same contract for chat-mode execution.

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -40
cd volva && cargo test --workspace 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->
    Finished `dev` profile [optimized + debuginfo] target(s) in 1.27s
    Finished `test` profile [optimized + debuginfo] target(s) in 1.61s
test result: ok. 20 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.17s
test result: ok. 24 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.50s

<!-- PASTE END -->

**Checklist:**
- [x] runtime context carries typed execution-session identity
- [x] CLI entry points use the shared types instead of ad hoc strings
- [x] build and tests pass

---

### Step 3: Expose a minimal inspectable host-session surface

**Project:** `volva/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Add a minimal status or inspect surface so downstream tools can reason about `volva` execution sessions without scraping logs. This does not need to be a full orchestration API yet; it only needs enough shape for later `canopy` and `cap` integration.

#### Files to modify

**`volva/crates/volva-cli/src/backend.rs`** — add a narrow inspection or status command path if needed.

**`volva/crates/volva-runtime/src/backend/mod.rs`** — expose execution-session state in a stable way.

#### Verification

```bash
cd volva && cargo build --workspace 2>&1 | tail -40
cd volva && cargo test --workspace 2>&1 | tail -60
bash .handoffs/archive/volva/verify-execution-host-session-workspace-contract.sh
```

**Output:**
<!-- PASTE START -->
    Finished `dev` profile [optimized + debuginfo] target(s) in 1.27s
    Finished `test` profile [optimized + debuginfo] target(s) in 1.61s
PASS: Volva core mentions execution session types
PASS: Volva runtime carries session or workspace identity
PASS: Volva CLI run or chat surfaces mention session identity
PASS: Volva architecture doc mentions execution-host session boundary
PASS: Volva runtime persists and loads execution session snapshots
PASS: Volva backend session surface reads persisted execution sessions
PASS: Volva chat path can emit paused or resumed session state
PASS: Handoff step checklists are marked complete
PASS: Handoff includes build and test proof
PASS: Handoff includes verify proof
Results: 10 passed, 0 failed

<!-- PASTE END -->

**Checklist:**
- [x] `volva` exposes an inspectable execution-session surface
- [x] downstream tools can rely on typed ids and state instead of log parsing
- [x] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/volva/verify-execution-host-session-workspace-contract.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/volva/verify-execution-host-session-workspace-contract.sh
```

**Output:**
<!-- PASTE START -->
PASS: Volva core mentions execution session types
PASS: Volva runtime carries session or workspace identity
PASS: Volva CLI run or chat surfaces mention session identity
PASS: Volva architecture doc mentions execution-host session boundary
PASS: Volva runtime persists and loads execution session snapshots
PASS: Volva backend session surface reads persisted execution sessions
PASS: Volva chat path can emit paused or resumed session state
PASS: Handoff step checklists are marked complete
PASS: Handoff includes build and test proof
PASS: Handoff includes verify proof
Results: 10 passed, 0 failed

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/autogen/ecosystem-borrow-audit.md`
- `.audit/external/audits/claude-mem/ecosystem-borrow-audit.md`
- `.audit/external/audits/claude-squad/ecosystem-borrow-audit.md`
- `.audit/external/audits/cmux/ecosystem-borrow-audit.md`
- `.audit/external/audits/vibe-kanban/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/next-session-context-second-wave-handoffs.md`
