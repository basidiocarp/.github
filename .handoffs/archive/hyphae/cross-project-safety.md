# Hyphae: Fix cross-project memory data loss

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** hyphae/...
- **Cross-repo edits:** none
- **Non-goals:** content_hash fix, purge/quality fixes (separate handoffs)
- **Verification contract:** run repo-local commands named below
- **Completion update:** update `.handoffs/HANDOFFS.md` and archive when done

## Problems

### 1 — consolidate_topic deletes across project boundaries (data loss)
`crates/hyphae-store/src/store/memory_store.rs:1521-1533`

The DELETE in `consolidate_topic` is `WHERE topic = ?1 AND invalidated_at IS NULL` with no project filter. When two projects share a topic name (e.g. both use `"architecture"` or `"decisions/auth"`), a consolidation request from project A silently deletes and overwrites project B's memories under that topic. The replacement consolidated memory carries project A's scope. This is irreversible data loss.

Fix: add a project filter to the DELETE: `WHERE topic = ?1 AND (project = ?2 OR (?2 IS NULL AND project IS NULL)) AND invalidated_at IS NULL`. Apply the same filter to any SELECT that feeds the consolidation.

### 2 — tool_store dedup can update memories from the wrong project
`crates/hyphae-mcp/src/tools/memory/store.rs:118-170`

The similarity-dedup path calls `store.search_hybrid(...)` and checks `existing.topic == topic` before doing an in-place update, but does not check `existing.project == memory.project`. When `project` is `None` (global scope), the hybrid search can match a memory from any project. A caller writing to project A can silently overwrite a semantically similar memory in project B.

Fix: add `existing.project == memory.project` (or both `None`) to the similarity-dedup guard before treating the hit as the same memory.

## Implementation Seam

- `crates/hyphae-store/src/store/memory_store.rs:1521` — add project filter to DELETE and surrounding SELECTs
- `crates/hyphae-mcp/src/tools/memory/store.rs:118` — add project equality check to dedup guard

## Verification

```bash
cd /Users/williamnewton/projects/basidiocarp/hyphae
cargo test --workspace 2>&1 | tail -5
cargo test -p hyphae-store 2>&1 | tail -5
```

## Checklist

- [x] `consolidate_topic` DELETE is scoped to the caller's project
- [x] Cross-project consolidation is impossible even with shared topic names
- [x] `tool_store` dedup guard checks project equality before in-place update
- [x] All tests pass

## Verification Output

```
cargo build --release: Finished `release` profile [optimized] target(s) in 1m 06s
cargo test: all crates passed (176 + 81 + 1 + 59 + ... tests, 0 failed)
```
