# Cross-Project: Docs Audit Platform Rust

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `multiple`
- **Allowed write scope:** `rhizome/...`, `stipe/...`, `canopy/...`
- **Cross-repo edits:** allowed only in the named repos
- **Non-goals:** auditing other repos in this handoff
- **Verification contract:** run the repo-local commands below and `bash .handoffs/cross-project/verify-docs-audit-platform-rust.sh`
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove this handoff if the dashboard tracks active work only

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What Needs Doing

Audit and fix user-facing docs in `rhizome`, `stipe`, and `canopy` against the
actual CLI and operator-facing surfaces.

## Verification

```bash
cd rhizome && ./target/debug/rhizome --help 2>&1 | head -20
cd stipe && ./target/debug/stipe --help 2>&1 | head -20
cd canopy && ./target/debug/canopy --help 2>&1 | head -20
bash .handoffs/cross-project/verify-docs-audit-platform-rust.sh
```

## Checklist

- [ ] `rhizome` docs match actual tool count and CLI surface
- [ ] `stipe` docs match current commands
- [ ] `canopy` docs match current CLI and operator workflow
- [ ] verify script passes with `Results: N passed, 0 failed`

## Context

## Implementation Seam

- **Likely repo:** `multiple`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `multiple` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commandsChild 2 of [Documentation Audit](docs-audit.md).
