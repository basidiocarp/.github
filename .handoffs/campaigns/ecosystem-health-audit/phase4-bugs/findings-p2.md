# Phase 4 Pass 2 — Bug Audit Deep Review

Date: 2026-04-22
Pass: Deep Review (agent-driven)

## Summary

Phase 4 Pass 1 PASS verdict confirmed. No new bugs found in deep review. All cross-boundary error propagation is correct, external data assumptions are safe, arithmetic is bounded, and error context is present at important boundaries.

---

## Triage Results

### Error Propagation at Cross-Boundary Calls

#### hyphae MCP → store

**Verdict: PASS**

`hyphae/crates/hyphae-mcp/src/server.rs`:
- Store errors return `JsonRpcResponse::err(id, -32603, format!("db error: {error}"))` — not swallowed
- Tool dispatch result properly serialized; serialization failure caught and returned as error response

#### canopy tool handlers → CLI response

**Verdict: PASS**

`canopy/src/tools/task.rs`:
- Validation errors returned as `ToolResult::error()`
- Store creation errors returned as `ToolResult::error(format!("failed to create task: {e}"))`
- Evidence lookup failures use `.ok()` fallback (returns empty vec, not panic)

#### cortina hook failure handling

**Verdict: PASS (silent-fail correctly implemented)**

`cortina/src/adapters/mod.rs` lines 140-142:
```rust
if let Err(e) = f() {
    tracing::warn!("cortina: hook {} failed: {:#}", hook_name, e);
}
```
Returns `Ok(())` regardless of hook outcome — does not propagate to caller. Matches CLAUDE.md: "does not block outer tool on hook failure."

---

### Implicit Assumptions on External Data

#### canopy reading hyphae results

**Verdict: PASS**

Canopy does not directly parse hyphae output. Evidence references are typed ULIDs; canopy does not deserialize raw hyphae JSON. Type safety is maintained at the boundary.

#### mycelium parsing command output

**Verdict: PASS**

`mycelium/src/dispatch/exec.rs`:
- `String::from_utf8_lossy()` handles invalid UTF-8 without panicking
- Non-zero exit codes handled explicitly
- `validate_filter_output()` implements graceful fallback rules:
  - Never return empty from non-empty input
  - >95% reduction on small output triggers fallback to raw passthrough

#### annulus reading canopy/hyphae SQLite databases

**Verdict: PASS with note**

`annulus/src/notify.rs` lines 19-34:
- Parameterized queries (no SQL injection)
- `.get()` calls assume column layout by position; no runtime schema validation
- SQLite errors are `Result<T>` and caught with `filter_map(Result::ok)` — no panic risk

**Note:** Schema changes in canopy's DB would cause `annulus` runtime errors (not panics). The errors would be caught gracefully. Low risk, but the schema contract is implicit. Recommend documenting it.

---

### Integer Overflow / Boundary Conditions

#### hyphae recall-bundle budget

**Verdict: PASS**

`hyphae/crates/hyphae-cli/src/commands/recall_bundle.rs`:
- Budget is `usize` with `default_value = "4000"`
- Token estimation: `(text.len() + 3) / 4` — safe for any usize
- Greedy accumulation checks `if used_tokens + item_tokens > args.budget` before accumulating
- No overflow risk; bounds check prevents runaway consumption

#### mycelium token counting

**Verdict: PASS**

Uses `text.split_whitespace().count()` — whitespace split is safe for any input, count produces usize. No division-by-zero or overflow risk.

---

### Concurrency / TOCTOU

#### canopy SQLite write handling

**Verdict: PASS (low-severity advisory)**

`canopy/src/store/mod.rs`:
- No explicit WAL mode pragma found in the open path
- SQLite defaults to ROLLBACK journal mode — writes take exclusive locks
- rusqlite defaults to `busy_timeout(5000)` (5 seconds)
- Multiple agents writing simultaneously serialize via SQLite's lock queue — no corruption risk

**Advisory:** Contention under heavy multi-agent load would manifest as "database locked" errors after 5 seconds. Data integrity is preserved (ACID guarantees), but throughput degrades. Explicit WAL mode would improve concurrency. Not a bug, but a potential performance issue.

---

### Error Context at Boundaries

#### mycelium dispatch → subprocess

**Verdict: PASS**

`mycelium/src/dispatch/exec.rs`:
```rust
.spawn()
.context("Failed to execute command")?;
.context("Failed to capture child stdout")?
.context("Failed to capture child stderr")?
.context("Failed waiting for command")?
```
All subprocess errors carry context identifying the operation.

#### cortina adapters → external tools

**Verdict: PASS**

`cortina/src/adapters/mod.rs` lines 140-142:
```rust
tracing::warn!("cortina: hook {} failed: {:#}", hook_name, e);
```
Hook name and full error chain included. `{:#}` format shows the complete cause chain.

#### hyphae MCP tools → ToolResult

**Verdict: PASS**

Throughout `hyphae/crates/hyphae-mcp/src/tools/`:
```rust
return ToolResult::error(format!("failed to update: {e}"));
```
All tool errors wrapped in `ToolResult::error()` with context string identifying the operation.

---

## Revised Severity Rankings

No issues rise above the Phase 1 advisory level:

1. **Low advisory** — Canopy SQLite without explicit WAL mode: contention possible under multi-agent load, no data loss risk
2. **Low advisory** — Annulus assumes canopy schema implicitly: safe because errors are caught, but schema contract should be documented

No new bugs. No ranking changes from Phase 1.

---

## New Issues Found

None.

---

## False Positive Confirmation

Phase 4 Pass 1 PASS verdict: **CONFIRMED**

All findings from Pass 1 held under deep review:
- Zero production panics
- Zero truncating casts on external input
- All CLI entry points use typed parsing
- All MCP handlers validate required fields
- All cross-boundary errors carry context

---

## Overall Verdict: PASS

**Confidence:** High

| Category | Finding | Verdict |
|----------|---------|---------|
| Error propagation | Errors bubble correctly, not swallowed | PASS |
| External data assumptions | Type-safe boundaries, graceful fallback | PASS |
| Integer overflow | Bounded arithmetic, safe estimations | PASS |
| Concurrency | SQLite ACID guarantees; WAL mode advisory | PASS (advisory) |
| Error context | Context present at all important boundaries | PASS |

**Key strengths:**
- Consistent use of `.context()` on cross-boundary errors
- Graceful fallback patterns (mycelium filter validation, cortina silent-fail)
- Type safety at boundaries (typed ULIDs, typed enums)
- Comprehensive error handling in tool handlers and store operations
