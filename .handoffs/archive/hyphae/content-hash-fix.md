# Hyphae: Fix content_hash TOCTOU and CLI ingest path

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none
- **Non-goals:** bench-retrieval changes, project scoping changes (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problem

Three related HIGH-severity bugs, all rooted in hash computation being outside `ingest_file`.

### Bug 1 — TOCTOU + double file read
`crates/hyphae-mcp/src/tools/ingest.rs:66-86`

`tool_ingest_file` reads the file a second time solely to compute the hash, after `ingest_file` already read it to produce chunks. Two consequences:
- **TOCTOU**: if the file is modified between reads, stored chunks and stored hash are from different file states. Future re-ingests will false-"unchanged" and serve stale content permanently.
- **Performance**: for large files, two full reads and two full copies in memory simultaneously.

### Bug 2 — CLI ingest path never sets content_hash
`crates/hyphae-ingest/src/lib.rs:74`

`ingest_file` always returns `Document { content_hash: None, ... }`. The hash is only patched in by the MCP handler after the call. The CLI path (`crates/hyphae-cli/src/commands/docs.rs`) calls `ingest_file` → `store.store_document(doc)` without ever setting the hash. Every CLI-ingested document gets `content_hash = NULL` forever. Skip-on-reindex is completely inoperative on the CLI surface.

## Implementation Seam

- **Likely files:**
  - `crates/hyphae-ingest/src/lib.rs` — `ingest_file` function; add hash computation here from the bytes already read
  - `crates/hyphae-mcp/src/tools/ingest.rs:66-86` — remove the second `std::fs::read` call; use hash returned from `ingest_file`
  - `crates/hyphae-cli/src/commands/docs.rs` — apply same hash logic as MCP path (or use same return value from `ingest_file`)
- **Spawn gate:** identify the `IngestResult` or equivalent return type from `ingest_file` and confirm it can carry a hash field without breaking callers

## What needs doing

1. Add `content_hash: Option<String>` to the return value of `ingest_file` (or the `Document` it returns, whichever is cleaner).
2. Inside `ingest_file`, compute the hash from the bytes already read for chunking — before or after chunking, but using the same bytes.
3. Remove the second `std::fs::read` call in `tool_ingest_file` (`ingest.rs:66`). Use the hash from the `ingest_file` return value instead.
4. In `docs.rs` (CLI ingest path), ensure `content_hash` is set on the document before calling `store.store_document`.
5. Keep the `compute_content_hash` function where it is; just move the call site.

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/hyphae
cargo test --workspace 2>&1 | tail -5
cargo test -p hyphae-mcp -- contract 2>&1 | tail -5
```

Expected: all pass. The existing contract test `ingest_file_skips_unchanged_content_on_second_call` should continue to pass and will now also be valid for the CLI path once fixed.

## Checklist

- [x] `ingest_file` computes and returns `content_hash`
- [x] MCP handler no longer does a second `std::fs::read`
- [x] CLI ingest path stores documents with non-null `content_hash`
- [x] All workspace tests pass
- [x] MCP contract tests pass

## Verification Evidence

```
cargo build --release: Finished `release` profile [optimized] target(s) in 1m 23s
cargo test --workspace: 759 tests total, 0 failed (across all crates)
cargo test -p hyphae-mcp -- contract: 1 passed, 0 failed
```
