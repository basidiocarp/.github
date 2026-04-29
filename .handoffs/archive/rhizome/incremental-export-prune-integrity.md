# Rhizome: Incremental Export Prune Integrity

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** `rhizome/crates/rhizome-mcp/src/tools/export_tools.rs`, `rhizome/crates/rhizome-mcp/tests/`, `rhizome/crates/rhizome-core/`
- **Cross-repo edits:** `hyphae/crates/hyphae-mcp/` tests only if needed to prove importer behavior
- **Non-goals:** no code graph schema redesign and no Hyphae memoir store rewrite
- **Verification contract:** run the repo-local commands below and `bash .handoffs/rhizome/verify-incremental-export-prune-integrity.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** incremental export graph collection and Hyphae import request construction
- **Reference seams:** cached-file skip logic, Hyphae `prune` import parameter, existing export tests
- **Spawn gate:** do not launch an implementer until the parent agent decides whether incremental exports should set `prune=false` or send a reconstructed full graph

## Problem

Incremental Rhizome exports skip cached unchanged files, then send only processed graphs to Hyphae. Hyphae defaults code-graph import pruning to true, so a partial export can delete unchanged concepts from `code:{project}`.

## What needs doing

1. Detect partial/incremental exports and avoid pruning unchanged concepts.
2. Alternatively reconstruct and send the full project graph whenever pruning is enabled.
3. Add a two-file export regression where the second run changes one file and preserves concepts from the cached file.

## Verification

```bash
cd rhizome && cargo test -p rhizome-mcp export
cd hyphae && cargo test -p hyphae-mcp import_code_graph
bash .handoffs/rhizome/verify-incremental-export-prune-integrity.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] partial exports do not prune unchanged Hyphae concepts
- [ ] full exports still prune intentionally removed concepts
- [ ] tests cover incremental export with cached unchanged files
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 4 data integrity audit. Severity: high.
