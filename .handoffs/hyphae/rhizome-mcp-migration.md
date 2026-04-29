# Hyphae: Rhizome CLI → MCP Migration

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/crates/hyphae-ingest/src/rhizome.rs`, `hyphae/crates/hyphae-ingest/Cargo.toml`, and test fixtures in that crate
- **Cross-repo edits:** none
- **Non-goals:** no changes to rhizome itself, no changes to hyphae-mcp or hyphae-cli layers
- **Verification contract:** `cd hyphae && cargo test -p hyphae-ingest && cargo clippy`
- **Completion update:** update `.handoffs/HANDOFFS.md` when done

## Problem

`hyphae/crates/hyphae-ingest/src/rhizome.rs` calls `rhizome symbols <file>` by spawning a subprocess and parsing its flat text output into `Vec<SymbolBoundary>`. This is a system-to-system CLI call: hyphae is calling rhizome as a programmatic dependency, not as a human-facing operator surface.

This approach is fragile:
- Text format of `rhizome symbols` can change without breaking compilation
- Timeout is manual (poll loop with 100 ms sleeps)
- No structured error propagation — a non-zero exit becomes a generic string error
- Violates the C8 rule: system-to-system calls must use library APIs, local service endpoints, or MCP — not CLI

## Current State

**File:** `hyphae/crates/hyphae-ingest/src/rhizome.rs`

- `get_symbol_boundaries(file: &Path) -> Result<Vec<SymbolBoundary>, RhizomeError>`
  - Calls `spore::discover(Tool::Rhizome)` to find the binary
  - Spawns `Command::new(&info.binary_path).arg("symbols").arg(file)`
  - Manually polls `child.try_wait()` with 100 ms sleeps up to a 10 s timeout
  - Reads stdout and calls `parse_symbols_output(&stdout)` to produce `Vec<SymbolBoundary>`

- `SymbolBoundary` struct: `{ name: String, kind: String, line_start: u32, line_end: u32 }`

- `RhizomeError`: `NotAvailable`, `CommandFailed(String)`

## Migration Plan

Replace the CLI subprocess approach with `spore::subprocess::McpClient`, which spawns rhizome as an MCP server process and calls its `get_symbols` tool via JSON-RPC 2.0.

### 1. Update `hyphae-ingest/Cargo.toml`

Verify `spore` is already a dependency. If `McpClient` is not re-exported by spore's default feature set, check `spore/src/subprocess.rs` for the import path (`spore::subprocess::McpClient` or re-exported at the crate root).

### 2. Rewrite `get_symbol_boundaries`

```rust
pub fn get_symbol_boundaries(file: &Path) -> Result<Vec<SymbolBoundary>, RhizomeError> {
    let mut client = spore::subprocess::McpClient::spawn(Tool::Rhizome, &[])
        .map_err(|e| RhizomeError::CommandFailed(format!("failed to start rhizome MCP: {e}")))?;

    let file_str = file.to_str().ok_or_else(|| RhizomeError::CommandFailed(
        "invalid file path encoding".into()
    ))?;

    let result = client
        .call_tool("get_symbols", serde_json::json!({ "path": file_str }))
        .map_err(|e| RhizomeError::CommandFailed(format!("get_symbols failed: {e}")))?;

    parse_mcp_symbols(result)
}
```

### 3. Add `parse_mcp_symbols`

The MCP response from `get_symbols` is a JSON array of rhizome `Symbol` objects. Each `Symbol` has:
- `name: String`
- `kind: SymbolKind` (serde: `"Function"`, `"Struct"`, `"Enum"`, etc.)
- `location: { file_path, line_start, line_end, column_start, column_end }`
- `children: Vec<Symbol>` (nested; flatten as needed)

```rust
fn parse_mcp_symbols(value: serde_json::Value) -> Result<Vec<SymbolBoundary>, RhizomeError> {
    // MCP tool_response wraps content as: [{"type":"text","text":"<json>"}]
    // Extract the text field and parse it as the symbol array.
    let text = value
        .get(0)
        .and_then(|v| v.get("text"))
        .and_then(|v| v.as_str())
        .ok_or_else(|| RhizomeError::CommandFailed("unexpected get_symbols response shape".into()))?;

    let symbols: Vec<serde_json::Value> = serde_json::from_str(text)
        .map_err(|e| RhizomeError::CommandFailed(format!("failed to parse symbols JSON: {e}")))?;

    let mut result = Vec::new();
    collect_symbol_boundaries(&symbols, &mut result);
    Ok(result)
}

fn collect_symbol_boundaries(symbols: &[serde_json::Value], out: &mut Vec<SymbolBoundary>) {
    for sym in symbols {
        let name = sym.get("name").and_then(|v| v.as_str()).unwrap_or_default();
        let kind = sym.get("kind").and_then(|v| v.as_str()).unwrap_or("unknown");
        let loc = sym.get("location");
        let line_start = loc.and_then(|l| l.get("line_start")).and_then(|v| v.as_u64()).unwrap_or(0) as u32;
        let line_end = loc.and_then(|l| l.get("line_end")).and_then(|v| v.as_u64()).unwrap_or(0) as u32;

        if !name.is_empty() {
            out.push(SymbolBoundary {
                name: name.to_string(),
                kind: kind.to_string(),
                line_start,
                line_end,
            });
        }

        // Recurse into children to preserve flat boundary list
        if let Some(children) = sym.get("children").and_then(|v| v.as_array()) {
            collect_symbol_boundaries(children, out);
        }
    }
}
```

### 4. Update `RhizomeError`

The `NotAvailable` variant is no longer needed (McpClient::spawn returns an error if rhizome is not found). Keep the variant for backward compatibility with existing match sites but it will only be constructed if explicitly needed. Alternatively, deprecate it and let `CommandFailed` cover spawn failures.

### 5. Update `is_available`

Keep `is_available()` as-is — it uses `spore::discover(Tool::Rhizome)` which is correct for availability checks. `McpClient::spawn` uses the same discovery path internally.

### 6. Update tests

The existing unit tests (`parse_single_function`, `parse_multiple_symbols`, etc.) test `parse_symbols_output` which parses the old text format. They remain valid as regression tests for the parser. Add a new test:

```rust
#[test]
fn parse_mcp_symbols_from_json() {
    let response = serde_json::json!([{
        "type": "text",
        "text": serde_json::json!([{
            "name": "main",
            "kind": "Function",
            "location": {"file_path": "src/main.rs", "line_start": 1, "line_end": 10, "column_start": 0, "column_end": 1},
            "children": []
        }]).to_string()
    }]);
    let symbols = parse_mcp_symbols(response).unwrap();
    assert_eq!(symbols.len(), 1);
    assert_eq!(symbols[0].name, "main");
    assert_eq!(symbols[0].kind, "Function");
    assert_eq!(symbols[0].line_start, 1);
    assert_eq!(symbols[0].line_end, 10);
}
```

## Verification

```bash
cd hyphae && cargo test -p hyphae-ingest
cd hyphae && cargo clippy
```

All existing tests must pass. The new `parse_mcp_symbols_from_json` test must pass.

## Context

- C7: `hyphae → rhizome` classified as "system-to-system compatibility" in `septa/integration-patterns.md`
- C8: `docs/foundations/inter-app-communication.md` — preferred integration tier for cross-binary calls is local service endpoint or MCP, not CLI
- `spore::subprocess::McpClient` is the existing mechanism for MCP subprocess calls (used by rhizome consumers already)
- If rhizome later registers a local service endpoint, the migration from McpClient to `spore::LocalServiceClient` will be a contained change inside this one file
