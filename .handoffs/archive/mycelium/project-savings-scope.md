# Mycelium Project Savings Scope

## Handoff Metadata

- **Dispatch:** `direct`
- **Owning repo:** `mycelium`
- **Allowed write scope:** mycelium/...
- **Cross-repo edits:** none unless this handoff explicitly says otherwise
- **Non-goals:** adjacent repo work not named in this handoff
- **Verification contract:** run the repo-local commands named in the handoff and the paired `verify-*.sh` script
- **Completion update:** once audit is clean and verification is green, update `.handoffs/HANDOFFS.md` and archive or remove the completed entry if the dashboard tracks active work only


## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands

## What needs doing

Add project scoping to Mycelium savings recording and query behavior:

- project column or equivalent schema support
- project derivation from git root or cwd
- `mycelium gain --project <name>`
- `mycelium gain --project all`

Keep this handoff limited to storage and CLI behavior, not JSON output for Cap.

## Verification

```bash
cd mycelium && cargo build --workspace
cd mycelium && cargo test --workspace
bash .handoffs/mycelium/verify-project-savings-scope.sh
```

## Checklist

## Implementation Seam

- **Likely repo:** `mycelium`
- **Likely files/modules:** start with the module or files that implement the primary seam named in this handoff; if this handoff already names files below, use those as the first candidate set before spawning
- **Reference seams:** reuse the closest existing command, resource, hook, serializer, storage, or UI surface in `mycelium` instead of creating a parallel path
- **Spawn gate:** do not launch an implementer until the parent agent can name the likely file set and exact repo-local verification commands- [ ] Mycelium stores project scope with savings records
- [ ] project-specific and all-project queries work
- [ ] global no-flag behavior stays unchanged
- [ ] verify script passes with `Results: N passed, 0 failed`
