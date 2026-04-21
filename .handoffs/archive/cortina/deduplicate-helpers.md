# Cortina Helper Deduplication

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `cortina`
- **Allowed write scope:** cortina/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## Problem

Three helper functions (`resolved_cwd`, `project_name_from_root`, `git_command_output`)
are duplicated verbatim between `state.rs` and `session_scope.rs`. A fourth function
(`current_runtime_session_id`) is duplicated between `state.rs` and `statusline.rs`.
Bug fixes must be applied to all copies.

## What exists (state)

- `resolved_cwd`, `project_name_from_root`, `git_command_output`:
  - `src/utils/state.rs:134-162` (canonical, `pub(super)`)
  - `src/utils/session_scope.rs:426-454` (identical copy)
- `current_runtime_session_id`:
  - `src/utils/state.rs:45` (`pub(super)`)
  - `src/statusline.rs:301` (module-private copy)
- **Also:** ~130 lines of dead migration code in `state.rs` behind 9 `#[allow(dead_code)]`

## What needs doing (intent)

Consolidate duplicated functions. Optionally clean up dead migration code.

---

### Step 1: Deduplicate helpers

**Project:** `cortina/`
**Effort:** 20 min

- Promote `resolved_cwd`, `project_name_from_root`, `git_command_output` in `state.rs`
  to `pub(crate)` visibility
- Delete the copies in `session_scope.rs`, import via `super::state::`
- Promote `current_runtime_session_id` in `state.rs` to `pub(crate)`
- Delete the copy in `statusline.rs`, import from `utils::state`

### Step 2: Clean up dead migration code (optional)

Either move the 9 `#[allow(dead_code)]` migration functions to a separate
`state_migration.rs` with dedicated tests, or delete them and rely on git history.

**Checklist:**
- [ ] Each of the 4 functions exists in exactly one location
- [ ] All 110 tests pass
- [ ] Zero `#[allow(dead_code)]` on the moved migration code (either tested or deleted)

## Context

## Implementation Seam

- **Likely repo:** `cortina`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `cortina` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsFound during global ecosystem audit (2026-04-04), Layer 2 structural review of cortina.
