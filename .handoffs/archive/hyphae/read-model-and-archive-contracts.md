# Hyphae: Read Model And Archive Contracts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/crates/hyphae-cli/src/commands/`, `hyphae/crates/hyphae-core/src/memoir.rs`, `hyphae/crates/hyphae-store/src/store/export.rs`, `hyphae/tests/`, and matching Hyphae Septa schemas/fixtures
- **Cross-repo edits:** `cap/server/hyphae/` only for consumer validators/tests that must move with the chosen Hyphae JSON shape
- **Non-goals:** no embedding behavior changes and no code-graph import changes
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hyphae/verify-read-model-and-archive-contracts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** CLI read commands, memoir serialization, export/import archive models, Cap Hyphae read adapters
- **Reference seams:** `septa/hyphae-search-v1.schema.json`, `septa/hyphae-context-v1.schema.json`, `septa/hyphae-archive-v1.schema.json`, `cap/server/hyphae/reads-cli.ts`, `cap/server/hyphae/memoirs-cli.ts`
- **Spawn gate:** do not launch an implementer until the parent agent chooses whether Septa should document the rich `MemoryPayload`/`Concept` objects or Hyphae should project narrower DTOs for Cap

## Problem

Hyphae CLI producers and Cap consumers agree with each other more than with Septa. Search, context, topic memories, sources, and memoir schemas are narrower than the JSON Hyphae emits and Cap expects. The archive export also includes `filter.until`, which `hyphae-archive-v1` forbids, and import checks only `schema_version` rather than the full contract.

The runtime safety audit also found that archive import can partially commit earlier records before a later malformed record fails. That belongs with the archive contract work because the fix should validate the entire archive before mutation or import it in one transaction.

The data integrity audit also found archive round-trip loss: memoir concepts/links are exported but not imported, and memories lose source attribution plus branch/worktree/agent/related-id provenance.

## What needs doing

1. Decide whether Hyphae read commands emit rich domain objects or Septa-shaped read DTOs.
2. Align Hyphae search/memory/context/source/memoir schemas and fixtures with real producer output, or add projection layers.
3. Align Cap Hyphae validators/tests with the canonical Septa shapes.
4. Add `hyphae-archive-v1` validation for export/import, including the `filter.until` decision.
5. Make archive import all-or-nothing by pre-validating records or wrapping the write path in one transaction.
6. Import archived memoir concepts and links, not only the memoir row.
7. Preserve memory provenance and scoped identity fields in archive export/import, either by schema revision or compatible optional fields.
8. Add generated-output fixture tests for representative Hyphae CLI JSON.

## Scope

- **Primary seam:** Hyphae JSON read/archive contracts
- **Allowed files:** Hyphae CLI/core/store tests and DTOs, matching Septa schemas/fixtures, narrow Cap Hyphae adapters
- **Explicit non-goals:** no memoir ranking changes, no code graph import work, no embedding adapter refactor

## Verification

```bash
cd hyphae && cargo test -p hyphae-cli
cd hyphae && cargo test -p hyphae-cli import
cd hyphae && cargo test -p hyphae-store export
cd septa && check-jsonschema --schemafile hyphae-archive-v1.schema.json fixtures/hyphae-archive-v1.example.json
bash .handoffs/hyphae/verify-read-model-and-archive-contracts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] Hyphae read command JSON matches Septa or uses explicit projection DTOs
- [ ] Cap read adapters accept the canonical Hyphae contract shapes
- [ ] archive export and import validate the full `hyphae-archive-v1` shape
- [ ] malformed archive import leaves no partially inserted records
- [ ] memoir concepts and links survive archive round-trip
- [ ] memory source, branch, worktree, agent, related-id, expiration, invalidation, and supersession fields are preserved or explicitly versioned out
- [ ] `filter.until` is either schema-backed or removed from export
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from the Phase 1 contract round-trip audit in the sequential audit hardening campaign. Severity: high.
