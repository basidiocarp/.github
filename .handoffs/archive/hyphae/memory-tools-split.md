# Hyphae memory.rs Tool Split

## Problem

`hyphae/crates/hyphae-mcp/src/tools/memory.rs` is 1,475 lines containing 15+ MCP tool
handlers. `tool_recall` alone is 320 lines with 6 levels of nesting in two locations.
Lesson extraction, evaluation, and keyword extraction are mixed in with core CRUD tools.

## What exists (state)

- **File:** `hyphae/crates/hyphae-mcp/src/tools/memory.rs` (1,475 lines)
- **`tool_recall`:** 320 lines (268-588) with 6-level nesting
- **`tool_store`:** 196 lines (70-266)
- **`tool_extract_lessons`:** 126 lines (1162-1287)
- **`tool_evaluate`:** 162 lines (1357-1519)
- **`normalize_identity`:** duplicated 3x across MCP modules

## What needs doing (intent)

Split memory.rs into focused modules and consolidate duplicated helpers.

---

### Step 1: Split tool handlers

**Project:** `hyphae/`
**Effort:** 1-2 hours

Create:
- `memory/mod.rs` — re-exports
- `memory/store.rs` — tool_store, tool_update, tool_forget, tool_invalidate
- `memory/recall.rs` — tool_recall (320 lines, deserves its own file)
- `memory/lessons.rs` — tool_extract_lessons
- `memory/evaluate.rs` — tool_evaluate
- `memory/helpers.rs` — shared utilities (keyword extraction, dedup)

### Step 2: Consolidate normalize_identity

Move `normalize_identity` to `tools/mod.rs` and import from:
- `tools/memory.rs` (currently tools/mod.rs:41)
- `tools/session.rs` (currently session.rs:130)
- `cli/commands/session.rs` (currently session.rs:460 — use pub from tools)

### Step 3: Flatten nesting in tool_recall

Extract helpers for the two 6-level-deep paths:
- Auto-consolidation hint (lines 307-336) → `compute_consolidation_hint()`
- Code context expansion (lines 460-522) → `expand_code_context()`

**Checklist:**
- [ ] No single file exceeds 500 lines
- [ ] `normalize_identity` exists in exactly one location
- [ ] No nesting >4 levels
- [ ] All 606 tests pass

## Context

Found during global ecosystem audit (2026-04-04), Layer 2 structural review of hyphae.
