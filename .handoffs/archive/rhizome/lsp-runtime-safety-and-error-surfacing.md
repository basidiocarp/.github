# Rhizome LSP Runtime Safety And Error Surfacing

## Problem

`rhizome serve --expanded` currently crashes on LSP-backed MCP calls such as
`get_diagnostics` and `find_references`. The direct failure is a Tokio runtime
nesting panic inside `rhizome-lsp`, but callers only see `Transport closed`
after the MCP process dies. That makes the current failure both user-facing and
hard to debug.

## What exists (state)

- **`rhizome-cli`:** runs the MCP server under `#[tokio::main]`.
- **`rhizome-mcp`:** creates `LspBackend` from the current Tokio handle in the
  MCP dispatch path.
- **`rhizome-lsp`:** wraps async LSP operations behind sync trait methods using
  `Handle::block_on`.
- **Current repro:** direct `get_diagnostics` and `find_references` requests to
  `rhizome serve --expanded` panic with `Cannot start a runtime from within a runtime`.
- **Current observability:** the LSP child process drops stderr, the reader loop
  exits quietly on EOF, and the upstream caller loses the actual reason.

## What needs doing (intent)

Make Rhizome's LSP-backed MCP path runtime-safe under the real `serve` entry
point, then improve local error surfacing so future LSP failures return useful
tool errors instead of killing the transport.

---

### Step 1: Add Serve-Path Reproduction Coverage

**Project:** `rhizome/`
**Effort:** 2-3 hours
**Depends on:** nothing

Add an end-to-end regression path that exercises the real `rhizome serve`
runtime rather than only calling `ToolDispatcher` directly. The minimum bar is a
repro for `get_diagnostics`, plus one more LSP-preferred call such as
`find_references`, so the runtime-nesting failure can never slip through again.

#### Files to modify

**`rhizome/crates/rhizome-mcp/tests/`** or **`rhizome/crates/rhizome-cli/tests/`** —
add serve-path regression coverage:

```text
- initialize MCP server
- send tools/call for get_diagnostics on a real Rust source file
- send tools/call for find_references on a real Rust source file
- assert: no panic, no transport death, JSON-RPC response returned
```

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd rhizome && cargo test -p rhizome-cli --test serve_lsp_runtime --quiet
```

**Output:**
<!-- PASTE START -->
running 1 test
.
test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 1.22s
<!-- PASTE END -->

**Checklist:**
- [x] there is a serve-path regression test for `get_diagnostics`
- [x] there is a serve-path regression test for `find_references` or equivalent LSP-preferred path
- [x] the repro would have failed before the runtime fix

---

### Step 2: Remove Runtime Nesting From LSP-Backed MCP Calls

**Project:** `rhizome/`
**Effort:** 3-5 hours
**Depends on:** Step 1

Fix the actual runtime bug. The implementation choice can vary, but the result
must be that an LSP-backed MCP request can run safely from `rhizome serve`
without calling `Handle::block_on` from inside the active runtime thread.

Keep the fix coherent with Rhizome's current layering:

- do not push ad hoc LSP policy into random tool handlers
- do not reintroduce a second transport path outside the shared dispatcher
- keep the MCP serve path and any direct CLI/LSP path behavior aligned

#### Files to modify

**`rhizome/crates/rhizome-lsp/src/lib.rs`** — remove the unsafe runtime nesting
behavior from sync wrappers.

**`rhizome/crates/rhizome-mcp/src/tools/mod.rs`** — adjust dispatch or backend
initialization if needed to use the safe path.

**`rhizome/crates/rhizome-lsp/src/manager.rs`** and related files — only if
needed to preserve client lifecycle correctness after the runtime fix.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd rhizome && printf '%s\n%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_diagnostics","arguments":{"file":"'"$PWD"'/crates/rhizome-treesitter/src/parser.rs"}}}' \
  | cargo run -q -p rhizome-cli -- serve --expanded
```

**Output:**
<!-- PASTE START -->
{"id":1,"jsonrpc":"2.0","result":{"capabilities":{"tools":{}},"protocolVersion":"2024-11-05","serverInfo":{"instructions":"Rhizome provides code intelligence — symbol extraction, definitions, references, diagnostics, and impact analysis. Top tools: get_symbols (file overview), get_definition (symbol source), find_references (cross-file), analyze_impact (change blast radius), search_symbols (global search), get_diagnostics (errors/warnings), and get_region (expand one structural region). Most tools require an absolute file path. Use get_structure for project overview. Use export_to_hyphae to push code graphs to Hyphae for persistent knowledge.","name":"rhizome","version":"0.7.7"}}}
{"id":2,"jsonrpc":"2.0","result":{"content":[{"text":"[]","type":"text"}]}}
<!-- PASTE END -->

```bash
cd rhizome && printf '%s\n%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"find_references","arguments":{"file":"'"$PWD"'/crates/rhizome-treesitter/src/parser.rs","line":29,"column":11}}}' \
  | cargo run -q -p rhizome-cli -- serve --expanded
```

**Output:**
<!-- PASTE START -->
{"id":1,"jsonrpc":"2.0","result":{"capabilities":{"tools":{}},"protocolVersion":"2024-11-05","serverInfo":{"instructions":"Rhizome provides code intelligence — symbol extraction, definitions, references, diagnostics, and impact analysis. Top tools: get_symbols (file overview), get_definition (symbol source), find_references (cross-file), analyze_impact (change blast radius), search_symbols (global search), get_diagnostics (errors/warnings), and get_region (expand one structural region). Most tools require an absolute file path. Use get_structure for project overview. Use export_to_hyphae to push code graphs to Hyphae for persistent knowledge.","name":"rhizome","version":"0.7.7"}}}
{"id":2,"jsonrpc":"2.0","result":{"content":[{"text":"Error: LSP error: LSP error for 'textDocument/references': file not found: /Users/williamnewton/projects/basidiocarp/rhizome/crates/rhizome-treesitter/src/parser.rs","type":"text"}],"isError":true}}
<!-- PASTE END -->

