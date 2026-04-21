# Stipe Provider MCP Plugin Doctor Expansion

## Problem

The audit set repeatedly points at the same operator gap: the ecosystem has useful provider, MCP, plugin, and worktree state, but `stipe doctor` does not surface enough of it. Users cannot easily answer basic questions like “which host is active?”, “are MCP servers healthy?”, “is auth stale?”, or “did a packaged skill/plugin install drift from expected state?”.

## What exists (state)

- **`stipe doctor`:** already reports baseline health, drift, and install state at a broad level
- **`stipe ecosystem`:** already owns host setup, registration, and repair semantics
- **`lamella`:** already owns packaged skills, commands, agents, and manifests
- **Examples:** `1code`, `claurst`, `rtk`, `context-keeper`, and `skill-manager` all point to richer doctor and safety surfaces

## What needs doing (intent)

Expand `stipe doctor` so it becomes the operator-facing health surface for:

- provider availability and health
- MCP registration and connection status
- plugin or package inventory visibility
- worktree config discovery
- skill/plugin install drift

Keep the boundary hard:

- `stipe` reports, checks, repairs, and mutates host state
- `lamella` remains the source of truth for package metadata

---

### Step 1: Add provider and MCP doctor models

**Project:** `stipe/`
**Effort:** 2-3 hours
**Depends on:** nothing

Extend the doctor model and output shape so it can report:

- configured providers
- provider health or availability
- MCP registration status
- MCP auth freshness where detectable
- per-host summary rather than one global bucket

#### Files to modify

**`stipe/src/commands/doctor/model.rs`** — add richer typed result sections for providers and MCP:

```rust
pub struct ProviderHealth { ... }
pub struct McpHealth { ... }
```

**`stipe/src/commands/doctor.rs`** — include the new sections in doctor output and summaries.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd stipe && cargo build 2>&1 | tail -20
cd stipe && cargo test 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] doctor model includes provider and MCP health sections
- [ ] build passes
- [ ] tests pass

---

### Step 2: Add plugin and worktree doctor checks

**Project:** `stipe/`
**Effort:** 2-3 hours
**Depends on:** Step 1

Add checks for:

- discovered plugin or package inventory from host-visible state
- worktree config discovery
- installed-vs-expected skill or plugin drift where package metadata is available

Start with read-only reporting before adding repair.

#### Files to modify

**`stipe/src/commands/doctor/`** — add focused checks for plugin inventory and worktree config discovery.

**`stipe/src/ecosystem/clients/`** — reuse existing client registration and path-discovery logic rather than duplicating host-specific lookup.

#### Verification

```bash
cd stipe && cargo build 2>&1 | tail -20
cd stipe && cargo test 2>&1 | tail -40
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] doctor reports plugin or package inventory
- [ ] doctor reports discovered worktree config state
- [ ] install drift is visible when metadata is available
- [ ] build and tests pass

---

### Step 3: Add safe install/update scaffolding for skill and plugin packages

**Project:** `stipe/`
**Effort:** 3-4 hours
**Depends on:** Step 2

Introduce the first safe mutation layer for packaged installs:

- backup before mutation
- rollback target
- audit log
- minimal install or update entrypoint for packaged skill or plugin state

Do not move packaging or validation into `stipe`.

#### Files to modify

**`stipe/src/commands/`** — add a focused install or repair entrypoint for packaged assets.

**`stipe/src/ecosystem/`** — keep host mutation logic here.

#### Verification

```bash
cd stipe && cargo build 2>&1 | tail -20
cd stipe && cargo test 2>&1 | tail -40
bash .handoffs/archive/stipe/verify-provider-mcp-plugin-doctor-expansion.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] packaged install/update path has backup and rollback hooks
- [ ] host mutation remains in Stipe
- [ ] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/stipe/verify-provider-mcp-plugin-doctor-expansion.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/stipe/verify-provider-mcp-plugin-doctor-expansion.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/1code/ecosystem-borrow-audit.md`
- `.audit/external/audits/context-keeper/ecosystem-borrow-audit.md`
- `.audit/external/audits/claurst/ecosystem-borrow-audit.md`
- `.audit/external/audits/skill-manager/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
