# Cross-Project: Docs Audit Core Rust

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** `mycelium/...`, `hyphae/...`
- **Cross-repo edits:** allowed only in the named repos
- **Non-goals:** auditing other repos in this handoff
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-docs-audit-core-rust.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Audit and fix user-facing docs in `mycelium` and `hyphae` against the actual
CLI, config, and MCP surfaces.

## Verification

```bash
cd mycelium && ./target/debug/mycelium --help 2>&1 | head -30
cd hyphae && ./target/debug/hyphae --help 2>&1 | head -30
bash .handoffs/cross-project/verify-docs-audit-core-rust.sh
```

## Checklist

- [ ] `mycelium` README and docs match current CLI and config
- [ ] `hyphae` README and docs match current CLI and MCP surface
- [ ] removed or renamed features are cleaned up
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 1 of [Documentation Audit](docs-audit.md).
