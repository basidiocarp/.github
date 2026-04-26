# Mycelium: Content-Aware Routing

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** `mycelium/src/dispatch/exec.rs` (extend), `mycelium/src/dispatch/content_router.rs` (new), `mycelium/src/dispatch/families.rs` (register content router)
- **Cross-repo edits:** none
- **Non-goals:** no ML-based content classification; no reversible CCR compression; detection is heuristic only; does not change how compiled filters are registered
- **Verification contract:** run the repo-local commands below
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md`

## Source

Inspired by headroom's Wave 2 audit and wave2-ecosystem-synthesis Theme 5 (content-aware output compression):

> "ContentRouter with SmartCrusher for JSON, CodeCompressor for AST, Kompress-base for general text — routing by output shape, not just command family, is the single biggest compression win available after command-family dispatch."
> — headroom Wave 2 audit, ContentRouter section

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:**
  - `src/dispatch/exec.rs` — execution layer; extend to call content detection after command runs and before output is returned
  - `src/dispatch/content_router.rs` (new) — `ContentType` enum, detection heuristics, `ContentRouter` struct, per-type filter logic
  - `src/dispatch/families.rs` — command-family dispatch; wire content router as a post-execution step
- **Reference seams:**
  - Existing dispatch flow in `src/dispatch/exec.rs` — read this first to understand where output lands after execution
  - `src/dispatch/routes.rs` — understand how routes hand off to exec before touching exec
- **Spawn gate:** do a short seam-finding pass first — read `exec.rs` and `families.rs` to identify exactly where output is produced and where filtering is currently applied, then spawn

## Problem

Mycelium currently has no awareness of the content type of command output. Every output — whether JSON from `cargo metadata`, a diff from `git diff`, or prose from `npm install` — flows through the same general-text filter path. This is correct-by-default but leaves compression headroom on the table: JSON can be compacted by stripping nulls and truncating long arrays; code/diff output can be compacted by preserving structure while truncating large hunks; only general text needs the prose-oriented path.

The dispatch layer already routes by command family before execution. Adding a content-type detection step after execution — before the output is returned to the caller — makes the compression strategy a function of what actually came out, not just what command ran.

## What needs doing (intent)

Add a content-aware routing layer to mycelium's dispatch exec path:

1. Define a `ContentType` enum: `Json`, `Code`, `StructuredText`, `GeneralText` — detected from output heuristics (leading `{`/`[`, diff format markers, etc.)
2. Define a `ContentRouter` struct that maps `ContentType` to the appropriate filter strategy
3. Add content-type detection to the exec layer, running after command execution and before output is returned
4. Add a JSON-specific filter: extract error keys, strip null fields, truncate arrays beyond a configurable item limit
5. Add a code-specific filter: preserve structure, truncate large hunks, keep lines containing error markers
6. Wire `ContentRouter` into the existing families dispatch so content-aware routing is additive — the existing per-family compiled filters still run first, and `ContentRouter` handles the remainder

## Data Model

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ContentType {
    Json,
    Code,
    StructuredText,
    GeneralText,
}

pub struct ContentRouter {
    pub json_max_array_items: usize,  // default: 20
    pub code_max_hunk_lines: usize,   // default: 50
}
```

## Scope

- **Allowed files:**
  - `mycelium/src/dispatch/exec.rs` — extend with post-execution content detection call
  - `mycelium/src/dispatch/content_router.rs` — new file, owns `ContentType`, `ContentRouter`, detection, and per-type filter logic
  - `mycelium/src/dispatch/families.rs` — register `ContentRouter` as a post-execution step
- **Explicit non-goals:**
  - No ML-based or regex-trained content classification
  - No reversible CCR compression scheme
  - No changes to compiled filter registration or precedence logic
  - No new CLI flags or config file changes in this handoff

---

### Step 1: Read the exec and families seam

**Project:** `mycelium/`
**Effort:** tiny (read-only)
**Depends on:** nothing

Before writing code, read `src/dispatch/exec.rs` and `src/dispatch/families.rs` to understand:
- Where command output is produced and what type it has (string, bytes, stream)
- Where filtering is currently applied relative to the exec return path
- How `families.rs` hands off to exec

Do not write any code in this step.

#### Verification

```bash
cd mycelium && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] Exec output production point identified
- [ ] Current filter application point identified
- [ ] Families-to-exec handoff understood

---

### Step 2: Define `ContentType` and `ContentRouter`

**Project:** `mycelium/`
**Effort:** small
**Depends on:** Step 1

Create `src/dispatch/content_router.rs`. Define:

- `ContentType` enum with variants `Json`, `Code`, `StructuredText`, `GeneralText`
- Detection function `detect_content_type(output: &str) -> ContentType`:
  - `Json`: output (after trimming leading whitespace) starts with `{` or `[`
  - `Code`: output contains diff hunk markers (`@@`) or fence markers (`` ``` ``), or the majority of lines begin with `+`, `-`, or ` ` (space) consistent with unified diff format
  - `StructuredText`: output has consistent repeated structure (e.g., key-value pairs, table rows) — use a simple heuristic: more than half of lines contain `:` or `|`
  - `GeneralText`: fallback
- `ContentRouter` struct with `json_max_array_items: usize` (default 20) and `code_max_hunk_lines: usize` (default 50)
- `ContentRouter::route(&self, output: &str) -> String` — detect type and dispatch to the appropriate filter method
- `ContentRouter::filter_json(&self, output: &str) -> String` — strip null-valued fields, truncate arrays beyond `json_max_array_items`
- `ContentRouter::filter_code(&self, output: &str) -> String` — keep lines containing `error`, `warning`, `FAIL`, or hunk headers; truncate runs of context lines beyond `code_max_hunk_lines`
- `ContentRouter::filter_structured(&self, output: &str) -> String` — pass through (reserved for future structured compression)
- `ContentRouter::filter_general(&self, output: &str) -> String` — pass through (delegates to existing general-text filter path)

#### Verification

```bash
cd mycelium && cargo build 2>&1 | tail -5
```

**Checklist:**
- [ ] `cargo build` succeeds with new module added to `src/dispatch/mod.rs`
- [ ] `ContentType` variants compile
- [ ] `ContentRouter` struct compiles with default-value constants

---

### Step 3: Wire content detection into exec

**Project:** `mycelium/`
**Effort:** small
**Depends on:** Step 2

In `src/dispatch/exec.rs`, after command output is collected and existing compiled filters have run, call `ContentRouter::route` on the output. Use a default `ContentRouter` instance (configurable via `Default` impl). Return the routed output instead of the pre-routing output.

The content router must run after any per-family compiled filter. If the compiled filter already reduced the output substantially, the content router still runs — it is a second-pass compression, not a replacement.

#### Verification

```bash
cd mycelium && cargo build --release 2>&1 | tail -5
```

**Checklist:**
- [ ] `cargo build --release` succeeds
- [ ] Content router call visible in `exec.rs` diff
- [ ] Compiled filter precedence preserved (compiled filter still runs first)

---

### Step 4: Register in families dispatch

**Project:** `mycelium/`
**Effort:** tiny
**Depends on:** Step 3

In `src/dispatch/families.rs`, ensure that the exec path invoked for each command family flows through the updated `exec.rs` and therefore through `ContentRouter`. If `families.rs` calls exec indirectly this may require no change — confirm during the seam-finding pass in Step 1 and note the outcome here.

If `families.rs` applies any family-level post-processing that bypasses `exec.rs`, extend those paths to also call `ContentRouter::route`.

#### Verification

```bash
cd mycelium && cargo build --release 2>&1 | tail -5
```

**Checklist:**
- [ ] All command families flow through the content router
- [ ] No family-level bypass paths remain

---

### Step 5: Add unit tests

**Project:** `mycelium/`
**Effort:** small
**Depends on:** Step 4

In `src/dispatch/content_router.rs`, add `#[cfg(test)]` tests:
- `detect_content_type` returns `Json` for output starting with `{` and `[`
- `detect_content_type` returns `Code` for output with `@@` hunk markers
- `detect_content_type` returns `GeneralText` for plain prose
- `filter_json` strips null fields and truncates arrays beyond `json_max_array_items`
- `filter_code` keeps error lines and truncates long context runs

```bash
cd mycelium && cargo test content 2>&1 | tail -20
```

**Checklist:**
- [ ] All content-router tests pass
- [ ] JSON truncation and null-stripping tested
- [ ] Code hunk truncation tested

---

### Step 6: Full suite

```bash
cd mycelium && cargo test 2>&1 | tail -20
cd mycelium && cargo clippy --all-targets -- -D warnings 2>&1 | tail -20
cd mycelium && cargo fmt --check 2>&1
```

**Checklist:**
- [ ] All tests pass
- [ ] Clippy clean
- [ ] Fmt clean

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. The full test suite passes
3. All checklist items are checked
4. `.handoffs/HANDOFFS.md` is updated to reflect completion

## Follow-on

- `ContentRouter` defaults can be made configurable via mycelium's config file once the config layer supports typed subsections
- `filter_structured` is a placeholder — a table-aware compressor for key-value and tabular output is a natural Wave 3 candidate
- JSON path filtering (keep only specific key paths) would further reduce JSON payloads for known command outputs like `cargo metadata`

## Context

Spawned from headroom Wave 2 audit (2026-04-23) and wave2-ecosystem-synthesis Theme 5. Mycelium has no content-type awareness in its current dispatch layer — every output path goes through general-text filtering regardless of whether the output is JSON, diff, or prose. The headroom pattern of routing by output shape after execution is a clean fit for the existing exec-layer architecture: detect content type from heuristics, dispatch to a type-appropriate compressor, keep the general path as the safe fallback.
