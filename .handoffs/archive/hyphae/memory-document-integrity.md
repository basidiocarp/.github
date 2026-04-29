# Hyphae: Memory And Document Integrity

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/crates/hyphae-store/src/store/memory_store.rs`, `hyphae/crates/hyphae-store/src/store/chunk_store.rs`, `hyphae/crates/hyphae-store/src/schema.rs`, `hyphae/crates/hyphae-store/migrations/`, `hyphae/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no embedding provider refactor and no archive schema redesign
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hyphae/verify-memory-document-integrity.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** memory store transaction path, document/chunk store schema and migration, project-scoped document lookup tests
- **Reference seams:** `update()` and `replace_memory()` transaction patterns; chunk store project-scoped lookup APIs
- **Spawn gate:** do not launch an implementer until the parent agent confirms the migration strategy for `documents.source_path` uniqueness

## Problem

Hyphae can persist memory rows without vector rows because `store()` inserts `memories` and `vec_memories` separately without a transaction. Document identity is also globally unique by `source_path` even though APIs are project-scoped, so two projects with the same relative path can replace each other's documents and chunks.

## What needs doing

1. Wrap memory row, vector row, and audit writes in one transaction for `store()`.
2. Add a regression proving invalid embedding/vector insertion leaves no memory row behind.
3. Migrate document uniqueness from global `source_path` to `(project, source_path)` or an equivalent normalized source identity.
4. Add cross-project document/chunk tests for identical relative paths.

## Verification

```bash
cd hyphae && cargo test -p hyphae-store store_with_embedding
cd hyphae && cargo test -p hyphae-store document
bash .handoffs/hyphae/verify-memory-document-integrity.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] failed vector insertion rolls back the memory row
- [ ] memory audit writes commit only when memory/vector writes commit
- [ ] two projects can store the same relative document path without replacing each other
- [ ] old databases migrate safely to the new document identity invariant
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 4 data integrity audit. Severity: high.
