# Canopy main.rs Split

## Problem

`canopy/src/main.rs` is 1,593 lines — the third largest file in the canopy codebase
after `api.rs` (3,737) and `helpers.rs` (1,769). It embeds multiple subsystems directly:
MCP server setup, tool registration, DB initialization, agent lifecycle, and CLI dispatch
are all in one file. This makes it hard to test subsystems in isolation and is a direct
consequence of the same structural debt that `api-module-split` and `store-trait-decomposition`
address. Found in the 2026-04-04 global audit structural hotspots.

## What exists (state)

- **File:** `canopy/src/main.rs` (1,593 lines)
- **Related:** `canopy/api-module-split.md` — splits api.rs; this handoff is scoped to main.rs
- **Related:** `canopy/store-trait-decomposition.md` — splits helpers.rs
- **Pattern:** same embedded-subsystem debt as api.rs

## What needs doing (intent)

Extract the embedded subsystems from `main.rs` into focused modules. The goal is a
`main.rs` that is ~150 lines: parses CLI args, initializes the runtime, and delegates
to modules.

---

### Step 1: Identify and map embedded subsystems

**Project:** `canopy/`
**Effort:** 30 min

Read `main.rs` and identify the logical subsystems embedded in it:
- MCP server setup and tool registration
- DB initialization and migration
- Agent registration / lifecycle hooks
- CLI subcommand dispatch
- Signal handling / shutdown

Produce a module map: what moves where.

**Checklist:**
- [ ] All embedded subsystems identified with line ranges
- [ ] Target module name proposed for each subsystem
- [ ] Dependencies between subsystems mapped (what must initialize before what)

---

### Step 2: Extract server setup and tool registration

**Project:** `canopy/`
**Effort:** 1-2 hours
**Depends on:** Step 1

Move MCP server setup and tool registration into `canopy/src/server.rs` (or
`canopy/src/mcp/mod.rs`). `main.rs` calls `server::start(config, store)`.

#### Verification

```bash
cd canopy && cargo test 2>&1 | tail -10
```

**Checklist:**
- [ ] Server setup extracted to dedicated module
- [ ] Tool registration extracted (or stays co-located with server setup)
- [ ] `main.rs` no longer contains MCP wiring
- [ ] All existing tests pass

---

### Step 3: Extract DB initialization

**Project:** `canopy/`
**Effort:** 30 min
**Depends on:** Step 2

Move DB initialization and migration logic into `canopy/src/db.rs` or alongside the
store layer. `main.rs` calls `db::open(path)` and receives a store handle.

**Checklist:**
- [ ] DB init extracted to dedicated module
- [ ] Migration logic co-located with DB init
- [ ] `main.rs` reduced to a `db::open()` call
- [ ] All existing tests pass

---

### Step 4: Slim main.rs to ≤200 lines

**Project:** `canopy/`
**Effort:** 30 min
**Depends on:** Steps 2-3

After extractions, `main.rs` should contain only:
- CLI arg parsing
- Config loading
- Module initialization in order
- Shutdown / signal handling

```bash
wc -l canopy/src/main.rs
```

**Checklist:**
- [ ] `main.rs` is ≤200 lines
- [ ] No subsystem logic remains in `main.rs`
- [ ] `cd canopy && cargo test --all` passes

---

## Completion Protocol

1. All step checklists checked
2. `cd canopy && cargo test --all` passes
3. `wc -l canopy/src/main.rs` ≤ 200

## Context

Global audit 2026-04-04, structural hotspots table. Complement to `api-module-split`
(api.rs) and `store-trait-decomposition` (helpers.rs). Together these three handoffs
eliminate all three >1,500-line files in canopy.
