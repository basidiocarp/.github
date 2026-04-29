# Mycelium: Rhizome CLI → MCP Migration

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/src/rhizome_client.rs` and related test fixtures
- **Cross-repo edits:** none
- **Non-goals:** no changes to rhizome itself; no changes to mycelium's filtering logic that consumes the structure output
- **Verification contract:** `cd mycelium && cargo test && cargo clippy`
- **Completion update:** update `.handoffs/HANDOFFS.md` when done

## Problem

`mycelium/src/rhizome_client.rs` calls `rhizome structure <file>` by spawning a thread with a subprocess and using `mpsc` + `recv_timeout` for the 3 s deadline. The result is returned as raw text that mycelium uses as a code outline for filtering context.

This is a system-to-system CLI call: mycelium is using rhizome as a programmatic dependency, not as a human-facing operator surface. It violates the C8 boundary rule and creates the same fragility as the hyphae→rhizome path: text-format changes in rhizome's structure output can silently break mycelium filtering without a compile-time signal.

## Current State

**File:** `mycelium/src/rhizome_client.rs`

- `pub fn get_structure(file: &Path) -> Result<String>`
  - Calls `spore::discover(Tool::Rhizome)` via `run_rhizome_command("structure", file)`
  - Spawns a thread that runs `Command::new(&bin).arg("structure").arg(file_str)`
  - Uses `rx.recv_timeout(Duration::from_secs(3))` for the timeout
  - Returns the raw stdout string to callers

- `run_rhizome_command(subcommand: &str, file: &Path) -> Result<String>`
  - Generic helper; currently only used by `get_structure`

- Callers in mycelium use the returned string as freeform context (code outline text inserted into filter output or summaries). The text format is passed through without structured parsing.

## Migration Plan

Replace the CLI approach with `spore::subprocess::McpClient`. Rhizome's MCP server exposes `get_structure` as a tool that returns the same hierarchical outline.

### 1. Rewrite `get_structure`

```rust
pub fn get_structure(file: &Path) -> Result<String> {
    use spore::subprocess::McpClient;
    use spore::Tool;

    let file_str = file.to_str().context("Invalid file path encoding")?;

    let mut client = McpClient::spawn(Tool::Rhizome, &[])
        .context("Rhizome binary not found")?;

    // Apply the same 3 s deadline via the McpClient timeout API
    client = client.with_timeout(std::time::Duration::from_secs(3));

    let result = client
        .call_tool("get_structure", serde_json::json!({ "path": file_str }))
        .context("Rhizome get_structure failed")?;

    // Extract text content from MCP tool_response envelope:
    // [{"type": "text", "text": "<outline text>"}]
    let text = result
        .get(0)
        .and_then(|v| v.get("text"))
        .and_then(|v| v.as_str())
        .ok_or_else(|| anyhow::anyhow!("Unexpected get_structure response shape"))?;

    if text.is_empty() {
        anyhow::bail!(
            "rhizome get_structure returned empty output for {}",
            file_str
        );
    }

    Ok(text.to_string())
}
```

### 2. Remove `run_rhizome_command`

After migrating `get_structure`, `run_rhizome_command` becomes dead code. Remove it.

### 3. Remove thread + mpsc boilerplate

The thread spawn and mpsc channel are no longer needed. The McpClient handles timeout internally via `with_timeout`. Remove the `use std::sync::mpsc;` and `use std::thread` imports.

### 4. Preserve the span context

The current implementation uses `spore::logging::{SpanContext, subprocess_span, tool_span}`. Keep these instrumentation spans around the McpClient call so tracing context is preserved:

```rust
let context = span_context("structure", file);
let _tool_span = tool_span("rhizome_structure", &context).entered();
// ... spawn McpClient ...
let _subprocess_span = subprocess_span("rhizome get_structure", &context).entered();
let result = client.call_tool(...);
```

### 5. Update tests

The existing tests check graceful failure when rhizome is absent:
- `test_get_structure_without_rhizome` — should still pass: McpClient::spawn returns Err when rhizome is not discovered
- `test_nonexistent_file` — should still pass: McpClient will call rhizome which will error on the missing file

Add a test documenting the expected output shape when rhizome is present (or mark as `#[ignore]` for environments with rhizome installed):

```rust
#[test]
#[ignore]
fn test_get_structure_returns_text() {
    let path = std::path::PathBuf::from("src/rhizome_client.rs");
    let result = get_structure(&path);
    assert!(result.is_ok(), "get_structure should succeed with rhizome installed");
    let text = result.unwrap();
    assert!(!text.is_empty(), "structure output should not be empty");
}
```

## Verification

```bash
cd mycelium && cargo test
cd mycelium && cargo clippy
```

Existing non-ignored tests must pass. The `test_get_structure_without_rhizome` test must continue to pass (it validates the graceful-failure path).

## Context

- C7: `mycelium → rhizome` classified as "system-to-system compatibility" in `septa/integration-patterns.md`
- C8: `docs/foundations/inter-app-communication.md` — preferred integration tier is MCP or local service endpoint, not CLI
- Companion handoff: `hyphae/rhizome-mcp-migration.md` — the same pattern applied to hyphae-ingest; do both together or in sequence to share the review cycle
- If rhizome later registers a local service endpoint, migrating from `McpClient` to `spore::LocalServiceClient` will be a contained change inside `rhizome_client.rs`
