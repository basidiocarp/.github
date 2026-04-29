# Hyphae: Storage And Ingest Runtime Safety

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `hyphae`
- **Allowed write scope:** `hyphae/crates/hyphae-cli/src/commands/backup.rs`, `hyphae/crates/hyphae-cli/src/commands/docs.rs`, `hyphae/crates/hyphae-cli/src/extract.rs`, `hyphae/crates/hyphae-cli/src/config.rs`, `hyphae/crates/hyphae-ingest/src/`, `hyphae/crates/hyphae-mcp/src/tools/ingest.rs`, `hyphae/crates/hyphae-store/`, `hyphae/scripts/hooks/hyphae-post-tool.sh`, `hyphae/tests/`
- **Cross-repo edits:** none
- **Non-goals:** no read-model schema redesign and no embedding provider refactor
- **Verification contract:** run the repo-local commands below and `bash .handoffs/hyphae/verify-storage-and-ingest-runtime-safety.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `hyphae`
- **Likely files/modules:** backup/restore commands, ingest readers, MCP ingest tools, store transaction helpers
- **Reference seams:** SQLite WAL setup, previous backup/restore tests, MCP tool input validation patterns
- **Spawn gate:** do not launch an implementer until the parent agent chooses SQLite backup API versus `VACUUM INTO` for backup creation

## Problem

Hyphae enables SQLite WAL mode but backup/restore uses raw file copies. Backups can miss committed WAL data, and restore overwrites the live DB directly while stale sidecars may remain. Public ingest boundaries also accept arbitrary paths and unbounded file/command-output payloads before memory and storage costs are controlled.

The security audit added that hook-driven auto-extraction can persist secrets from raw tool output. The hook pipes `tool_response` or `tool_output` into `hyphae extract`, and `extract_and_store` writes extracted facts without the same secret rejection policy used by MCP memory storage.

## What needs doing

1. Replace raw DB backup copies with a WAL-safe backup mechanism.
2. Restore through a validated same-directory temp file plus atomic rename, with clear sidecar handling.
3. Restrict MCP/CLI ingest paths to an approved workspace/root policy.
4. Add file-size, recursive ingest, command length, and output-size limits before full reads/chunking/storage.
5. Apply secret detection/redaction to hook auto-extraction and CLI extract paths before durable storage.
6. Add regression tests for WAL backup correctness, oversized input rejection, and secret-bearing extraction rejection/redaction.

## Verification

```bash
cd hyphae && cargo test -p hyphae-cli backup
cd hyphae && cargo test -p hyphae-cli restore
cd hyphae && cargo test -p hyphae-mcp ingest
bash .handoffs/hyphae/verify-storage-and-ingest-runtime-safety.sh
```

**Output:**
<!-- PASTE START -->

<!-- PASTE END -->

**Checklist:**
- [ ] backup includes data committed in WAL mode
- [ ] restore is atomic and handles old `-wal`/`-shm` sidecars deliberately
- [ ] MCP/CLI ingest cannot read arbitrary local files outside policy
- [ ] oversized files and command outputs are rejected before full processing
- [ ] hook auto-extraction and `hyphae extract` do not persist raw API keys, bearer tokens, or secret assignments
- [ ] recursive ingest has file-count or byte-budget limits
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

Created from Phase 2 runtime safety audit. Severity: high.
