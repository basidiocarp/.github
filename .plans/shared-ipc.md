# Plan: Shared IPC — Common Types and Discovery for Ecosystem Tools

## Context

Mycelium, Hyphae, and Rhizome are independent Rust repositories under the `basidiocarp` org. Each independently implements: tool availability detection (`which` + `OnceLock` cache), JSON-RPC message formatting, error handling for subprocess failures, and common data types (project context, tool status). A shared crate eliminates this duplication and ensures all tools speak the same protocol.

## Design Decision: Crate Delivery

Since the projects are separate repos (not a monorepo), the shared crate must be consumed as either:

**Option A**: Git dependency
```toml
basidiocarp-ipc = { git = "https://github.com/basidiocarp/basidiocarp-ipc", tag = "v0.1.0" }
```
- Pro: No registry setup, version pinning via tags
- Con: Slower builds (git fetch), no semver resolution across transitive deps

**Option B**: crates.io publication
```toml
basidiocarp-ipc = "0.1"
```
- Pro: Standard Rust ecosystem, fast builds, proper semver
- Con: Public crate for a niche ecosystem

**Decision**: Start with **Option A** (git dependency with tag pinning). Move to crates.io if/when the ecosystem has external users. The crate lives in its own repo: `basidiocarp/basidiocarp-ipc`.

## Repository

`basidiocarp/basidiocarp-ipc` — new repo under the org.

```
basidiocarp-ipc/
├── Cargo.toml
└── src/
    ├── lib.rs
    ├── discovery.rs    # Find sibling tools in PATH
    ├── jsonrpc.rs      # JSON-RPC 2.0 client/server primitives
    ├── types.rs        # Shared ecosystem types
    └── subprocess.rs   # Spawn + communicate with sibling tools
```

## Tasks

### Phase 1 — Core crate (sequential)

#### Task 1: Create repo and crate with discovery and types

**Repo**: `basidiocarp/basidiocarp-ipc` (new)
**Files**: `Cargo.toml`, `src/lib.rs`, `src/discovery.rs`, `src/types.rs`

**Accept criteria**:
- [ ] New GitHub repo: `basidiocarp/basidiocarp-ipc`
- [ ] `Tool` enum: `Mycelium`, `Hyphae`, `Rhizome`
- [ ] `ToolInfo` struct: `tool: Tool`, `binary_path: PathBuf`, `version: String`
- [ ] `pub fn discover(tool: Tool) -> Option<ToolInfo>` — finds binary in PATH, runs `--version`, caches in `OnceLock`
- [ ] `pub fn discover_all() -> Vec<ToolInfo>` — discovers all three tools
- [ ] `EcosystemStatus` struct: `tools: Vec<ToolInfo>`, `timestamp: DateTime<Utc>`
- [ ] `ProjectContext` struct: `name: String`, `root: PathBuf`, `detected_languages: Vec<String>`
- [ ] `pub fn detect_project(path: &Path) -> ProjectContext` — finds `.git` root, detects languages from file extensions
- [ ] Unit tests for discovery (mock binary with `--version` flag)
- [ ] `cargo test` passes, `cargo clippy` passes
- [ ] Tagged `v0.1.0` on first release

**Implementation notes**:
- Use `which` crate for cross-platform binary lookup
- Version parsing: run `{binary} --version`, parse first line. Format: `tool_name X.Y.Z`
- Cache per-process in `static CACHE: OnceLock<HashMap<Tool, Option<ToolInfo>>>`
- Minimal dependencies: `serde`, `serde_json`, `anyhow`, `chrono`, `which`

---

#### Task 2: Add JSON-RPC primitives

**Repo**: `basidiocarp/basidiocarp-ipc`
**Files**: `src/jsonrpc.rs`

**Accept criteria**:
- [ ] `Request` struct: `jsonrpc: "2.0"`, `id: i64`, `method: String`, `params: Value`
- [ ] `Response` struct: `jsonrpc: "2.0"`, `id: i64`, `result: Option<Value>`, `error: Option<RpcError>`
- [ ] `RpcError` struct: `code: i64`, `message: String`, `data: Option<Value>`
- [ ] `pub fn encode(request: &Request) -> String` — JSON with Content-Length header
- [ ] `pub fn decode(input: &str) -> Result<Response>` — parse Content-Length + JSON
- [ ] `AtomicI64` based ID generator for request correlation
- [ ] Serde derives on all types
- [ ] Unit tests: encode/decode round-trip

