# Hyphae: Code Graph Import And Core Boundary

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/crates/hyphae-mcp/src/tools/memoir.rs`, `hyphae/crates/hyphae-mcp/src/tools/schema.rs`, `hyphae/crates/hyphae-mcp/src/tools/ingest.rs`, `hyphae/crates/hyphae-core/src/*embedder*.rs`, `hyphae/crates/hyphae-store/`, `hyphae/tests/`
- **Cross-repo edits:** none; coordinate with Rhizome handoff if identity semantics change at the producer
- **Non-goals:** no code graph schema redesign and no new embedding provider
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hyphae/verify-code-graph-import-and-core-boundary.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** `hyphae-mcp` code graph import, MCP tool schema, source listing path formatting, `hyphae-core` embedder implementations
- **Reference seams:** `septa/code-graph-v1.schema.json`, existing `import_code_graph` tests, `hyphae-core` traits and store interfaces
- **Spawn gate:** do not launch an implementer until the parent agent decides whether code memoir identity should include both `project_root` and `worktree_id`

## Problem

Hyphae accepts some code-graph input outside the Septa contract and advertises identity fields that are not stored or enforced. The audit also found `hyphae-core` owns I/O-heavy embedder implementations and `truncate_path` can panic on non-ASCII paths.

## What needs doing

1. Validate code-graph edge `relation` and `weight` against Septa at import time.
2. Make the MCP tool schema mirror Septa exactly.
3. Decide and implement identity handling for `project_root` and `worktree_id`, or stop accepting advertised fields until they are stored.
4. Move concrete HTTP/FastEmbed I/O out of the domain core or clearly isolate it behind an adapter boundary.
5. Make source path truncation UTF-8 safe.

## Verification

```bash
cd hyphae && cargo test -p hyphae-mcp import_code_graph
cd hyphae && cargo test -p hyphae-mcp source
bash .handoffs/hyphae/verify-code-graph-import-and-core-boundary.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] missing or unknown edge relations are rejected
- [ ] edge weights outside `0.0..=1.0` are rejected
- [ ] code memoir identity is stored, enforced, or removed from the public schema
- [ ] concrete network/filesystem embedders do not make `hyphae-core` a catch-all adapter crate
- [ ] source path truncation handles non-ASCII paths safely
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the 2026-04-26 Rust ecosystem audit. Severity: high/medium/low. This handoff keeps Hyphae-owned fixes together.