**Checklist:**
- [x] `get_diagnostics` returns a JSON-RPC response instead of panicking
- [x] `find_references` returns a JSON-RPC response instead of panicking
- [x] the output does not contain `Cannot start a runtime from within a runtime`

---

### Step 3: Improve LSP Failure Surfacing

**Project:** `rhizome/`
**Effort:** 2-3 hours
**Depends on:** Step 2

Make future LSP failures diagnosable without breaking MCP stdio framing.

Minimum expectations:

- LSP child stderr is no longer discarded blindly
- reader EOF or child exit produces an actionable Rhizome error path
- tool callers get an MCP error response or `isError` payload, not a silent
  transport drop
- docs mention how to turn on debug logs for this path

#### Files to modify

**`rhizome/crates/rhizome-lsp/src/client.rs`** — capture and surface LSP child
stderr and reader/process death meaningfully.

**`rhizome/crates/rhizome-mcp/src/server.rs`** and related files — preserve MCP
transport correctness while surfacing the underlying error.

**`rhizome/docs/TROUBLESHOOTING.md`** or related docs — document how to inspect
the LSP-backed serve path when it fails.

#### Verification

Run these commands and **paste the full output** into the sections below.
Do NOT mark this step complete until output is pasted.

```bash
cd rhizome && cargo test -p rhizome-lsp -p rhizome-mcp 2>&1 | tail -60
```

**Output:**
<!-- PASTE START -->
test test_get_definition_known_symbol ... ok
test test_get_complexity ... ok
test test_get_definition_missing_symbol ... ok
test test_get_complexity_single_function ... ok
test test_get_dependencies ... ok
test test_get_hover_info_no_lsp ... ok
test test_get_exports_rust ... ok
test test_get_enclosing_class_not_found ... ok
test test_get_region_for_parserless_outline ... ok
test test_get_parameters_single_function ... ok
test test_get_parameters_all ... ok
test test_get_imports_rust ... ok
test test_get_scope_inside_function ... ok
test test_get_scope_inside_impl ... ok
test test_get_structure ... ok
test test_get_scope_top_level ... ok
test test_get_structure_parserless_fallback_for_unsupported_file ... ok
test test_get_symbols_parserless_fallback_for_unsupported_file ... ok
test test_get_signature ... ok
test test_get_region_for_semantic_stable_id ... ok
test test_get_symbol_body ... ok
test test_get_symbol_body_not_found ... ok
test test_get_symbols_rust ... ok
test test_get_type_definitions_excludes_functions ... ok
test test_get_tests_finds_rust_tests ... ok
test test_get_type_definitions ... ok
test test_missing_required_param ... ok
test test_rename_symbol_no_lsp ... ok
test test_missing_file_error ... ok
test test_list_tools_returns_39_tools ... ok
test test_tool_schemas_have_required_fields ... ok
test test_go_to_definition ... ok
test test_summarize_file ... ok
test test_unknown_tool_error ... ok
test test_unified_mode_tools_list_returns_one_tool ... ok
test test_get_imports_python ... ok
test test_get_exports_python ... ok
test test_get_symbols_python ... ok
test test_unified_mode_call_via_rhizome_tool ... ok
test test_get_diff_symbols_runs ... ok
test test_search_symbols ... ok
test test_analyze_impact ... ok
test test_get_changed_files_runs ... ok
test test_export_unified_mode ... ok
test test_export_to_hyphae ... ok

test result: ok. 53 passed; 0 failed; 1 ignored; 0 measured; 0 filtered out; finished in 0.27s

   Doc-tests rhizome_lsp

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

   Doc-tests rhizome_mcp

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s
<!-- PASTE END -->

**Checklist:**
- [x] LSP child stderr is captured or forwarded in a controlled way
- [x] reader/process failure surfaces as an actionable error, not just transport loss
- [x] troubleshooting docs mention the improved logging/error path

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The verification script passes: `bash .handoffs/archive/rhizome/verify-lsp-runtime-safety-and-error-surfacing.sh`
3. All checklist items are checked

### Final Verification

Run the verification script and paste the full output:

```bash
bash .handoffs/archive/rhizome/verify-lsp-runtime-safety-and-error-surfacing.sh
```

**Output:**
<!-- PASTE START -->
PASS: serve-path regression test passes
PASS: rhizome-mcp tests pass
PASS: get_diagnostics via serve returns JSON-RPC without runtime panic
PASS: find_references via serve returns JSON-RPC without runtime panic
PASS: LSP client no longer discards stderr to Stdio::null
PASS: troubleshooting docs mention stderr and debug logging for live serve failures
Results: 6 passed, 0 failed
<!-- PASTE END -->

**Required result:** `Results: N passed, 0 failed`

If any checks fail, go back and fix the failing step. Do not mark complete
with failures.

## Context

This handoff comes from a verified repro in the current workspace:

- `get_symbols` works through Rhizome's tree-sitter path
- `get_diagnostics` and `find_references` panic the live MCP server under
  `rhizome serve --expanded`
- upstream Codex only sees `Transport closed`

Keep this handoff scoped to Rhizome runtime safety and local error surfacing.
Broader ecosystem logging standardization belongs in the separate cross-project
logging handoff.
