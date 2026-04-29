# Canopy: MCP Handoff Runtime Boundaries

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `canopy`
- **Allowed write scope:** `canopy/src/tools/completeness.rs`, `canopy/src/handoff_check.rs`, `canopy/src/tools/import.rs`, `canopy/src/tools/files.rs`, `canopy/src/store/files.rs`, `canopy/src/mcp/schema.rs`, `canopy/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no task lifecycle redesign and no Septa read-model contract work
- **Verification contract:** run the repo-local commands below and `bash .handoffs/canopy/verify-mcp-handoff-runtime-boundaries.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `canopy`
- **Likely files/modules:** handoff completeness tool, handoff import tool, file lock tool/store
- **Reference seams:** existing handoff path validation, file lock MCP schema, archived file-conflict-detection work
- **Spawn gate:** do not launch an implementer until the parent agent decides whether verify-script execution requires an explicit MCP flag or is removed from the check tool entirely

## Problem

Canopy has MCP runtime boundaries that are too permissive. `canopy_check_handoff_completeness` derives and executes a sibling verify script from a caller-provided handoff path. `canopy_import_handoff` treats unsafe handoff paths as warnings, then reads and imports them. File locks accept path spellings verbatim and unlock by task rather than lock owner.

The data integrity audit also found import is not all-or-nothing: parent task creation, evidence insertion, and subtask creation happen in separate steps, so a mid-import failure can leave an incomplete imported task tree.

## What needs doing

1. Make handoff completeness checks non-executing by default, or require an explicit execution flag plus path allowlisting.
2. Reject handoff paths outside the workspace `.handoffs` tree instead of warning and continuing.
3. Normalize or reject file lock paths so equivalent spellings cannot bypass locks.
4. Require owner-scoped unlocks, or make operator override explicit and auditable.
5. Make handoff import transactional or add rollback/cleanup so partial task trees are not persisted after failure.

## Verification

```bash
cd canopy && cargo test completeness
cd canopy && cargo test import_handoff
cd canopy && cargo test import_handoff_rolls_back_partial_task_tree
cd canopy && cargo test files
bash .handoffs/canopy/verify-mcp-handoff-runtime-boundaries.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] completeness check does not execute verify scripts without explicit operator intent
- [ ] handoff import rejects paths outside approved handoff roots
- [ ] handoff import rolls back or cleans up partial task trees on failure
- [ ] file lock paths are canonical or rejected when ambiguous
- [ ] unlock requires matching owner or explicit operator override
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 2 runtime safety audit. Severity: critical/high/medium.