---

#### Task 3: Add subprocess communication

**Repo**: `basidiocarp/basidiocarp-ipc`
**Files**: `src/subprocess.rs`

**Accept criteria**:
- [ ] `McpClient` struct: manages a subprocess MCP server
- [ ] `pub fn spawn(tool: Tool, args: &[&str]) -> Result<McpClient>` — starts subprocess with piped stdio
- [ ] `pub fn call_tool(&mut self, name: &str, args: Value) -> Result<Value>` — sends JSON-RPC `tools/call`, reads response
- [ ] Timeout: configurable, default 10 seconds
- [ ] Auto-restart: if process exits, next call re-spawns
- [ ] `pub fn is_alive(&self) -> bool`
- [ ] `impl Drop` — kills subprocess on drop
- [ ] Thread-safe: `Arc<Mutex<...>>` for internal state
- [ ] Unit test: spawn a mock echo server, send request, verify response

**Implementation notes**:
- Use `std::process::Command` with piped stdin/stdout
- Reader thread: continuously read stdout, parse JSON-RPC responses, dispatch to pending `oneshot` channels
- Pending requests: `HashMap<i64, oneshot::Sender<Result<Value>>>`
- Timeout: `recv_timeout` on the oneshot receiver

---

### Phase 2 — Adopt in each repo (parallel)

#### Task 4: Adopt in Mycelium

**Repo**: `basidiocarp/mycelium`
**Files**: `Cargo.toml`, `src/hyphae.rs`, `src/rhizome.rs`

**Blocked by**: Tasks 1-3, `basidiocarp-ipc` tagged `v0.1.0`

**Accept criteria**:
- [ ] Add to `Cargo.toml`: `basidiocarp-ipc = { git = "https://github.com/basidiocarp/basidiocarp-ipc", tag = "v0.1.0" }`
- [ ] Replace `src/hyphae.rs` `is_available()` + `OnceLock` with `basidiocarp_ipc::discover(Tool::Hyphae)`
- [ ] Replace `src/rhizome.rs` `is_available()` + `OnceLock` with `basidiocarp_ipc::discover(Tool::Rhizome)`
- [ ] Replace manual JSON-RPC formatting with `basidiocarp_ipc::McpClient`
- [ ] All existing tests pass
- [ ] `cargo clippy` passes

---

#### Task 5: Adopt in Hyphae

**Repo**: `basidiocarp/hyphae`
**Files**: `Cargo.toml` (workspace root), relevant crate `Cargo.toml` files

**Blocked by**: Tasks 1-3

**Accept criteria**:
- [ ] Add `basidiocarp-ipc` as git dependency
- [ ] Use `ProjectContext` for project detection in MCP tools
- [ ] Use `EcosystemStatus` for status reporting
- [ ] All existing tests pass

---

#### Task 6: Adopt in Rhizome

**Repo**: `basidiocarp/rhizome`
**Files**: `Cargo.toml` (workspace root), `crates/rhizome-core/Cargo.toml`

**Blocked by**: Tasks 1-3

**Accept criteria**:
- [ ] Add `basidiocarp-ipc` as git dependency
- [ ] Replace Hyphae detection with `basidiocarp_ipc::discover(Tool::Hyphae)`
- [ ] Use `McpClient` for Hyphae export communication
- [ ] All existing tests pass

---

### Phase 3 (verification)

#### Task 7: Integration testing

**Blocked by**: Tasks 4-6

**Accept criteria**:
- [ ] All three repos build with shared crate dependency
- [ ] `basidiocarp-ipc` has comprehensive test coverage on public API
- [ ] Cross-project: Mycelium discovers Hyphae and Rhizome via shared crate
- [ ] No duplicate discovery/IPC code remains in individual repos
- [ ] CI workflows pass in all repos

## Verification

```bash
# Build and test shared crate
git clone https://github.com/basidiocarp/basidiocarp-ipc
cd basidiocarp-ipc && cargo test && cargo clippy

# Verify each consumer builds
cd ../mycelium && cargo test
cd ../hyphae && cargo test --workspace
cd ../rhizome && cargo test --workspace
```