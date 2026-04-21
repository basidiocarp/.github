# Hyphae: Quality fixes (project scoping, bench, fixture assertion)

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none
- **Non-goals:** content_hash TOCTOU fix (separate handoff)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — Project scoping asymmetry in get_document_by_path
`crates/hyphae-store/src/store/chunk_store.rs:123-130`

Query is `WHERE source_path = ?1 AND (project = ?2 OR ?2 IS NULL)`. When `project` is `None`, it matches documents across all projects. Cross-project path collisions cause incorrect skip-on-reindex: a document at `/repo/README.md` in project A will be found when checking project B's ingest if B passes `project = None`. Fix: use exact match `WHERE source_path = ?1 AND project IS ?2` so NULL-for-NULL is also exact.

### 2 — Silent swallow of file read failure in ingest handler
`crates/hyphae-mcp/src/tools/ingest.rs:66`

`if let Ok(content) = std::fs::read(...)` silently discards I/O errors. When the read fails, the document is stored with `content_hash = None` and no warning is emitted. Add a `warn!` log call in the else branch.

### 3 — bench-retrieval operates on synthetic data with no indication
`crates/hyphae-cli/src/commands/bench.rs:170-196`

The command ignores the real store and uses `SqliteStore::in_memory()` per fixture. The help text gives no indication of this. Operators running `hyphae bench-retrieval` against their live store will get meaningless results without realizing it. Add a note to the command description or help text: "operates on synthetic fixtures, not your configured database."

### 4 — Fixture with no assertions always fails
`crates/hyphae-cli/src/commands/bench.rs:154-158`

A `QueryFixture` with both `expected_rank_1_contains` and `expected_top_k_contains` set to `None` counts as a failure. Either treat missing assertions as "skipped" or require at least one assertion in fixture validation.

## Implementation Seam

- `crates/hyphae-store/src/store/chunk_store.rs:123` — fix SQL query
- `crates/hyphae-mcp/src/tools/ingest.rs:66` — add warn! log
- `crates/hyphae-cli/src/commands/bench.rs` — fix help text and no-assertion case

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/hyphae
cargo test --workspace 2>&1 | tail -5
cargo clippy 2>&1 | tail -10
```

## Checklist

- [ ] `get_document_by_path` uses exact project match including NULL-for-NULL
- [ ] File read failure in ingest handler logs a warning
- [ ] `bench-retrieval` help text discloses synthetic-data behavior
- [ ] Fixture with no assertions is treated as skipped, not failed
- [ ] All tests pass, clippy clean
