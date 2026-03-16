# Plan: Spore — Shared IPC for Ecosystem Tools

## Context

Mycelium, Hyphae, and Rhizome are independent Rust repositories under the `basidiocarp` org. Each independently implements: tool availability detection (`which` + `OnceLock` cache), JSON-RPC message formatting, error handling for subprocess failures, and common data types (project context, tool status). Spore eliminates this duplication and ensures all tools speak the same protocol.

Named after fungal spores — lightweight carriers of information between separate organisms.

## Status

**Phase 1 complete.** The `basidiocarp/spore` repo exists with initial implementation:
- `Tool` enum, `ToolInfo`, `EcosystemStatus`, `ProjectContext` types
- `discover()` / `discover_all()` with `OnceLock` caching
- JSON-RPC 2.0 `Request`/`Response` with Content-Length framing
- `McpClient` subprocess communication with auto-restart

## Design Decision: Crate Delivery

Since the projects are separate repos (not a monorepo), the shared crate is consumed as a git dependency:

```toml
spore = { git = "https://github.com/basidiocarp/spore", tag = "v0.1.0" }
```

Move to crates.io if/when the ecosystem has external users.

## Repository

`basidiocarp/spore` — https://github.com/basidiocarp/spore

```
spore/
├── Cargo.toml
└── src/
    ├── lib.rs
    ├── discovery.rs    # Find sibling tools in PATH
    ├── jsonrpc.rs      # JSON-RPC 2.0 client/server primitives
    ├── types.rs        # Shared ecosystem types
    └── subprocess.rs   # Spawn + communicate with sibling tools
```

## Remaining Tasks

### Phase 2 — Adopt in each repo (parallel)

#### Task 1: Adopt in Mycelium

**Repo**: `basidiocarp/mycelium`
**Files**: `Cargo.toml`, `src/hyphae.rs`, `src/rhizome.rs`

**Accept criteria**:
- [ ] Add to `Cargo.toml`: `spore = { git = "https://github.com/basidiocarp/spore", tag = "v0.1.0" }`
- [ ] Replace `src/hyphae.rs` `is_available()` + `OnceLock` with `spore::discover(Tool::Hyphae)`
- [ ] Replace `src/rhizome.rs` `is_available()` + `OnceLock` with `spore::discover(Tool::Rhizome)`
- [ ] Replace manual JSON-RPC formatting with `spore::McpClient`
- [ ] All existing tests pass
- [ ] `cargo clippy` passes

---

#### Task 2: Adopt in Hyphae

**Repo**: `basidiocarp/hyphae`
**Files**: `Cargo.toml` (workspace root), relevant crate `Cargo.toml` files

**Accept criteria**:
- [ ] Add `spore` as git dependency
- [ ] Use `ProjectContext` for project detection in MCP tools
- [ ] Use `EcosystemStatus` for status reporting
- [ ] All existing tests pass

---

#### Task 3: Adopt in Rhizome

**Repo**: `basidiocarp/rhizome`
**Files**: `Cargo.toml` (workspace root), `crates/rhizome-core/Cargo.toml`

**Accept criteria**:
- [ ] Add `spore` as git dependency
- [ ] Replace Hyphae detection with `spore::discover(Tool::Hyphae)`
- [ ] Use `McpClient` for Hyphae export communication
- [ ] All existing tests pass

---

### Phase 3 (verification)

#### Task 4: Integration testing

**Blocked by**: Tasks 1-3

**Accept criteria**:
- [ ] All three repos build with spore dependency
- [ ] Spore has comprehensive test coverage on public API
- [ ] Cross-project: Mycelium discovers Hyphae and Rhizome via spore
- [ ] No duplicate discovery/IPC code remains in individual repos
- [ ] CI workflows pass in all repos

## Verification

```bash
# Build and test spore
git clone https://github.com/basidiocarp/spore
cd spore && cargo test && cargo clippy

# Verify each consumer builds
cd ../mycelium && cargo test
cd ../hyphae && cargo test --workspace
cd ../rhizome && cargo test --workspace
```