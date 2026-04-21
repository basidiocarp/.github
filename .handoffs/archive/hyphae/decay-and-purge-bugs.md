# Hyphae Decay and Purge Bugs (H1/H2)

## Problem

Two data integrity bugs in hyphae's core memory system:

**H1 — Negative weight after decay:** `apply_decay` in `memory_store.rs:927` can produce
negative weights for low-importance memories with low access counts. No `MAX(0.0, ...)`
guard in the SQL UPDATE path. The `.clamp(0.0, 1.5)` at line 892 is in hybrid search
scoring, not the decay path.

**H2 — Orphaned FTS rows after purge:** `purge_project` and `purge_before_date` in
`purge.rs` delete from `chunks` without matching `DELETE FROM chunks_fts`. `chunks_fts`
is a standalone FTS5 table (no `content=` directive). After purge, stale FTS entries
are returned by `search_chunks_fts` for non-existent documents.

## What exists (state)

- **H1 file:** `hyphae/crates/hyphae-store/src/store/memory_store.rs:927`
- **H1 SQL:** `UPDATE memories SET weight = weight * (1.0 - (1.0 - ?1) * 2.0 / ...)`
- **H2 file:** `hyphae/crates/hyphae-store/src/store/purge.rs`
- **H2 schema:** `hyphae/crates/hyphae-store/src/schema.rs:341` confirms standalone FTS5
- **Per-document delete:** `chunk_store.rs:165` correctly handles FTS deletion for single docs
- **Tests:** `purge_before_date` has zero test coverage

## What needs doing (intent)

Fix both bugs and add regression tests.

---

### Step 1: Fix H1 — Clamp decay weight to non-negative

**Project:** `hyphae/`
**Effort:** 20 min
**Depends on:** nothing

Wrap the SQL UPDATE to clamp the result:

#### Files to modify

**`crates/hyphae-store/src/store/memory_store.rs`** — in `apply_decay`, change the SQL to:
```sql
UPDATE memories SET weight = MAX(0.0, weight * (1.0 - (1.0 - ?1) * 2.0 / ...))
WHERE ...
```

Or add a post-update clamp:
```sql
UPDATE memories SET weight = 0.0 WHERE weight < 0.0
```

Add a test that verifies low-importance memories with access_count=1 don't go negative
after decay.

#### Verification

```bash
cd hyphae && cargo test decay 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [x] Decay SQL includes `MAX(0.0, ...)` or equivalent clamp
- [x] Test: low-importance memory with access_count=1 stays >= 0 after decay
- [x] Existing decay tests still pass

---

### Step 2: Fix H2 — Delete from chunks_fts during purge

**Project:** `hyphae/`
**Effort:** 30 min
**Depends on:** nothing

#### Files to modify

**`crates/hyphae-store/src/store/purge.rs`** — in both `purge_project` and
`purge_before_date`, add FTS cleanup before deleting chunks:

```rust
// Delete FTS entries for chunks being purged
conn.execute(
    "DELETE FROM chunks_fts WHERE rowid IN (
        SELECT id FROM chunks WHERE document_id IN (
            SELECT id FROM documents WHERE project = ?1
        )
    )",
    params![project],
)?;
```

Follow the same pattern used in `chunk_store.rs:165` for per-document deletion.

Also check if `chunks_vec` (vector table) needs similar cleanup.

#### Verification

```bash
cd hyphae && cargo test purge 2>&1
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [x] `purge_project` deletes from `chunks_fts` before `chunks`
- [x] `purge_before_date` deletes from `chunks_fts` before `chunks`
- [x] Test: after purge, `search_chunks_fts` returns no results for purged content
- [x] If `chunks_vec` exists, it is also cleaned up

---

## Completion Protocol

**This handoff is NOT complete until ALL of the following are true:**

1. Every step above has verification output pasted between the markers
2. All checklist items are checked
3. No negative weights possible after decay
4. No orphaned FTS entries after purge

## Context

Found during global ecosystem audit (2026-04-04), Layer 1 lint audit of hyphae.
See `ECOSYSTEM-AUDIT-2026-04-04.md` C4. These were flagged in a previous audit
but remain unresolved.
