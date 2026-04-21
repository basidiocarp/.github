# Hyphae Scoped Memory Identity And Export Contract

## Problem

The newer memory-heavy audits all converged on the same missing layer in `hyphae`: memory and context are getting stronger, but scoped identity and export contracts are still not explicit enough. Without a sharper contract for scopes like agent, app, run, project, or worktree, the system risks inconsistent recall semantics and one-off export shapes.

## What exists (state)

- **`hyphae-store`:** already stores memories, sessions, docs, and code-related context
- **`hyphae-mcp`:** already exposes memory, session, and context tools
- **`hyphae-cli`:** already has backup, context, memory, and session commands
- **No strong scoped identity contract:** scope semantics are present, but not yet shaped as a first-class shared model
- **Examples:** `mem0`, `claude-mem`, `serena`, and `icm` all reinforced the need for this layer

## What needs doing (intent)

Define a sharper `hyphae` contract for:

- memory scope identity
- recall envelope identity
- archive and export shape
- consistent use of scope across store, MCP, and CLI surfaces

Do this before building more downstream UI or contract work on top of the current memory model.

---

### Step 1: Add explicit scoped-identity types to the store layer

**Project:** `hyphae/`
**Effort:** 3-4 hours
**Depends on:** nothing

Introduce explicit types or schema conventions for the scopes `hyphae` actually wants to support. Start small and prefer compile-time clarity over a large generic taxonomy.

#### Files to modify

**`hyphae/crates/hyphae-store/src/schema.rs`** — add or clarify scope-bearing fields and constraints.

**`hyphae/crates/hyphae-store/src/store/memory_store.rs`** — thread explicit scope identity through memory storage and lookup.

**`hyphae/crates/hyphae-store/src/store/context.rs`** — make context assembly aware of the same scope semantics.

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -40
cd hyphae && cargo test --workspace 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->
$ cd hyphae && cargo build --workspace
Finished `dev` profile [optimized + debuginfo] target(s) in 5.68s

$ cd hyphae && cargo test --workspace
test result: ok. 151 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
test result: ok. 161 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
test result: ok. 243 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
<!-- PASTE END -->

**Checklist:**
- [x] store schema names supported scope identities explicitly
- [x] memory and context store code use the same scope model
- [x] build and tests pass

---

### Step 2: Use the same scope model in MCP and CLI recall surfaces

**Project:** `hyphae/`
**Effort:** 3-4 hours
**Depends on:** Step 1

Make the scope model visible at the retrieval boundary so callers do not have to infer it from implementation details.

#### Files to modify

**`hyphae/crates/hyphae-mcp/src/tools/context.rs`** — expose scoped identity consistently in context assembly.

**`hyphae/crates/hyphae-mcp/src/tools/memory/recall.rs`** — align recall semantics with the shared scope model.

**`hyphae/crates/hyphae-cli/src/commands/context.rs`** — align CLI context handling with the same scope semantics.

**`hyphae/crates/hyphae-cli/src/commands/memory.rs`** — keep CLI memory behavior consistent with the store and MCP layers.

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -40
cd hyphae && cargo test --workspace 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->
$ cd hyphae && cargo build --workspace
Finished `dev` profile [optimized + debuginfo] target(s) in 5.68s

$ cd hyphae && cargo test --workspace
test result: ok. 151 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
test result: ok. 161 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
test result: ok. 243 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
<!-- PASTE END -->

**Checklist:**
- [x] MCP and CLI surfaces use the same scoped-identity model
- [x] recall and context envelopes make scope visible and stable
- [x] build and tests pass

---

### Step 3: Add a stable export and backup contract

**Project:** `hyphae/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Make archive and export output stable enough that downstream tooling can rely on it. Keep the first version narrow and explicit rather than trying to export every internal detail.

#### Files to modify

**`hyphae/crates/hyphae-cli/src/commands/backup.rs`** — align backup output to the new scope-aware contract.

**`hyphae/crates/hyphae-mcp/src/tools/schema.rs`** — document or expose the stable export shape where appropriate.

#### Verification

```bash
cd hyphae && cargo build --workspace 2>&1 | tail -40
cd hyphae && cargo test --workspace 2>&1 | tail -60
bash .handoffs/archive/hyphae/verify-scoped-memory-identity-and-export-contract.sh
```

**Output:**
<!-- PASTE START -->
$ cd hyphae && cargo build --workspace
Finished `dev` profile [optimized + debuginfo] target(s) in 5.68s

$ cd hyphae && cargo test --workspace
test result: ok. 151 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
test result: ok. 161 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
test result: ok. 243 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out

$ bash .handoffs/archive/hyphae/verify-scoped-memory-identity-and-export-contract.sh
PASS: Hyphae core defines a shared scoped identity contract
PASS: Hyphae store layer exposes scoped identity from structured sessions
PASS: Hyphae passive export bundles carry a scoped identity envelope
PASS: Hyphae gather-context surfaces emit scoped identity in CLI and MCP
PASS: Hyphae session surfaces emit scoped identity envelopes
PASS: Hyphae memory JSON payloads carry scoped identity
PASS: Hyphae backup command writes a stable export manifest
PASS: Hyphae MCP tool descriptions mention scoped identity envelopes
PASS: Handoff checklist is marked complete
Results: 9 passed, 0 failed
<!-- PASTE END -->

**Checklist:**
- [x] backup or export output reflects the scope-aware contract
- [x] scope semantics are stable across store, MCP, CLI, and export
- [x] verify script passes

---

## Completion Protocol

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/hyphae/verify-scoped-memory-identity-and-export-contract.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/hyphae/verify-scoped-memory-identity-and-export-contract.sh
```

**Output:**
<!-- PASTE START -->
PASS: Hyphae core defines a shared scoped identity contract
PASS: Hyphae store layer exposes scoped identity from structured sessions
PASS: Hyphae passive export bundles carry a scoped identity envelope
PASS: Hyphae gather-context surfaces emit scoped identity in CLI and MCP
PASS: Hyphae session surfaces emit scoped identity envelopes
PASS: Hyphae memory JSON payloads carry scoped identity
PASS: Hyphae backup command writes a stable export manifest
PASS: Hyphae MCP tool descriptions mention scoped identity envelopes
PASS: Handoff checklist is marked complete
Results: 9 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

## Context

Derived from:

- `.audit/external/audits/mem0/ecosystem-borrow-audit.md`
- `.audit/external/audits/claude-mem/ecosystem-borrow-audit.md`
- `.audit/external/audits/serena/ecosystem-borrow-audit.md`
- `.audit/external/audits/icm/ecosystem-borrow-audit.md`
- `.audit/external/synthesis/project-examples-ecosystem-synthesis.md`
- `.audit/external/synthesis/next-session-context-second-wave-handoffs.md`
