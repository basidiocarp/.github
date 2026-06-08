# try_lsp_or_heuristic silently falls back to the heuristic backend when LSP init fails

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** `rhizome/crates/rhizome-mcp/src/tools/mod.rs`
- **Cross-repo edits:** none
- **Hot shared files touched:** none
- **Assignee type:** `agent`
- **Verification contract:** `cd rhizome && cargo test -p rhizome-mcp` + `cargo clippy -p rhizome-mcp`
- **Origin:** Stage 1 review CONCERN 3 of `dispatch-auto-lsp-fallback-observability.md`.

## Problem

`try_lsp_or_heuristic` (`crates/rhizome-mcp/src/tools/mod.rs`, ~line 600, invoked from `dispatch_outline`) resolves a tool to `ActiveBackend::Lsp`, calls `ensure_lsp()`, then:

```rust
match lsp.as_ref() {
    Some(backend) => match lsp_fn(backend, args) {
        Ok(value) => Ok(value),
        Err(_) => heuristic_fn(args),
    },
    None => heuristic_fn(args),   // silent fallback — no diagnostic
}
```

This is the same silent-downgrade observability gap addressed for `dispatch_auto` in the sibling handoff, but for a different dispatch helper and a different fallback target (heuristic backend, not tree-sitter). Two paths downgrade silently: (a) `None` when LSP init fails, and (b) `Err(_)` when the LSP call itself errors and the result is quietly swapped for a heuristic one.

## Proposed direction (confirm at seam time)

Mirror the `dispatch_auto` fix: emit a per-tool warn-once `tracing::warn!` (then debug) at the `None` arm naming the tool. Consider whether the `Err(_) => heuristic_fn(args)` arm also deserves a log (it swallows an LSP error — arguably a `tracing::debug!` with the error). Do NOT change fallback behavior; graceful degradation must remain.

## Implementation Seam

**CONFIRMED** — seam pass 2026-06-05 (orchestrator). Existence check PASS: the silent-fallback body is unchanged by #49's fix (5e4bfa3, which touched `dispatch_auto` only).

| Field | Value |
|-------|-------|
| Target file | `crates/rhizome-mcp/src/tools/mod.rs` |
| Seam stamp | `5e4bfa3` (latest commit on file == the #49 fix; re-verify if it advances) |
| Primary symbol | `ToolDispatcher::try_lsp_or_heuristic` (defn at line 594, 0-based) |
| Insertion points | the two fallback arms in the body: `Err(_) => heuristic_fn(args)` and `None => heuristic_fn(args)` |
| Callers (census) | 2, both module-local in `dispatch_outline`: line 421→ no, line 422 `ActiveBackend::Lsp` arm, and line 436 `ResolvedBackend::Lsp` ts-failure-fallback arm. ≤5 callers, all in-repo → no cross-call invariant required; module-local tests suffice. |
| Reference fix | #49 `5e4bfa3` added a per-tool warn-once `OnceLock<Mutex<HashSet<String>>>` keyed on `tool_name` at `dispatch_auto`'s `None` arm. |

**Design wrinkle (decide at implementation):** `try_lsp_or_heuristic`'s signature is `(&self, args, lsp_fn, heuristic_fn)` — it has **no `tool_name` param**, so #49's `tool_name`-keyed warn-once cannot be copied verbatim. Two options: (a) thread a `tool_name: &str` (or `&'static str` call-site label) param through the **two** call sites at lines 422 and 436; or (b) key the warn-once on a single static label (e.g. `"outline"`) since both callers are in `dispatch_outline`. Option (a) is more precise and matches #49's granularity; option (b) is smaller-diff. Implementer picks; both stay within the allowed write scope (single file).

**Behavioral invariants (must not break):**
1. Fallback behavior is unchanged — when LSP is unavailable or errors, the heuristic result is still served (graceful degradation preserved); only a diagnostic is added.
2. The result *shape* returned to the caller is identical to today's (the warn is a side effect, not a value change).
3. No log spam — repeat downgrades of the same tool/label drop to `debug!` after the first `warn!` (mirror #49's once-then-debug keying).

## Residual Work

| Finding | Disposition | Link / Note |
|---------|-------------|-------------|
| _(none on open handoff)_ | — | — |

## Completion

- **Commit:** —
