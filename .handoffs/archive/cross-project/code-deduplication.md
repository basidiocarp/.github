# Cross-Project Code Deduplication

## Problem

Several utility patterns are duplicated across 2-4 projects instead of living in spore
(the shared infrastructure crate). Each duplicate is a divergence risk — bug fixes
applied to one copy but not the other.

## What exists (state)

| Pattern | Projects | Lines Each |
|---------|----------|-----------|
| `CLAUDE_SESSION_ID` env reading | cortina, canopy, mycelium (x2) | 3-5 |
| `spore_tool()` name-to-Tool mapping | cortina, stipe | 10-15 |
| `find_symbol_by_name` | rhizome treesitter + lsp | 20 |
| `vscode_cline_settings_path` | stipe ecosystem + doctor | 5 |
| `truncate_str` | hyphae server.rs + memory.rs | 5 |

## What needs doing (intent)

Extract shared patterns to spore or consolidate within their project.

---

### Step 1: Add `claude_session_id()` to spore

**Project:** `spore/`
**Effort:** 15 min

Add `pub fn claude_session_id() -> Option<String>` to spore that reads
`CLAUDE_SESSION_ID` from the environment. Replace the 4 copies in cortina, canopy,
and mycelium with `spore::claude_session_id()`.

### Step 2: Add `Tool::from_binary_name()` to spore

**Project:** `spore/`
**Effort:** 10 min

Add a method on `spore::Tool` that maps binary names ("hyphae", "mycelium", etc.)
to enum variants. Replace `spore_tool()` functions in cortina and stipe.

### Step 3: Consolidate find_symbol_by_name in rhizome-core

**Project:** `rhizome/`
**Effort:** 15 min

Move the identical `find_symbol_by_name` from both `rhizome-treesitter/src/lib.rs:396`
and `rhizome-lsp/src/lib.rs:232` to `rhizome-core` as a free function or method on
`&[Symbol]`. Both crates already depend on rhizome-core.

### Step 4: Consolidate within-project duplicates

- **stipe:** Deduplicate `vscode_cline_settings_path` between `ecosystem/clients.rs:173`
  and `commands/doctor/config_checks.rs:155`
- **hyphae:** Deduplicate `truncate_str` between `mcp/server.rs:17` and `tools/memory.rs:20`

**Checklist:**
- [x] `claude_session_id` exists once in spore, used by cortina/canopy/mycelium
- [x] `Tool::from_binary_name()` exists in spore, used by cortina/stipe
- [x] `find_symbol_by_name` exists once in rhizome-core
- [x] No within-project duplicates remain
- [x] All affected project tests pass

## Completion Notes

- `spore` now exposes `claude_session_id()` and `Tool::from_binary_name(...)`, and the
  consumer repos were updated to the pushed `spore` revision before closeout.
- `rhizome` now shares `find_symbol_by_name` from `rhizome-core` instead of repeating
  it in both the LSP and tree-sitter crates.
- `stipe` now uses the shared VS Code Cline settings-path helper, and `hyphae`
  moved the UTF-8 truncation helper to a crate-level text utility instead of
  routing it through `tools::memory`.

## Verification

```text
spore: cargo test
cortina: cargo test
canopy: cargo test
mycelium: cargo test
stipe: cargo test
rhizome: cargo test -p rhizome-core -p rhizome-lsp -p rhizome-treesitter
hyphae: cargo test -p hyphae-mcp
```

## Context

Found during global ecosystem audit (2026-04-04), Layer 3 cross-project consistency.
