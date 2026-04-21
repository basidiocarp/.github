# Rhizome symbol_tools.rs Split

## Problem

`rhizome/crates/rhizome-mcp/src/tools/symbol_tools.rs` is 2,288 lines containing
22 tool handlers, 15+ private helpers, inline JSON schema definitions, and a global
`PROJECT_SUMMARY_CACHE` static. It is the second-largest file in the ecosystem.
Every change to any symbol tool requires touching this file. The `analyze_impact`
function alone is 230 lines.

## What exists (state)

- **File:** `rhizome/crates/rhizome-mcp/src/tools/symbol_tools.rs` (2,288 lines)
- **22 tool handlers** in one file
- **`analyze_impact`:** 230 lines (lines 537-764)
- **`PROJECT_SUMMARY_CACHE`:** global static at line 2148
- **`use std::sync::Mutex`:** buried at line 2144 instead of top of file

## What needs doing (intent)

Split into submodules by tool category.

---

### Step 1: Split into submodules

**Project:** `rhizome/`
**Effort:** 2-3 hours
**Depends on:** `rhizome/build-fix-and-format.md` (must compile first)

Create:
- `symbol_tools/mod.rs` — re-exports only
- `symbol_tools/query.rs` — get_symbols, get_structure, get_definition, search_symbols
- `symbol_tools/analysis.rs` — analyze_impact, get_complexity, get_dependencies, get_call_sites
- `symbol_tools/git.rs` — get_diff_symbols, get_changed_files
- `symbol_tools/navigation.rs` — go_to_definition, get_scope, get_enclosing_class
- `symbol_tools/onboard.rs` — rhizome_onboard + summary cache
- `symbol_tools/params.rs` — shared `required_str`, `required_u32` (also used by edit_tools)

### Step 2: Extract analyze_impact helpers

Split the 230-line function into:
- `compute_risk_factors()`
- `compute_references_by_file()`
- `format_impact_response()`

**Checklist:**
- [x] No single file exceeds 600 lines
- [x] All tests pass (`cargo test --all`)
- [x] `required_str`/`required_u32` shared between symbol_tools and edit_tools
- [x] Cache static is in `onboard.rs`, clearly visible

## Context

Found during global ecosystem audit (2026-04-04), Layer 2 structural review of rhizome.
Depends on `rhizome/build-fix-and-format.md` completing first.
