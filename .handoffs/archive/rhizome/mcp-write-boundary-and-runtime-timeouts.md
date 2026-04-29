# Rhizome: MCP Write Boundary And Runtime Timeouts

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `rhizome`
- **Allowed write scope:** `rhizome/crates/rhizome-mcp/src/tools/`, `rhizome/crates/rhizome-core/src/installer.rs`, `rhizome/crates/rhizome-core/src/backend_selector.rs`, `rhizome/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no code graph schema changes and no Hyphae importer work
- **Verification contract:** run the repo-local commands below and `bash .handoffs/rhizome/verify-mcp-write-boundary-and-runtime-timeouts.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `rhizome`
- **Likely files/modules:** `rhizome-mcp/src/tools/mod.rs`, `rhizome-mcp/src/tools/edit_tools.rs`, `rhizome-core/src/installer.rs`, `rhizome-core/src/backend_selector.rs`
- **Reference seams:** existing edit tool path validation, LSP client timeout handling, explicit install command paths
- **Spawn gate:** do not launch an implementer until the parent agent identifies the configured MCP project root and the write-capable tool list

## Problem

Rhizome MCP accepts caller-provided absolute `root` values and validates edits against that selected root instead of the server's configured project root. A registered MCP caller can expand write authority outside the project. The security audit confirmed the same root override expands read and export authority through symbol inspection and repo export tools, so the boundary must apply to read, write, and export tool families. Separately, package-manager installer paths call `npm`/`brew`/`pip`/`gem`/`dotnet` without timeouts or cleanup, and backend probing can reach those installs.

## What needs doing

1. Prevent MCP `root` overrides from expanding read, write, or export authority beyond the configured project root.
2. Add tests for read/export tools such as `get_symbols`, `get_call_sites`, and `export_repo_understanding` with hostile roots.
3. Add tests for write-capable tools such as `create_file`, line edits, deletes, and symbol edits with hostile roots.
4. Ensure backend probing cannot trigger unbounded package-manager installs.
5. Add deadlines and kill/wait cleanup to any explicit package-manager install commands that remain.

## Verification

```bash
cd rhizome && cargo test -p rhizome-mcp root
cd rhizome && cargo test -p rhizome-core installer
bash .handoffs/rhizome/verify-mcp-write-boundary-and-runtime-timeouts.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] MCP write tools cannot use `root = "/"` or sibling roots to escape the configured project
- [ ] MCP read and export tools cannot use hostile roots to inspect or export files outside the configured project
- [ ] root override behavior is tested for every write-capable tool family
- [ ] backend probing does not run package-manager installs
- [ ] explicit installs use bounded subprocess execution and reap killed children
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 2 runtime safety audit. Severity: critical/high.
